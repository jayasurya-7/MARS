class_name BrushCursor
extends Node2D
## Paintbrush cursor. The brush TIP is the hotspot (node origin).
## A ring around the tip fills while the patient dwells on a target.

const RING_R := 36.0
const DARK := Color("1f2230")

var brush_color := Color("f2f2f2")
var progress := 0.0

func set_brush(c: Color) -> void:
	brush_color = c
	queue_redraw()

func clear_brush() -> void:
	set_brush(Color("f2f2f2"))

func set_progress(p: float) -> void:
	if not is_equal_approx(p, progress):
		progress = p
		queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, RING_R, 0, TAU, 64, Color(0, 0, 0, 0.22), 9.0, true)
	draw_arc(Vector2.ZERO, RING_R, 0, TAU, 64, Color(1, 1, 1, 0.95), 5.0, true)
	if progress > 0.0:
		draw_arc(Vector2.ZERO, RING_R, -PI / 2.0, -PI / 2.0 + TAU * progress, 64, Color("2fa84f"), 11.0, true)

	var bristle := PackedVector2Array([Vector2(0, 0), Vector2(14, -9), Vector2(34, -15), Vector2(54, -14),
		Vector2(54, 14), Vector2(34, 15), Vector2(14, 9)])
	var ferrule := PackedVector2Array([Vector2(54, -15), Vector2(86, -15), Vector2(86, 15), Vector2(54, 15)])
	var handle := PackedVector2Array([Vector2(86, -12), Vector2(220, -8), Vector2(238, 0), Vector2(220, 8), Vector2(86, 12)])

	# soft shadow, then the brush itself (rotated so the handle points up-right)
	draw_set_transform(Vector2(7, 9), deg_to_rad(-42))
	for poly in [bristle, ferrule, handle]:
		draw_colored_polygon(poly, Color(0, 0, 0, 0.18))
	draw_set_transform(Vector2.ZERO, deg_to_rad(-42))
	draw_colored_polygon(handle, Color("c4743a"))
	draw_colored_polygon(ferrule, Color("c7ccd6"))
	draw_colored_polygon(bristle, brush_color)
	for poly in [handle, ferrule, bristle]:
		var closed: PackedVector2Array = poly.duplicate()
		closed.append(closed[0])
		draw_polyline(closed, DARK, 3.0, true)
	draw_set_transform(Vector2.ZERO, 0.0)
	draw_circle(Vector2.ZERO, 5.0, DARK)
