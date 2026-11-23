class_name Icons
extends RefCounted
## Procedural vector icons, drawn in the caller's _draw(). Unit box is ~[-1,1]; `s` is the pixel scale.

static func draw_icon(ci: CanvasItem, id: String, s: float, tint: Color) -> void:
	match id:
		"toy_car": _car(ci, s, tint)
		"book": _book(ci, s, tint)
		"clothes": _shirt(ci, s, tint)
		"stuffed_animal": _teddy(ci, s, tint)
		"fruit": _apple(ci, s, tint)
		"shoe": _shoe(ci, s, tint)
		"cup": _cup(ci, s, tint)
		"ball": _ball(ci, s, tint)
		_: _circ(ci, Vector2.ZERO, 0.7, s, tint)


static func _poly(ci: CanvasItem, pts: Array, s: float, col: Color) -> void:
	var p := PackedVector2Array()
	for v: Vector2 in pts:
		p.append(v * s)
	ci.draw_colored_polygon(p, col)
	p.append(p[0])
	ci.draw_polyline(p, col.darkened(0.45), maxf(2.0, s * 0.055), true)


static func _circ(ci: CanvasItem, c: Vector2, r: float, s: float, col: Color) -> void:
	ci.draw_circle(c * s, r * s, col)
	ci.draw_arc(c * s, r * s, 0.0, TAU, 32, col.darkened(0.45), maxf(2.0, s * 0.055), true)


static func _rect(ci: CanvasItem, pos: Vector2, size: Vector2, s: float, col: Color) -> void:
	var r := Rect2(pos * s, size * s)
	ci.draw_rect(r, col)
	ci.draw_rect(r, col.darkened(0.45), false, maxf(2.0, s * 0.055))


static func _car(ci: CanvasItem, s: float, c: Color) -> void:
	var glass := Color(0.82, 0.95, 1.0)
	_poly(ci, [Vector2(-1.0, 0.4), Vector2(-1.0, -0.05), Vector2(-0.75, -0.25),
		Vector2(0.75, -0.25), Vector2(1.0, -0.05), Vector2(1.0, 0.4)], s, c)
	_poly(ci, [Vector2(-0.55, -0.25), Vector2(-0.3, -0.7), Vector2(0.35, -0.7), Vector2(0.6, -0.25)], s, c.lightened(0.1))
	_poly(ci, [Vector2(-0.45, -0.3), Vector2(-0.27, -0.6), Vector2(-0.02, -0.6), Vector2(-0.02, -0.3)], s, glass)
	_poly(ci, [Vector2(0.08, -0.3), Vector2(0.08, -0.6), Vector2(0.32, -0.6), Vector2(0.48, -0.3)], s, glass)
	_circ(ci, Vector2(0.93, 0.05), 0.09, s, Color(1.0, 0.92, 0.4))
	_circ(ci, Vector2(-0.55, 0.4), 0.28, s, Color(0.2, 0.2, 0.25))
	_circ(ci, Vector2(0.55, 0.4), 0.28, s, Color(0.2, 0.2, 0.25))
	_circ(ci, Vector2(-0.55, 0.4), 0.11, s, Color(0.85, 0.85, 0.9))
	_circ(ci, Vector2(0.55, 0.4), 0.11, s, Color(0.85, 0.85, 0.9))


static func _book(ci: CanvasItem, s: float, c: Color) -> void:
	_rect(ci, Vector2(-0.62, -0.78), Vector2(1.34, 1.62), s, Color(0.98, 0.95, 0.85))
	_rect(ci, Vector2(-0.7, -0.88), Vector2(1.34, 1.62), s, c)
	_rect(ci, Vector2(-0.7, -0.88), Vector2(0.22, 1.62), s, c.darkened(0.25))
	_rect(ci, Vector2(-0.3, -0.62), Vector2(0.78, 0.3), s, Color(1, 1, 1, 0.92))
	_circ(ci, Vector2(0.09, 0.2), 0.22, s, Color(1, 1, 1, 0.85))
	_rect(ci, Vector2(-0.3, 0.55), Vector2(0.78, 0.07), s, Color(1, 1, 1, 0.85))


static func _shirt(ci: CanvasItem, s: float, c: Color) -> void:
	_poly(ci, [Vector2(-0.5, -0.75), Vector2(-0.2, -0.75), Vector2(0.0, -0.5), Vector2(0.2, -0.75),
		Vector2(0.5, -0.75), Vector2(1.0, -0.3), Vector2(0.8, 0.02), Vector2(0.5, -0.2),
		Vector2(0.5, 0.8), Vector2(-0.5, 0.8), Vector2(-0.5, -0.2), Vector2(-0.8, 0.02),
		Vector2(-1.0, -0.3)], s, c)
	_rect(ci, Vector2(-0.5, 0.2), Vector2(1.0, 0.16), s, c.lightened(0.45))
	_rect(ci, Vector2(-0.5, 0.45), Vector2(1.0, 0.16), s, c.lightened(0.45))
	ci.draw_polyline(PackedVector2Array([Vector2(-0.2, -0.75) * s, Vector2(0, -0.5) * s, Vector2(0.2, -0.75) * s]),
		c.darkened(0.45), maxf(3.0, s * 0.09), true)


