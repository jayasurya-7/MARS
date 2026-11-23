class_name Spoon
extends Grabbable
## The wooden spoon. Only grabbable during the stirring phase. Its head tracks the hand and
## its handle always points away from the pot's centre.

var enabled := false:
	set(value):
		enabled = value
		modulate.a = 1.0 if enabled else 0.45
		if not enabled:
			set_highlighted(false)

var _rest_point := Vector2.ZERO
var _tween: Tween


func can_grab() -> bool:
	return enabled and super()


func set_rest_point(local_point: Vector2) -> void:
	_kill_tween()
	_rest_point = local_point
	position = local_point
	_face_outward()


func follow(point: Vector2) -> void:
	super(point)
	_face_outward()


func _on_grabbed() -> void:
	_kill_tween()
	z_index = 10


## Slides back onto the ring, so it can always be reached again.
func _on_dropped() -> void:
	z_index = 0
	var length := position.length()
	var target := _rest_point
	if length > 1.0:
		target = position / length * _rest_point.length()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target, 0.25)
	_tween.tween_callback(_face_outward)


func _face_outward() -> void:
	if position.length_squared() > 1.0:
		rotation = position.angle()


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()


func _draw() -> void:
	var wood := Color("d19a58")
	var dark := Color("6e4524")
	# Soft shadow cast on the counter and the broth.
	draw_line(Vector2(14, 9), Vector2(196, 9), Color(0, 0, 0, 0.22), 14.0, true)
	draw_line(Vector2(12, 0), Vector2(196, 0), dark, 15.0, true)
	draw_line(Vector2(12, 0), Vector2(196, 0), wood, 10.0, true)
	draw_line(Vector2(16, -2.5), Vector2(192, -2.5), Color("efc88c"), 2.5, true)
	draw_circle(Vector2(196, 0), 8.0, dark)
	draw_circle(Vector2(196, 0), 5.5, wood)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.25, 0.9))
	draw_circle(Vector2.ZERO, 23.0, dark)
	draw_circle(Vector2.ZERO, 19.5, wood)
	draw_circle(Vector2(-2, 0), 12.5, dark.lerp(wood, 0.5))
	draw_arc(Vector2(-1, -1), 16.0, PI * 1.05, PI * 1.6, 12, Color("efc88c"), 2.5, true)
	draw_set_transform(Vector2.ZERO)
	if highlighted:
		draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 48, Color("ffe25a"), 5.0, true)
