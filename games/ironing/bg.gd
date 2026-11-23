extends Node2D
# Cozy living-room backdrop. Drawn once; blur.gdshader softens it into a depth-of-field look.

var sb := StyleBoxFlat.new()


func rr(r: Rect2, col: Color, rad: int = 12) -> void:
	sb.bg_color = col
	sb.set_corner_radius_all(rad)
	sb.set_border_width_all(0)
	sb.anti_aliasing = true
	draw_style_box(sb, r)


func ell(c: Vector2, rx: float, ry: float, n: int = 32) -> PackedVector2Array:
	var o := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		o.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return o


func leaf(b: Vector2, ang: float, l: float, w: float, col: Color) -> void:
	var d := Vector2.from_angle(ang)
	var p := d.orthogonal()
	var pts := PackedVector2Array([
		b, b + d * l * 0.35 + p * w * 0.8, b + d * l * 0.7 + p * w, b + d * l,
		b + d * l * 0.7 - p * w, b + d * l * 0.35 - p * w * 0.8])
	draw_colored_polygon(pts, col)
	draw_colored_polygon(PackedVector2Array([b, b + d * l * 0.6 + p * w * 0.2, b + d * l * 0.95, b + d * l * 0.6 - p * w * 0.9]), col.lightened(0.12))


func plant(base: Vector2, scale: float, n: int, seed_v: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	for i in n:
		var a := -PI / 2 + r.randf_range(-1.2, 1.2)
		var g := Color(0.20 + r.randf() * 0.12, 0.50 + r.randf() * 0.2, 0.25 + r.randf() * 0.1)
		leaf(base, a, scale * r.randf_range(0.7, 1.2), scale * 0.17, g)


func _draw() -> void:
	# --- wall
	var t := Color(0.50, 0.67, 0.86)
	var b := Color(0.42, 0.58, 0.80)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(1920, 0), Vector2(1920, 760), Vector2(0, 760)]), PackedColorArray([t, t, b, b]))
	# --- floor
	var f1 := Color(0.82, 0.52, 0.30)
	var f2 := Color(0.60, 0.34, 0.20)
	draw_polygon(PackedVector2Array([Vector2(0, 720), Vector2(1920, 720), Vector2(1920, 1080), Vector2(0, 1080)]), PackedColorArray([f1, f1, f2, f2]))
	for i in 26:
		draw_line(Vector2(960 + (i - 13) * 60, 720), Vector2(960 + (i - 13) * 150, 1080), Color(0.35, 0.18, 0.1, 0.3), 4.0)
	rr(Rect2(0, 690, 1920, 38), Color(0.95, 0.88, 0.80), 4)

	# --- window
	rr(Rect2(390, 20, 330, 420), Color(1, 1, 1), 10)
	var s1 := Color(0.62, 0.84, 0.98)
	var s2 := Color(0.88, 0.96, 1.0)
	draw_polygon(PackedVector2Array([Vector2(410, 40), Vector2(700, 40), Vector2(700, 420), Vector2(410, 420)]), PackedColorArray([s1, s1, s2, s2]))
	draw_colored_polygon(ell(Vector2(600, 330), 130, 90), Color(0.4, 0.72, 0.4, 0.85))
	draw_colored_polygon(ell(Vector2(500, 370), 110, 70), Color(0.3, 0.62, 0.35, 0.9))
	draw_colored_polygon(ell(Vector2(660, 250), 70, 60), Color(1, 1, 0.9, 0.5))
	draw_line(Vector2(555, 40), Vector2(555, 420), Color.WHITE, 12)
	draw_line(Vector2(410, 230), Vector2(700, 230), Color.WHITE, 12)
	# --- curtains
	var c1 := Color(0.93, 0.62, 0.55)
	var c2 := Color(0.98, 0.78, 0.70)
	draw_polygon(PackedVector2Array([Vector2(215, 0), Vector2(400, 0), Vector2(380, 640), Vector2(190, 640)]), PackedColorArray([c1, c2, c2, c1]))
	draw_polygon(PackedVector2Array([Vector2(710, 0), Vector2(860, 0), Vector2(880, 600), Vector2(720, 640)]), PackedColorArray([c2, c1, c1, c2]))
	for i in 4:
		draw_line(Vector2(240 + i * 40, 0), Vector2(225 + i * 38, 640), Color(0.7, 0.4, 0.35, 0.25), 8)

	# --- sofa
	rr(Rect2(300, 420, 520, 230), Color(0.86, 0.50, 0.40), 50)
	rr(Rect2(300, 520, 520, 160), Color(0.93, 0.58, 0.45), 40)
	rr(Rect2(410, 470, 140, 110), Color(1.0, 0.76, 0.28), 26)

	# --- plants
	plant(Vector2(950, 700), 330, 11, 3)
	rr(Rect2(890, 680, 120, 90), Color(0.8, 0.5, 0.4), 18)
	plant(Vector2(190, 760), 420, 13, 9)
	rr(Rect2(100, 740, 190, 150), Color(0.9, 0.72, 0.68), 26)

	# --- shelf + picture
	rr(Rect2(1140, 184, 380, 22), Color(0.88, 0.52, 0.30), 6)
	rr(Rect2(1325, 44, 100, 125), Color(0.95, 0.88, 0.80), 6)
	rr(Rect2(1337, 56, 76, 100), Color(0.98, 0.72, 0.74), 4)
	rr(Rect2(1290, 140, 40, 44), Color(0.5, 0.75, 0.6), 10)

	# --- bookcase
	rr(Rect2(1632, 0, 300, 1080), Color(0.64, 0.38, 0.22), 6)
	for i in 4:
		var y := 40.0 + i * 180.0
		rr(Rect2(1632, y + 130, 300, 20), Color(0.78, 0.48, 0.28), 4)
		var x := 1660.0
		var r := RandomNumberGenerator.new()
		r.seed = i + 40
		while x < 1850:
			var w := r.randf_range(20, 36)
			var h := r.randf_range(70, 120)
			rr(Rect2(x, y + 130 - h, w, h), Color.from_hsv(r.randf(), 0.45, 0.8), 3)
			x += w + 3
	# lamp
	rr(Rect2(1850, 470, 90, 110), Color(1.0, 0.82, 0.62), 30)
	draw_colored_polygon(ell(Vector2(1895, 640), 55, 55), Color(0.55, 0.35, 0.7))

	# --- teal armchair + pouf
	rr(Rect2(1300, 570, 340, 230), Color(0.15, 0.50, 0.55), 55)
	rr(Rect2(1330, 650, 280, 150), Color(0.20, 0.60, 0.62), 40)
	draw_colored_polygon(ell(Vector2(1840, 800), 110, 130), Color(0.18, 0.5, 0.58))
	draw_colored_polygon(ell(Vector2(1900, 780), 70, 90), Color(0.9, 0.45, 0.5, 0.9))

	# --- rug
	draw_colored_polygon(ell(Vector2(1470, 910), 300, 80), Color(0.95, 0.85, 0.65, 0.9))
