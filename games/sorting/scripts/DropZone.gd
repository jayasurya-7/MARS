class_name DropZone
extends Area2D
## A target bin. Validates incoming items, hands out snap slots, and draws itself
## (glass card, glowing border, category icon, live "2 / 3" counter).

signal item_accepted(item: InteractableItem, zone: DropZone)
signal item_rejected(item: InteractableItem, zone: DropZone)
signal filled(zone: DropZone)

@export var category_id: String = ""
@export var display_name: String = ""
@export var accent := Color.WHITE
@export var zone_size := Vector2(400, 290)

var capacity := 0
var count := 0

var _hovered := false
var _hint := false
var _hover := 0.0
var _hint_amt := 0.0
var _flash := 0.0
var _glow := 0.0
var _ring_t := 1.0
var _ring_pos := Vector2.ZERO
var _style := StyleBoxFlat.new()
var _frame := StyleBoxFlat.new()
var _lid_style := StyleBoxFlat.new()
var _lid := 0.0
var _lid_done := false


func _ready() -> void:
	add_to_group("drop_zones")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = zone_size
	shape.shape = rect
	add_child(shape)
	_style.set_corner_radius_all(40)
	_frame.draw_center = false
	_frame.set_corner_radius_all(52)
	_lid_style.set_corner_radius_all(16)
	_lid_style.set_border_width_all(3)


func configure(id: String, title: String, color: Color) -> void:
	category_id = id
	display_name = title
	accent = color


func set_capacity(n: int) -> void:
	capacity = n
	count = 0
	_lid = 0.0
	_lid_done = false


## Called by the item: does this bin accept it?
func validate(item: InteractableItem) -> bool:
	return item.category_id == category_id


## Registers the item and returns the global position it should snap to.
func accept(item: InteractableItem) -> Vector2:
	var slot := get_slot_global(count)
	count += 1
	_glow = 1.0
	item_accepted.emit(item, self)
	return slot


func reject(item: InteractableItem) -> void:
	_flash = 1.0
	item_rejected.emit(item, self)


