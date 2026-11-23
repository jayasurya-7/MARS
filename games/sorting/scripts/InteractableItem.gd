class_name InteractableItem
extends Area2D
## A sortable object. Click (or dwell) once to pick it up, it then follows the cursor
## with smoothing (filters tremor); click again to drop. No sustained hold needed.

signal picked_up(item: InteractableItem)
signal released(item: InteractableItem)
signal sorted(item: InteractableItem, zone: DropZone)
signal rejected(item: InteractableItem, zone: DropZone)

enum State { IDLE, HELD, RETURNING, SORTED }

const RADIUS := 82.0          ## visual radius
const SHAPE_RADIUS := 100.0   ## forgiving collision radius

## The item currently carried (only one at a time).
static var held: InteractableItem = null

@export var category_id: String = ""
@export var follow_speed := 12.0  ## higher = snappier, lower = smoother (more tremor filtering)
@export var pick_radius := 100.0

var accent := Color.WHITE
var tint := Color.WHITE
var home_position := Vector2.ZERO
var state := State.IDLE
var lift := 0.0  ## 0..1, animated while carried

var _tween: Tween
var _shape: CollisionShape2D
var _hover := 0.0
var _phase := randf()
var _target_zone: DropZone = null
var _heart_t := 1.0


func _ready() -> void:
	input_pickable = false
	_shape = CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = SHAPE_RADIUS
	_shape.shape = c
	add_child(_shape)


func contains_point(p: Vector2) -> bool:
	return global_position.distance_to(p) <= pick_radius


func is_selectable_at(p: Vector2) -> bool:
	return state == State.IDLE and contains_point(p)


func pop_in(delay: float) -> void:
	scale = Vector2.ZERO
	_tween = create_tween()
	_tween.tween_interval(delay)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _input(event: InputEvent) -> void:
	if state == State.SORTED or state == State.RETURNING:
		return
	var pressed := false
	if event is InputEventMouseButton:
		pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event.is_action_pressed("ui_accept"):
		pressed = true
	if not pressed:
		return
	if state == State.HELD:
		get_viewport().set_input_as_handled()
		_release()
	elif not is_instance_valid(held) and contains_point(GamePointer.world(self)):
		get_viewport().set_input_as_handled()
		_pick()


func _process(delta: float) -> void:
	if state == State.SORTED:
		_heart_t = minf(1.0, _heart_t + delta * 0.9)
		queue_redraw()
		return
	var mouse := GamePointer.world(self)
	if state == State.HELD:
		global_position = global_position.lerp(mouse, 1.0 - exp(-follow_speed * delta))
		var z := find_target_zone()
		if z != _target_zone:
			if _target_zone:
				_target_zone.set_hover(false)
			_target_zone = z
			if _target_zone:
				_target_zone.set_hover(true)
	var want := 1.0 if (state == State.IDLE and not is_instance_valid(held) and contains_point(mouse)) else 0.0
	_hover = move_toward(_hover, want, delta * 6.0)
	if state == State.IDLE and not (_tween and _tween.is_running()):
		scale = Vector2.ONE * (1.0 + 0.1 * _hover)  # hovered item grows a little
	queue_redraw()


## Closest bin overlapped by this item's Area2D (falls back to a geometric test).
func find_target_zone() -> DropZone:
	var best: DropZone = null
	var best_d := INF
	for a in get_overlapping_areas():
		var zone := a as DropZone
		if zone:
			var d := global_position.distance_squared_to(zone.global_position)
			if d < best_d:
				best_d = d
				best = zone
	if best == null:
		for n in get_tree().get_nodes_in_group("drop_zones"):
			var zone := n as DropZone
			if zone and zone.contains_point(global_position):
				var d := global_position.distance_squared_to(zone.global_position)
				if d < best_d:
					best_d = d
					best = zone
	return best


func _pick() -> void:
	held = self
	state = State.HELD
	z_index = 100
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", Vector2.ONE * 1.18, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "lift", 1.0, 0.18)
	picked_up.emit(self)


