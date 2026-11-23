class_name ColorRegion
extends Area2D
## One colourable area of the picture: white Polygon2D fill + black outline + Area2D collision.
## The fill is tinted through `modulate`, as in the design brief.

signal filled(region: ColorRegion)

const OUTLINE_COLOR := Color("1f2230")
const OUTLINE_W := 7.0

var region_name: String
var color_id: StringName
var target_color: Color
var step: int
var polygon: PackedVector2Array
var locked := false

var _fill: Polygon2D
var _outline: Line2D
var _particles: CPUParticles2D
var _pulse_tween: Tween
var _hint_color := Color(1, 0.95, 0.75)

func setup(data: Dictionary, color: Color, particle_tex: Texture2D) -> void:
	region_name = data.name
	color_id = data.color
	target_color = color
	step = data.step
	polygon = data.poly
	_hint_color = Color.WHITE.lerp(color, 0.4)
	monitoring = false
	monitorable = false
	input_pickable = false

	_fill = Polygon2D.new()
	_fill.name = "Fill"
	_fill.polygon = polygon
	_fill.color = Color.WHITE        # stays white; colour comes from modulate
	_fill.antialiased = true
	add_child(_fill)

	var col := CollisionPolygon2D.new()
	col.name = "Hitbox"
	col.polygon = polygon
	add_child(col)

	_outline = _make_line(polygon, OUTLINE_W, true)
	_outline.name = "Outline"
	for d in data.details:
		_make_line(d, OUTLINE_W * 0.7, false)

	_particles = CPUParticles2D.new()
	_particles.name = "Burst"
	_particles.emitting = false
	_particles.one_shot = true
	_particles.amount = 44
	_particles.lifetime = 1.2
	_particles.explosiveness = 0.95
	_particles.texture = particle_tex
	_particles.direction = Vector2.UP
	_particles.spread = 180.0
	_particles.initial_velocity_min = 220.0
	_particles.initial_velocity_max = 480.0
	_particles.gravity = Vector2(0, 520)
	_particles.scale_amount_min = 0.5
	_particles.scale_amount_max = 1.1
	_particles.angular_velocity_min = -240.0
	_particles.angular_velocity_max = 240.0
	_particles.color = color.lightened(0.25)
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	_particles.color_ramp = fade
	_particles.position = _centroid()
	_particles.z_index = 20
	add_child(_particles)

func _make_line(pts: PackedVector2Array, w: float, closed: bool) -> Line2D:
	var l := Line2D.new()
	l.points = pts
	l.closed = closed
	l.width = w
	l.default_color = OUTLINE_COLOR
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	l.antialiased = true
	add_child(l)
	return l

func _centroid() -> Vector2:
	var lo := polygon[0]
	var hi := polygon[0]
	for p in polygon:
		lo = lo.min(p)
		hi = hi.max(p)
	return (lo + hi) * 0.5

## `global_pos` in canvas/screen space (no camera is used).
func contains_point(global_pos: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(to_local(global_pos), polygon)

## Pulsing hint: tells the player "paint me next".
func highlight(on: bool) -> void:
	_stop_pulse()
	if on and not locked:
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_method(_apply_pulse, 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_pulse_tween.tween_method(_apply_pulse, 1.0, 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply_pulse(v: float) -> void:
	_fill.modulate = Color.WHITE.lerp(_hint_color, v)
	_outline.width = lerpf(OUTLINE_W, OUTLINE_W * 2.0, v)

func _stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	if not locked:
		_fill.modulate = Color.WHITE
	_outline.width = OUTLINE_W

## Colour the region, lock it, burst particles.
func fill_with(color: Color) -> void:
	locked = true
	_stop_pulse()
	var t := create_tween()
	t.tween_property(_fill, "modulate", color.lightened(0.35), 0.12)
	t.tween_property(_fill, "modulate", color, 0.35).set_trans(Tween.TRANS_SINE)
	_particles.color = color.lightened(0.25)
	_particles.restart()
	_particles.emitting = true
	filled.emit(self)

func reset() -> void:
	locked = false
	_stop_pulse()
	_fill.modulate = Color.WHITE