func celebrate(at_global: Vector2) -> void:
	_ring_pos = to_local(at_global)
	_ring_t = 0.0
	SortFx.burst(self, at_global, accent)
	if capacity > 0 and count >= capacity and not _lid_done:
		_lid_done = true
		var tw := create_tween()
		tw.tween_interval(0.35)
		tw.tween_property(self, "_lid", 1.0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		filled.emit(self)


func set_hover(on: bool) -> void:
	_hovered = on


func set_hint(on: bool) -> void:
	_hint = on


func contains_point(p: Vector2) -> bool:
	return Rect2(-zone_size * 0.5, zone_size).has_point(to_local(p))


func slot_local(i: int) -> Vector2:
	var cols := clampi(capacity, 1, 4)
	var col := i % cols
	var row := floori(float(i) / cols)
	return Vector2((col - (cols - 1) * 0.5) * 112.0, 45.0 + row * 92.0)


func get_slot_global(i: int) -> Vector2:
	return to_global(slot_local(i))


func _process(delta: float) -> void:
	_hover = move_toward(_hover, 1.0 if _hovered else 0.0, delta * 6.0)
	_hint_amt = move_toward(_hint_amt, 1.0 if _hint else 0.0, delta * 4.0)
	_flash = move_toward(_flash, 0.0, delta * 2.2)
	_glow = move_toward(_glow, 0.0, delta * 1.5)
	_ring_t = minf(1.0, _ring_t + delta * 1.6)
	scale = Vector2.ONE * (1.0 + 0.05 * _hover)  # bin grows a little when targeted
	queue_redraw()


func _draw() -> void:
	var half := zone_size * 0.5
	var t := Time.get_ticks_msec() * 0.001
	var emphasis := clampf(_hover + _hint_amt * (0.5 + 0.5 * sin(t * 2.5)) * 0.8, 0.0, 1.0)
	var shake := sin(_flash * 40.0) * 8.0 * _flash

	draw_set_transform(Vector2(shake, 0.0), 0.0, Vector2.ONE)
	_style.bg_color = Color(0.17, 0.2, 0.28, 0.85).lerp(accent, 0.10 + 0.14 * emphasis + 0.15 * _glow)
	_style.border_color = accent.lerp(Color.WHITE, 0.35 * _hover).lerp(Color(0.9, 0.65, 0.5), _flash)
	_style.set_border_width_all(int(6 + 5 * emphasis))
	_style.shadow_color = Color(0, 0, 0, 0.18 + 0.12 * emphasis)
	_style.shadow_size = int(14 + 10 * emphasis)
	_style.draw(get_canvas_item(), Rect2(-half, zone_size))

	# HINT (correct bin for the carried item): pulsing coloured frame + bouncing arrow
	if _hint_amt > 0.01:
		var pulse := 0.55 + 0.45 * sin(t * 3.0)
		_frame.border_color = Color(accent.lightened(0.45), _hint_amt * pulse)
		_frame.set_border_width_all(7)
		_frame.draw(get_canvas_item(), Rect2(-half, zone_size).grow(24.0))
		var a := Vector2(0, half.y + 46.0 + sin(t * 4.0) * 8.0)
		var tri := PackedVector2Array([a + Vector2(0, -24), a + Vector2(28, 14), a + Vector2(-28, 14)])
		draw_colored_polygon(tri, Color(1.0, 0.97, 0.88, _hint_amt))
		tri.append(tri[0])
		draw_polyline(tri, Color(accent.darkened(0.3), _hint_amt), 4.0, true)

	# TARGET (carried item is over this bin): thick bright cream frame
	if _hover > 0.01:
		_frame.border_color = Color(1.0, 0.97, 0.88, _hover)
		_frame.set_border_width_all(10)
		_frame.draw(get_canvas_item(), Rect2(-half, zone_size).grow(10.0))

	# header token with the category icon
	var icon_pos := Vector2(-half.x + 72.0, -half.y + 70.0)
	draw_circle(icon_pos, 46.0, Color(0.97, 0.98, 1.0))
	draw_arc(icon_pos, 43.0, 0.0, TAU, 40, accent, 5.0, true)
	draw_set_transform(Vector2(shake, 0.0) + icon_pos, 0.0, Vector2.ONE)
	Icons.draw_icon(self, category_id, 26.0, accent)
	draw_set_transform(Vector2(shake, 0.0), 0.0, Vector2.ONE)

	var font := ThemeDB.fallback_font
	var tx := -half.x + 135.0
	draw_string(font, Vector2(tx + 2, -half.y + 80), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color(0, 0, 0, 0.4))
	draw_string(font, Vector2(tx, -half.y + 78), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color.WHITE)
	draw_string(font, Vector2(tx, -half.y + 116), "%d / %d" % [count, capacity], HORIZONTAL_ALIGNMENT_LEFT, -1, 30,
		accent.lightened(0.4))

	# empty slot rings
	for i in capacity:
		if i < count:
			continue
		var sp := slot_local(i)
		draw_circle(sp, 46.0, Color(1, 1, 1, 0.05))
		draw_arc(sp, 46.0, 0.0, TAU, 40, Color(1, 1, 1, 0.28), 3.0, true)

	# "complete" badge
	if capacity > 0 and count >= capacity:
		var b := Vector2(half.x - 48.0, -half.y + 48.0)
		draw_circle(b, 26.0, Color(0.3, 0.85, 0.5))
		draw_polyline(PackedVector2Array([b + Vector2(-11, 1), b + Vector2(-3, 10), b + Vector2(12, -9)]),
			Color.WHITE, 6.0, true)

	# lid drops onto a full bin
	if _lid > 0.0:
		var ly := lerpf(-half.y - 140.0, -half.y - 4.0, _lid)
		var a := minf(1.0, _lid * 4.0)
		_lid_style.bg_color = Color(accent.darkened(0.15), a)
		_lid_style.border_color = Color(1.0, 0.97, 0.88, a)
		_lid_style.draw(get_canvas_item(), Rect2(-40.0, ly - 34.0, 80.0, 16.0))  # handle
		_lid_style.draw(get_canvas_item(), Rect2(-half.x - 10.0, ly - 22.0, zone_size.x + 20.0, 30.0))

	# success shockwave
	if _ring_t < 1.0:
		draw_arc(_ring_pos, 30.0 + 130.0 * _ring_t, 0.0, TAU, 48,
			Color(accent.r, accent.g, accent.b, 1.0 - _ring_t), 7.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
