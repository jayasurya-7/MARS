class_name Mascot
extends Node2D
## "Bolt" - a friendly little robot buddy. Cheers on success, comforts on a miss,
## gives a gentle tip when the player is idle, follows the cursor with its eyes,
## and giggles if the cursor touches it. Purely supportive - it never blocks input.

const BODY := Color(0.72, 0.8, 0.88)
const CHEER_LINES := ["Yay!", "Woohoo!", "Super!", "High five!", "You rock!", "Brilliant!"]
const PICK_LINES := ["You can do it!", "Nice grab!", "Good one!", "Steady..."]
const OOPS_LINES := ["So close!", "No worries!", "Try again!", "Almost!"]
const TIP_FREE := ["Pick any item!", "Take your time", "I'm cheering for you!"]
const TIP_HELD := ["Find the glowing bin!", "Slow and steady!"]
const IDLE_TIME := 10.0

enum Mood { NORMAL, HAPPY, OOPS }

var _t := 0.0
var _jump := 0.0
var _arms := 0.0   # 0 = resting, 1 = raised
var _wave := 0.0   # waving strength, decays
var _tilt := 0.0
var _mood := Mood.NORMAL
var _mood_left := 0.0
var _blink_in := 2.5
var _blink := 0.0
var _bubble := ""
var _bubble_a := 0.0
var _bubble_left := 0.0
var _idle := 0.0
var _tickle_cd := 3.0
var _streak := 0
var _dancing := false
var _screen := StyleBoxFlat.new()
var _bubble_style := StyleBoxFlat.new()


func _ready() -> void:
	z_index = 20
	_screen.bg_color = Color(0.1, 0.13, 0.3)
	_screen.set_corner_radius_all(22)
	_bubble_style.set_corner_radius_all(28)
	_bubble_style.shadow_size = 12


# --- reactions (called by GameManager) ---------------------------------------

func greet() -> void:
	_wave = 1.0
	say("Hi! Let's sort!", 3.0)


func on_pick() -> void:
	_idle = 0.0
	if randf() < 0.35:
		say(PICK_LINES.pick_random())


func on_sorted() -> void:
	_idle = 0.0
	_streak += 1
	_set_mood(Mood.HAPPY, 1.6)
	_hop(2 if _streak % 3 == 0 else 1)
	_raise_arms()
	if _streak % 3 == 0:
		say("%d in a row!" % _streak)
	elif randf() < 0.6:
		say(CHEER_LINES.pick_random())
	SortFx.burst(get_parent(), global_position + Vector2(0, -70), Color(0.92, 0.84, 0.62), 14)


func on_rejected() -> void:
	_idle = 0.0
	_streak = 0
	_set_mood(Mood.OOPS, 1.8)
	say(OOPS_LINES.pick_random())


func celebrate() -> void:
	_dancing = true
	_set_mood(Mood.HAPPY, 999.0)
	say("You did it!", 5.0)


func say(text: String, secs: float = 2.2) -> void:
	_bubble = text
	_bubble_left = secs


# --- internals ---------------------------------------------------------------

func _set_mood(m: Mood, secs: float) -> void:
	_mood = m
	_mood_left = secs


