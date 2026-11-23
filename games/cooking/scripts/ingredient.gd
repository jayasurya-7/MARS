class_name Ingredient
extends Grabbable
## A vegetable. Snaps to the hand while gripped. On release it goes into the pot if it is
## over the pot, otherwise it glides back to its crate. Drawn from the pictures in assets/veg.

enum Kind {
	POTATO, BROCCOLI, CARROT, TOMATO, ONION, PEPPER_RED, PEPPER_YELLOW, PEPPER_GREEN,
	PEPPER_ORANGE, GARLIC, MUSHROOMS, CELERY, PUMPKIN, ZUCCHINI, PEAS,
}
enum State { ON_PLATE, HELD, RETURNING, IN_POT }

## Picture size on screen, in pixels.
const DISPLAY := 92.0

@export var kind := Kind.BROCCOLI

var state := State.ON_PLATE
var home := Vector2.ZERO
## Set by the pot while this ingredient overlaps it.
var target_pot: CookingPot = null

var _tween: Tween
var _hover_progress := 0.0
var _time := randf() * 10.0
var _swell := 0.0
var _tilt := 0.0
var _last_x := 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_last_x = global_position.x


func set_hover_progress(value: float) -> void:
	_hover_progress = clampf(value, 0.0, 1.0)


func place_at(point: Vector2) -> void:
	home = point
	global_position = point
	_last_x = point.x


func sprite_name() -> String:
	return str(Kind.keys()[kind]).to_lower()


func can_grab() -> bool:
	return super() and state != State.IN_POT


func _on_grabbed() -> void:
	_kill_tween()
	state = State.HELD
	z_index = 25 # Above the hand (20), so the patient can see what they are carrying.
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE * 1.15, 0.16)


func _on_dropped() -> void:
	z_index = 0
	if target_pot != null and target_pot.accept_ingredient(self):
		return
	state = State.RETURNING
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "global_position", home, 0.5)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.5)
	_tween.chain().tween_callback(func() -> void: state = State.ON_PLATE)


## Called by the pot once it has accepted this ingredient: it tumbles in and floats.
func settle_in(contents: Node2D, local_point: Vector2) -> void:
	_kill_tween()
	state = State.IN_POT
	set_deferred("monitorable", false)
	set_highlighted(false)
	reparent(contents)
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", local_point, 0.4)
	_tween.tween_property(self, "scale", Vector2.ONE * 0.5, 0.4)
	_tween.tween_property(self, "rotation", rotation + TAU * 0.75, 0.4)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


func _process(delta: float) -> void:
	_time += delta
	_swell = lerpf(_swell, 1.0 if highlighted else 0.0, 1.0 - exp(-delta * 12.0))
	var speed_x := (global_position.x - _last_x) / maxf(delta, 0.0001)
	_last_x = global_position.x
	var lean := clampf(speed_x / 1600.0, -0.3, 0.3) if state == State.HELD else 0.0
	_tilt = lerpf(_tilt, lean, 1.0 - exp(-delta * 10.0))
	queue_redraw()


## Makes a vegetable waiting in its crate impossible to miss: a golden frame round the crate,
## a pulsing glow behind the vegetable and sparkles circling it.
func _draw_beacon() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 3.2)
	# A bright square frame (the plate is round and white, so this stands out), a glow, and an arrow.
	Paint.box(self, Rect2(-86, -80, 172, 160), Color(1.0, 0.9, 0.2, 0.16 + 0.12 * pulse), 18,
			Color(1.0, 0.78, 0.05, 0.85 + 0.15 * pulse), 9, 0)
	Paint.box(self, Rect2(-92, -86, 184, 172), Color(0, 0, 0, 0), 22,
			Color(0.35, 0.18, 0.0, 0.8), 3, 0)
	for i in 5:
		draw_circle(Vector2(0, 2), 80.0 - i * 10.0 + pulse * 6.0, Color(1.0, 0.93, 0.4, 0.05 + 0.03 * i))
	var bob := sin(_time * 6.0) * 7.0
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -122 + bob), Vector2(20, -122 + bob), Vector2(0, -92 + bob)]),
			Color(0.3, 0.15, 0.0))
	draw_colored_polygon(PackedVector2Array([Vector2(-15, -118 + bob), Vector2(15, -118 + bob), Vector2(0, -97 + bob)]),
			Color(1.0, 0.85, 0.1))
	for k in 4:
		var angle := _time * 1.4 + k * TAU / 4.0
		var at := Vector2(cos(angle), sin(angle)) * (72.0 + 5.0 * sin(_time * 5.0 + k))
		var twinkle := 0.5 + 0.5 * sin(_time * 7.0 + k * 1.7)
		Paint.star(self, at, 5.0 + 5.0 * twinkle, Color(1.0, 0.95, 0.55, 0.6 + 0.4 * twinkle))


func _draw() -> void:
	if state == State.ON_PLATE:
		_draw_beacon()
	var lift := 0.0
	var bob := 0.0
	var squash := Vector2.ONE
	match state:
		State.ON_PLATE:
			bob = sin(_time * 2.2) * 2.5
			var breathe := sin(_time * 2.2 + 1.2) * 0.02
			squash = Vector2(1.0 - breathe, 1.0 + breathe)
		State.HELD:
			lift = 8.0 + sin(_time * 7.0) * 1.5
		State.IN_POT:
			bob = sin(_time * 2.6 + position.x * 0.05) * 2.0
	# Soft shadow on whatever it rests on, shrinking as it lifts.
	if state != State.IN_POT:
		var shadow_scale := 1.0 - lift * 0.02
		draw_set_transform(Vector2(2, 34 + lift * 0.5), 0.0, Vector2(shadow_scale, 0.28 * shadow_scale))
		draw_circle(Vector2.ZERO, 36.0, Color(0, 0, 0, 0.32))
	draw_set_transform(Vector2(0, bob - lift), _tilt, squash)
	var tex := Sprites.veg(sprite_name())
	var size := DISPLAY * (1.0 + 0.12 * _swell)
	if tex != null:
		Sprites.draw_fit(self, tex, Vector2.ZERO, size)
	else:
		draw_circle(Vector2.ZERO, size * 0.4, Color.from_hsv(float(kind) / 15.0, 0.6, 0.9))
	draw_set_transform(Vector2.ZERO)
	if highlighted:
		draw_arc(Vector2.ZERO, 54.0, 0.0, TAU, 48, Color(1.0, 0.89, 0.35, 0.3), 12.0, true)
		draw_arc(Vector2.ZERO, 52.0, 0.0, TAU, 48, Color("ffe25a"), 4.0, true)
	if _hover_progress > 0.0:
		draw_arc(Vector2.ZERO, 61.0, -PI * 0.5, -PI * 0.5 + TAU * _hover_progress,
				48, Color("3ddc84"), 7.0, true)
