class_name ItemPool
extends Node2D
## The large glass-like tray at the bottom that holds the unsorted items.

@export var size := Vector2(1800, 500)
var _style := StyleBoxFlat.new()


func _ready() -> void:
	z_index = -10
	_style.bg_color = Color(1, 1, 1, 0.07)
	_style.border_color = Color(1, 1, 1, 0.24)
	_style.set_border_width_all(3)
	_style.set_corner_radius_all(56)
	_style.shadow_color = Color(0, 0, 0, 0.35)
	_style.shadow_size = 30


func _draw() -> void:
	_style.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	# soft inner highlight along the top edge
	draw_arc(Vector2(size.x * 0.5, 70), size.x * 0.5 - 90, deg_to_rad(205), deg_to_rad(335), 60,
		Color(1, 1, 1, 0.07), 4.0, true)


func get_pool_rect() -> Rect2:
	return Rect2(global_position, size)