func _hop(times: int) -> void:
	var tw := create_tween()
	for i in times:
		tw.tween_property(self, "_jump", -26.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "_jump", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _raise_arms() -> void:
	var tw := create_tween()
	tw.tween_property(self, "_arms", 1.0, 0.15)
	tw.tween_interval(0.8)
	tw.tween_property(self, "_arms", 0.0, 0.4)


func _process(delta: float) -> void:
	_t += delta
	_idle += delta
	_tickle_cd -= delta
	_bubble_left -= delta
	_bubble_a = move_toward(_bubble_a, 1.0 if _bubble_left > 0.0 else 0.0, delta * 5.0)
	_mood_left -= delta
	if _mood_left <= 0.0:
		_mood = Mood.NORMAL
	_tilt = lerpf(_tilt, 0.18 if _mood == Mood.OOPS else 0.0, 1.0 - exp(-delta * 6.0))
	_wave = move_toward(_wave, 0.0, delta * 0.5)

	_blink_in -= delta
	if _blink_in <= 0.0:
		_blink = 0.15
		_blink_in = randf_range(2.5, 5.0)
	_blink = maxf(0.0, _blink - delta)

	var holding := is_instance_valid(InteractableItem.held)
	if _idle > IDLE_TIME and not _dancing:
		_idle = 0.0
		_wave = 1.0
		say(TIP_HELD.pick_random() if holding else TIP_FREE.pick_random(), 3.0)

	# giggle when the cursor touches Bolt
	if not holding and _tickle_cd <= 0.0 and GamePointer.world(self).distance_to(global_position) < 75.0:
		_tickle_cd = 6.0
		_hop(1)
		_set_mood(Mood.HAPPY, 1.2)
		say("Hee hee!")

	if _dancing:
		_jump = -absf(sin(_t * 6.0)) * 22.0
		_arms = 0.5 + 0.5 * sin(_t * 6.0)
	queue_redraw()


func _draw() -> void:
	var bob := sin(_t * 2.2) * 5.0 + _jump
	var dark := BODY.darkened(0.3)

	# ground shadow (shrinks while jumping)
	draw_set_transform(Vector2(0, 76), 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, 52.0 * (1.0 + _jump / 70.0), Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2(0, bob), _tilt, Vector2.ONE)

	# arms (behind the body); left raises outward through PI, right through 0
	var wave := sin(_t * 14.0) * 0.5 * _wave
	var left_a := lerpf(PI * 0.7, PI * 1.3, _arms)
	var right_a := lerpf(PI * 0.3, -PI * 0.3, maxf(_arms, _wave)) + wave
	for arm in [[Vector2(-50, 8), left_a], [Vector2(50, 8), right_a]]:
		var base: Vector2 = arm[0]
		var hand: Vector2 = base + Vector2.from_angle(arm[1]) * 44.0
		draw_line(base, hand, dark, 14.0, true)
		draw_circle(hand, 11.0, BODY)
		draw_arc(hand, 11.0, 0.0, TAU, 20, dark, 3.0, true)

	# feet
	draw_circle(Vector2(-22, 58), 14.0, dark)
	draw_circle(Vector2(22, 58), 14.0, dark)

	# body
	draw_circle(Vector2.ZERO, 62.0, BODY.darkened(0.12))
	draw_circle(Vector2(0, -4), 57.0, BODY)
	draw_circle(Vector2(-22, -28), 15.0, Color(1, 1, 1, 0.45))
	draw_arc(Vector2.ZERO, 62.0, 0.0, TAU, 48, dark, 4.0, true)

	# antenna with a glowing bulb that changes colour with mood
	var bulb := Color(0.65, 0.85, 0.75)
	if _mood == Mood.HAPPY:
		bulb = Color(0.92, 0.8, 0.55)
	elif _mood == Mood.OOPS:
		bulb = Color(0.9, 0.68, 0.55)
	draw_line(Vector2(0, -60), Vector2(0, -84), dark, 5.0, true)
	draw_circle(Vector2(0, -90), 18.0 + 3.0 * sin(_t * 4.0), Color(bulb.r, bulb.g, bulb.b, 0.22))
	draw_circle(Vector2(0, -90), 10.0, bulb)

	# face screen
	_screen.draw(get_canvas_item(), Rect2(-40, -36, 80, 56))
	var eye_col := Color(0.7, 0.9, 0.88)
	var look := (GamePointer.world(self) - global_position).normalized() * 4.0
	for eye: Vector2 in [Vector2(-16, -12), Vector2(16, -12)]:
		if _blink > 0.0:
			draw_line(eye - Vector2(7, 0), eye + Vector2(7, 0), eye_col, 4.0, true)
		elif _mood == Mood.HAPPY:
			draw_arc(eye + Vector2(0, 4), 8.0, PI, TAU, 12, eye_col, 4.0, true)
		else:
			draw_circle(eye + look, 8.0, eye_col)
			draw_circle(eye + look + Vector2(-2.5, -2.5), 2.5, Color.WHITE)
	match _mood:
		Mood.HAPPY:
			draw_arc(Vector2(0, 2), 11.0, PI * 0.1, PI * 0.9, 12, eye_col, 4.0, true)
		Mood.OOPS:
			draw_arc(Vector2(0, 14), 7.0, PI * 1.15, PI * 1.85, 10, eye_col, 3.5, true)
		_:
			draw_arc(Vector2(0, 3), 7.0, PI * 0.2, PI * 0.8, 10, eye_col, 3.5, true)

	# cheeks and blinking belly lights
	draw_circle(Vector2(-46, 12), 8.0, Color(0.9, 0.62, 0.65, 0.45))
	draw_circle(Vector2(46, 12), 8.0, Color(0.9, 0.62, 0.65, 0.45))
	var on := int(_t * 3.0) % 3
	for i in 3:
		var c := Color(0.92, 0.8, 0.55) if i == on else Color(1, 1, 1, 0.35)
		draw_circle(Vector2(-14 + 14 * i, 40), 4.5, c)

	# speech bubble (to the left of Bolt)
	if _bubble_a > 0.01 and _bubble != "":
		draw_set_transform(Vector2(0, bob * 0.3), 0.0, Vector2.ONE)
		var font := ThemeDB.fallback_font
		var fs := 32
		var w := font.get_string_size(_bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var r := Rect2(-92.0 - w - 40.0, -70.0, w + 40.0, 62.0)
		_bubble_style.bg_color = Color(1, 1, 1, 0.95 * _bubble_a)
		_bubble_style.shadow_color = Color(0, 0, 0, 0.25 * _bubble_a)
		_bubble_style.draw(get_canvas_item(), r)
		draw_colored_polygon(PackedVector2Array([
			Vector2(r.end.x - 2, -54), Vector2(r.end.x + 20, -38), Vector2(r.end.x - 2, -28)]),
			Color(1, 1, 1, 0.95 * _bubble_a))
		draw_string(font, Vector2(r.position.x + 20, -28), _bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color(0.1, 0.12, 0.3, _bubble_a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