static func _teddy(ci: CanvasItem, s: float, c: Color) -> void:
	var light := c.lightened(0.45)
	var dark := Color(0.25, 0.15, 0.12)
	_circ(ci, Vector2(-0.55, -0.78), 0.28, s, c)
	_circ(ci, Vector2(0.55, -0.78), 0.28, s, c)
	_circ(ci, Vector2(-0.55, -0.78), 0.13, s, light)
	_circ(ci, Vector2(0.55, -0.78), 0.13, s, light)
	_circ(ci, Vector2(-0.3, 0.88), 0.24, s, c)
	_circ(ci, Vector2(0.3, 0.88), 0.24, s, c)
	_circ(ci, Vector2(0.0, 0.4), 0.55, s, c)
	_circ(ci, Vector2(0.0, 0.5), 0.3, s, light)
	_circ(ci, Vector2(-0.62, 0.3), 0.21, s, c)
	_circ(ci, Vector2(0.62, 0.3), 0.21, s, c)
	_circ(ci, Vector2(0.0, -0.42), 0.62, s, c)
	_circ(ci, Vector2(0.0, -0.27), 0.26, s, light)
	_circ(ci, Vector2(0.0, -0.34), 0.09, s, dark)
	_circ(ci, Vector2(-0.23, -0.55), 0.07, s, dark)
	_circ(ci, Vector2(0.23, -0.55), 0.07, s, dark)


static func _apple(ci: CanvasItem, s: float, c: Color) -> void:
	_circ(ci, Vector2(-0.3, 0.12), 0.58, s, c)
	_circ(ci, Vector2(0.3, 0.12), 0.58, s, c)
	ci.draw_circle(Vector2(0.0, 0.12) * s, 0.5 * s, c)  # hides the seam
	ci.draw_line(Vector2(0.0, -0.4) * s, Vector2(0.08, -0.85) * s, Color(0.4, 0.25, 0.15), maxf(3.0, s * 0.1), true)
	_poly(ci, [Vector2(0.1, -0.7), Vector2(0.45, -0.95), Vector2(0.7, -0.7), Vector2(0.35, -0.55)], s, Color(0.35, 0.8, 0.35))
	ci.draw_arc(Vector2(-0.35, 0.1) * s, 0.38 * s, deg_to_rad(200), deg_to_rad(250), 10, Color(1, 1, 1, 0.55), maxf(3.0, s * 0.08), true)


static func _shoe(ci: CanvasItem, s: float, c: Color) -> void:
	_poly(ci, [Vector2(-0.95, 0.5), Vector2(-0.95, -0.05), Vector2(-0.3, -0.1), Vector2(0.0, -0.55),
		Vector2(0.4, -0.55), Vector2(0.5, -0.2), Vector2(0.95, 0.05), Vector2(0.95, 0.5)], s, c)
	_rect(ci, Vector2(-1.0, 0.42), Vector2(2.0, 0.26), s, Color(0.97, 0.97, 1.0))
	var lace := Color(1, 1, 1, 0.95)
	var w := maxf(3.0, s * 0.08)
	ci.draw_line(Vector2(0.02, -0.4) * s, Vector2(0.34, -0.3) * s, lace, w, true)
	ci.draw_line(Vector2(-0.1, -0.2) * s, Vector2(0.4, -0.08) * s, lace, w, true)
	ci.draw_line(Vector2(-0.25, 0.0) * s, Vector2(0.55, 0.12) * s, lace, w, true)


static func _cup(ci: CanvasItem, s: float, c: Color) -> void:
	var dark := c.darkened(0.45)
	ci.draw_arc(Vector2(0.45, 0.05) * s, 0.36 * s, -PI / 2.0, PI / 2.0, 16, dark, s * 0.24, true)
	ci.draw_arc(Vector2(0.45, 0.05) * s, 0.36 * s, -PI / 2.0, PI / 2.0, 16, c, s * 0.13, true)
	_rect(ci, Vector2(-0.7, -0.5), Vector2(1.2, 1.25), s, c)
	_rect(ci, Vector2(-0.7, -0.5), Vector2(1.2, 0.2), s, c.lightened(0.45))
	_rect(ci, Vector2(-0.45, 0.05), Vector2(0.7, 0.2), s, Color(1, 1, 1, 0.8))
	var steam := Color(0.6, 0.65, 0.8, 0.8)
	var w := maxf(3.0, s * 0.08)
	ci.draw_polyline(PackedVector2Array([Vector2(-0.3, -0.65) * s, Vector2(-0.2, -0.8) * s, Vector2(-0.3, -0.95) * s]), steam, w, true)
	ci.draw_polyline(PackedVector2Array([Vector2(0.1, -0.65) * s, Vector2(0.2, -0.8) * s, Vector2(0.1, -0.95) * s]), steam, w, true)


static func _ball(ci: CanvasItem, s: float, c: Color) -> void:
	ci.draw_circle(Vector2.ZERO, 0.85 * s, c)
	for a in [[-150.0, -90.0, Color(1, 1, 1, 0.9)], [-30.0, 30.0, Color(1, 1, 1, 0.9)], [90.0, 150.0, Color(1, 1, 1, 0.9)]]:
		var pts := PackedVector2Array([Vector2.ZERO])
		for k in 9:
			var ang := deg_to_rad(lerpf(a[0], a[1], k / 8.0))
			pts.append(Vector2(cos(ang), sin(ang)) * 0.85 * s)
		ci.draw_colored_polygon(pts, a[2])
	ci.draw_arc(Vector2.ZERO, 0.85 * s, 0.0, TAU, 40, c.darkened(0.45), maxf(2.0, s * 0.055), true)
	ci.draw_circle(Vector2.ZERO, 0.16 * s, c.darkened(0.2))
