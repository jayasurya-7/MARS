class_name Paint
extends RefCounted
## Small drawing helpers shared by the illustrated scenery. Every function draws onto the
## CanvasItem passed in and must be called from that item's _draw().


static func box(ci: CanvasItem, rect: Rect2, fill: Color, radius: int = 8,
		border: Color = Color(0, 0, 0, 0), border_w: int = 0, shadow: int = 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	if shadow > 0:
		sb.shadow_color = Color(0, 0, 0, 0.38)
		sb.shadow_size = shadow
		sb.shadow_offset = Vector2(0, shadow * 0.5)
	sb.draw(ci.get_canvas_item(), rect)


static func vgrad(ci: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	var a := rect.position
	var b := rect.end
	ci.draw_polygon(PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]),
			PackedColorArray([top, top, bottom, bottom]))


static func hgrad(ci: CanvasItem, rect: Rect2, left: Color, right: Color) -> void:
	var a := rect.position
	var b := rect.end
	ci.draw_polygon(PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]),
			PackedColorArray([left, right, right, left]))


## A circle squashed vertically, for surfaces seen at an angle.
static func ellipse(ci: CanvasItem, center: Vector2, rx: float, ry: float, color: Color) -> void:
	ci.draw_set_transform(center, 0.0, Vector2(1.0, ry / rx))
	ci.draw_circle(Vector2.ZERO, rx, color)
	ci.draw_set_transform(Vector2.ZERO)


static func ellipse_arc(ci: CanvasItem, center: Vector2, rx: float, ry: float,
		from_angle: float, to_angle: float, color: Color, width: float) -> void:
	ci.draw_set_transform(center, 0.0, Vector2(1.0, ry / rx))
	ci.draw_arc(Vector2.ZERO, rx, from_angle, to_angle, 48, color, width, true)
	ci.draw_set_transform(Vector2.ZERO)


## A shaded sphere: dark outline, shadowed body, lit body, highlight.
static func ball(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c, r + 2.5, col.darkened(0.6))
	ci.draw_circle(c, r, col.darkened(0.22))
	ci.draw_circle(c + Vector2(-r * 0.12, -r * 0.16), r * 0.82, col)
	ci.draw_circle(c + Vector2(-r * 0.34, -r * 0.38), r * 0.24, col.lightened(0.5))


static func star(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + TAU * i / 10.0
		pts.append(c + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.45))
	ci.draw_colored_polygon(pts, col)
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, col.darkened(0.55), 2.0, true)


static func leaf(ci: CanvasItem, base: Vector2, angle: float, length: float, width: float,
		col: Color) -> void:
	var dir := Vector2.from_angle(angle)
	var side := dir.orthogonal()
	var pts := PackedVector2Array()
	for i in range(0, 9):
		var t := i / 8.0
		pts.append(base + dir * length * t + side * width * sin(PI * t) * (1.0 - 0.25 * t))
	for i in range(7, 0, -1):
		var t := i / 8.0
		pts.append(base + dir * length * t - side * width * sin(PI * t) * (1.0 - 0.25 * t))
	ci.draw_colored_polygon(pts, col)
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, col.darkened(0.45), 1.8, true)
	ci.draw_line(base, base + dir * length * 0.9, col.lightened(0.3), 1.5, true)
