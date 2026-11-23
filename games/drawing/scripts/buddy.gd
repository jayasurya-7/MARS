class_name Buddy
extends Node2D
## "Bindu" – a friendly paint-drop helper that sits in a corner and cheers the player on.
## Fully procedural (no art files). Only ever positive: it never reacts to mistakes.
## Edit LINES to change or translate what Bindu says.

const INK := Color("1f2230")
const R := 78.0                      # body radius
const BUBBLE_BOTTOM := -240.0       # local y of speech bubble's bottom edge

const LINES := {
	cheer = ["Super!", "Wow, lovely!", "Great job!", "Beautiful!", "You did it!", "So colourful!",
		"Nice and steady!", "Well done!"],
	pick = ["Great pick!", "That's the one!", "Nice colour!"],
	idle = ["Take your time.", "Nice and slow - you're doing fine.", "I'm right here with you!",
		"Follow the glow!"],
	done = ["Amazing! Picture finished!", "Hooray! What a picture!", "You're a real artist!"],
	hello = ["Hi there!", "Hello, friend!"],
}

var cursor_pos := Vector2.ZERO        # set every frame by LevelManager

var _body_color := Color("8fd0ff")
var _t := 0.0
var _hop := 0.0                        # tweened vertical offset
var _squash := 0.0                     # tweened squash/stretch amount
var _arm_lift := 0.0                   # right arm wave 0..1
var _both_arms := 0.0                  # celebrate: both arms up 0..1
var _happy := 0.0                      # 0 = smile, 1 = big open grin
var _blink := 1.0                      # eye openness
var _next_blink := 3.0
var _look_override := Vector2.ZERO
var _look_timer := 0.0
var _wave_cooldown := 0.0

var _bubble: PanelContainer
var _label: Label
var _bubble_tween: Tween
var _bubble_timer: SceneTreeTimer


func _ready() -> void:
	_bubble = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.WHITE
	sb.set_corner_radius_all(24)
	sb.set_border_width_all(4)
	sb.border_color = INK
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_size = 10
	sb.shadow_color = Color(0, 0, 0, 0.18)
	sb.shadow_offset = Vector2(0, 5)
	_bubble.add_theme_stylebox_override("panel", sb)
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.modulate.a = 0.0
	add_child(_bubble)
	_label = Label.new()
	_label.custom_minimum_size = Vector2(250, 0)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 34)
	_label.add_theme_color_override("font_color", INK)
	_bubble.add_child(_label)
	_bubble.resized.connect(_place_bubble)
	_place_bubble()


func _place_bubble() -> void:
	_bubble.position = Vector2(-_bubble.size.x * 0.5, BUBBLE_BOTTOM - _bubble.size.y)


# ───────────────────────────── public reactions ─────────────────────────────

func say(text: String, seconds := 2.8) -> void:
	_label.text = text
	_bubble.reset_size()
	if _bubble_tween:
		_bubble_tween.kill()
	_bubble_tween = create_tween()
	_bubble_tween.tween_property(_bubble, "modulate:a", 1.0, 0.2)
	var timer := get_tree().create_timer(seconds)
	_bubble_timer = timer
	await timer.timeout
	if _bubble_timer == timer:            # a newer line hasn't replaced this one
		_bubble_tween = create_tween()
		_bubble_tween.tween_property(_bubble, "modulate:a", 0.0, 0.35)


func say_random(kind: StringName, seconds := 2.8) -> void:
	say(LINES[kind].pick_random(), seconds)


func set_color(c: Color) -> void:
	var t := create_tween()
	t.tween_property(self, "_body_color", c.lightened(0.15), 0.4)


func look_at_point(global_p: Vector2, seconds := 2.0) -> void:
	_look_override = global_p
	_look_timer = seconds