func _release() -> void:
	if held == self:
		held = null
	var zone := find_target_zone()
	if _target_zone:
		_target_zone.set_hover(false)
		_target_zone = null
	released.emit(self)
	if zone != null and zone.validate(self):
		_snap_to(zone)
	else:
		if zone != null:
			zone.reject(self)
		rejected.emit(self, zone)
		_return_home(zone != null)


func _snap_to(zone: DropZone) -> void:
	state = State.SORTED
	_shape.set_deferred("disabled", true)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var slot := zone.accept(self)
	z_index = 5
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "global_position", slot, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE * 0.5, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "lift", 0.0, 0.38)
	_tween.chain().tween_callback(zone.celebrate.bind(slot))
	_tween.tween_callback(_landed)
	sorted.emit(self, zone)


## A little "happy" reaction once the item settles in its bin, plus a floating heart.
func _landed() -> void:
	_heart_t = 0.0
	var base := position
	var tw := create_tween()
	match category_id:
		"stuffed_animal", "ball":
			for i in 2:
				tw.tween_property(self, "position:y", base.y - 18.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(self, "position:y", base.y, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		"toy_car":
			for dx: float in [10.0, -10.0, 6.0, 0.0]:
				tw.tween_property(self, "position:x", base.x + dx, 0.09)
		_:
			for r: float in [0.25, -0.22, 0.12, 0.0]:
				tw.tween_property(self, "rotation", r, 0.1)


func _return_home(shake: bool) -> void:
	state = State.RETURNING
	if _tween:
		_tween.kill()
	_tween = create_tween()
	if shake:
		var p := global_position
		for dx in [16.0, -16.0, 10.0, -10.0, 0.0]:
			_tween.tween_property(self, "global_position", p + Vector2(dx, 0), 0.05)
	_tween.tween_property(self, "global_position", home_position, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.75)
	_tween.parallel().tween_property(self, "lift", 0.0, 0.75)
	_tween.tween_callback(_on_home)


func _on_home() -> void:
	state = State.IDLE
	z_index = 0


func _draw() -> void:
	var bob := 0.0
	if state == State.IDLE:
		bob = sin(Time.get_ticks_msec() * 0.0016 + _phase * TAU) * 2.5
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	var emph := maxf(_hover, lift)

	for i in 4:
		draw_circle(Vector2(0, 12 + 20 * lift), RADIUS + 16 - i * 4 + 8 * lift, Color(0, 0, 0, 0.07))
	if emph > 0.01:
		for i in 5:
			draw_circle(Vector2.ZERO, RADIUS + 8 + i * 7,
				Color(accent.r, accent.g, accent.b, 0.06 * emph * (1.0 - i / 5.0)))

	draw_circle(Vector2.ZERO, RADIUS, Color(0.97, 0.98, 1.0).lerp(accent, 0.12))
	draw_arc(Vector2.ZERO, RADIUS - 3.0, 0.0, TAU, 64, accent, 7.0, true)
	if emph > 0.01:  # clear cream ring = "this is the item you are pointing at / carrying"
		draw_arc(Vector2.ZERO, RADIUS + 8.0, 0.0, TAU, 64, Color(1.0, 0.97, 0.88, emph), 7.0, true)
	Icons.draw_icon(self, category_id, 46.0, tint)
	draw_arc(Vector2.ZERO, RADIUS - 16.0, deg_to_rad(200), deg_to_rad(250), 12, Color(1, 1, 1, 0.8), 5.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _heart_t < 1.0:
		var hp := Vector2(0, -RADIUS - 30.0 - 60.0 * _heart_t)
		var hc := Color(0.9, 0.55, 0.62, 1.0 - _heart_t)
		draw_circle(hp + Vector2(-11, 0), 13.0, hc)
		draw_circle(hp + Vector2(11, 0), 13.0, hc)
		draw_colored_polygon(PackedVector2Array([hp + Vector2(-23, 5), hp + Vector2(23, 5), hp + Vector2(0, 30)]), hc)