func hop(height := 50.0) -> void:
	var t := create_tween()
	t.tween_property(self, "_squash", 0.15, 0.08)
	t.tween_property(self, "_squash", -0.12, 0.1)
	t.parallel().tween_property(self, "_hop", -height, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "_hop", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(self, "_squash", 0.0, 0.22)
	t.tween_property(self, "_squash", 0.12, 0.07)
	t.tween_property(self, "_squash", 0.0, 0.15).set_trans(Tween.TRANS_BACK)


func wave(seconds := 1.6) -> void:
	var t := create_tween()
	t.tween_property(self, "_arm_lift", 1.0, 0.25)
	t.tween_interval(seconds)
	t.tween_property(self, "_arm_lift", 0.0, 0.3)


func cheer() -> void:
	_set_happy(1.4)
	hop()
	wave(0.6)
	if randf() < 0.7:
		say_random(&"cheer", 2.0)


func celebrate() -> void:
	_set_happy(4.0)
	say_random(&"done", 4.0)
	var arms := create_tween()
	arms.tween_property(self, "_both_arms", 1.0, 0.25)
	arms.tween_interval(3.0)
	arms.tween_property(self, "_both_arms", 0.0, 0.4)
	for i in 4:
		hop(70.0)
		await get_tree().create_timer(0.75).timeout


func encourage(target_global: Vector2) -> void:
	look_at_point(target_global, 3.0)
	wave(1.0)
	say_random(&"idle", 3.2)


func _set_happy(seconds: float) -> void:
	var t := create_tween()
	t.tween_property(self, "_happy", 1.0, 0.15)
	t.tween_interval(seconds)
	t.tween_property(self, "_happy", 0.0, 0.3)


# ───────────────────────────── animation & drawing ─────────────────────────────

func _process(delta: float) -> void:
	_t += delta
	_look_timer -= delta
	_wave_cooldown -= delta

	_next_blink -= delta
	if _next_blink <= 0.0:
		_next_blink = randf_range(2.5, 5.5)
		var b := create_tween()
		b.tween_property(self, "_blink", 0.08, 0.07)
		b.tween_property(self, "_blink", 1.0, 0.09)

	# Wave hello when the player's cursor comes close.
	if _wave_cooldown <= 0.0 and cursor_pos.distance_to(global_position) < 210.0:
		_wave_cooldown = 20.0
		wave()
		say_random(&"hello", 1.8)

	queue_redraw()


func _drop_shape() -> PackedVector2Array:
	var apex := Vector2(0, -R * 1.85)
	var a := acos(R / apex.length())          # tangent angle from straight up
	var pts := PackedVector2Array([apex])
	var steps := 40
	for i in steps + 1:
		var ang := -PI / 2.0 + a + (TAU - 2.0 * a) * i / steps
		pts.append(Vector2.from_angle(ang) * R)
	return pts


func _draw() -> void:
	# speech bubble tail
	if _bubble.modulate.a > 0.01:
		var al := _bubble.modulate.a
		var tail := PackedVector2Array([Vector2(-16, BUBBLE_BOTTOM - 4), Vector2(16, BUBBLE_BOTTOM - 4), Vector2(4, BUBBLE_BOTTOM + 26)])
		draw_colored_polygon(tail, Color(1, 1, 1, al))
		draw_line(tail[0], tail[2], Color(INK, al), 4.0, true)
		draw_line(tail[1], tail[2], Color(INK, al), 4.0, true)

	# ground shadow (doesn't move with the hop, shrinks when in the air)
	var sh := 1.0 + _hop / 140.0
	draw_set_transform(Vector2(0, R + 14), 0.0, Vector2(sh, sh * 0.25))
	draw_circle(Vector2.ZERO, R * 0.9, Color(0, 0, 0, 0.16))

	var bob := sin(_t * 2.3) * 4.0
	var sy := 1.0 - _squash + sin(_t * 2.3) * 0.015
	var sx := 1.0 + _squash
	# squash around the feet so the body stays on the ground
	draw_set_transform(Vector2(0, bob + _hop + R * (1.0 - sy)), 0.0, Vector2(sx, sy))

	# feet
	draw_circle(Vector2(-32, R - 2), 18, INK)
	draw_circle(Vector2(32, R - 2), 18, INK)

	# arms (behind body): left & right, angle measured from straight down
	var wiggle := sin(_t * 14.0) * 0.35
	var right_ang := lerpf(-0.55, -2.5 + wiggle, maxf(_arm_lift, _both_arms))
	var left_ang := lerpf(0.55, 2.5 - wiggle, _both_arms)
	for side in [[-1.0, left_ang], [1.0, right_ang]]:
		var shoulder := Vector2(side[0] * R * 0.82, 0)
		var hand: Vector2 = shoulder + Vector2.DOWN.rotated(side[1]) * 58.0
		draw_line(shoulder, hand, INK, 9.0, true)
		draw_circle(hand, 13, _body_color)
		draw_arc(hand, 13, 0, TAU, 20, INK, 4.0, true)

	# body
	var body := _drop_shape()
	draw_colored_polygon(body, _body_color)
	var outline := body.duplicate()
	outline.append(body[0])
	draw_polyline(outline, INK, 5.0, true)
	draw_set_transform(Vector2(-34, bob + _hop - 50 + R * (1.0 - sy)), -0.5, Vector2(sx, sy))
	draw_circle(Vector2.ZERO, 14, Color(1, 1, 1, 0.55))     # shine
	draw_set_transform(Vector2(0, bob + _hop + R * (1.0 - sy)), 0.0, Vector2(sx, sy))

	# eyes follow the cursor (or whatever Bindu is looking at)
	var target := _look_override if _look_timer > 0.0 else cursor_pos
	var look := (target - global_position).normalized() * 7.0
	for ex in [-28.0, 28.0]:
		var c := Vector2(ex, -16)
		draw_set_transform(Vector2(0, bob + _hop + R * (1.0 - sy)) + c * Vector2(sx, sy), 0.0, Vector2(sx, sy * _blink))
		draw_circle(Vector2.ZERO, 19, Color.WHITE)
		draw_arc(Vector2.ZERO, 19, 0, TAU, 28, INK, 4.0, true)
		draw_circle(look, 9, INK)
		draw_circle(look + Vector2(-3, -3), 3, Color.WHITE)
	draw_set_transform(Vector2(0, bob + _hop + R * (1.0 - sy)), 0.0, Vector2(sx, sy))

	# cheeks
	draw_circle(Vector2(-50, 14), 11, Color(1, 0.45, 0.5, 0.45))
	draw_circle(Vector2(50, 14), 11, Color(1, 0.45, 0.5, 0.45))

	# mouth: smile blends into a big open grin when happy
	if _happy < 0.5:
		draw_arc(Vector2(0, 8), 20, deg_to_rad(20), deg_to_rad(160), 20, INK, 5.0, true)
	else:
		var grin := PackedVector2Array()
		var open := 18.0 + 10.0 * _happy
		for i in 21:
			var ang := PI * i / 20.0
			grin.append(Vector2(cos(ang) * 24.0, 8.0 + sin(ang) * open))
		draw_colored_polygon(grin, Color("8c2131"))
		draw_circle(Vector2(0, 8 + open * 0.7), 8, Color("ff7b8a"))   # tongue
		grin.append(grin[0])
		draw_polyline(grin, INK, 4.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
