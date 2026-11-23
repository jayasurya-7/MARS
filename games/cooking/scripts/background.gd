extends Node2D
## The kitchen: tiled wall, shelf of jars, plank counter, stove top, produce crates (left)
## and steel trays (right), plus decorative baskets and greens that are not interactive.

const W := 1280.0
const H := 720.0
const COUNTER_Y := 156.0

var plates := PackedVector2Array()
var stove_center := Vector2(640, 415)
## Crates that hold a vegetable this round. The others are dimmed so the live ones stand out.
var active_slots := PackedVector2Array()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func set_active_slots(points: PackedVector2Array) -> void:
	active_slots = points
	queue_redraw()


func set_plates(points: PackedVector2Array) -> void:
	plates = points
	queue_redraw()


func _draw() -> void:
	_wall()
	_shelf()
	_counter()
	_warm_light()
	_stove()
	_basket(Vector2(285, 480), 62.0, [
		["potato", Vector2(-24, -12), 54.0], ["potato", Vector2(22, -14), 52.0],
		["potato", Vector2(0, 6), 56.0], ["potato", Vector2(-28, 14), 46.0],
		["potato", Vector2(28, 12), 48.0], ["garlic", Vector2(2, -26), 40.0]])
	_basket(Vector2(995, 480), 62.0, [
		["onion", Vector2(-24, -12), 52.0], ["onion", Vector2(22, -14), 50.0],
		["onion", Vector2(0, 6), 54.0], ["garlic", Vector2(-28, 14), 44.0],
		["garlic", Vector2(28, 12), 44.0], ["onion", Vector2(2, -26), 40.0]])
	_left_produce()
	_right_produce()
	for point in plates:
		if point.x < W * 0.5:
			_crate(point)
		else:
			_tray(point)
		if not active_slots.is_empty() and not active_slots.has(point):
			Paint.ellipse(self, point, 74.0, 68.0, Color(0.05, 0.03, 0.02, 0.22))


func _wall() -> void:
	Paint.vgrad(self, Rect2(0, 0, W, COUNTER_Y + 4), Color("4a5d4b"), Color("2b3a31"))
	# Subway tiles in a running bond.
	for row in 5:
		var offset := 32.0 if row % 2 == 1 else 0.0
		var x := -offset
		var n := 0
		while x < W:
			var shade := 0.03 + 0.02 * float((n + row) % 3)
			draw_rect(Rect2(x + 1.5, row * 32.0 + 1.5, 61.0, 29.0), Color(1, 1, 1, shade))
			x += 64.0
			n += 1


func _shelf() -> void:
	var palette := [Color("d9a441"), Color("a33a2a"), Color("7a9a3a"), Color("e9e2cf"),
			Color("8a5a2b"), Color("c46a2c")]
	for i in 2:
		_jar(935.0 + i * 80.0, 30.0, 36.0 + float((i * 5) % 10), palette[(i + 2) % 6])
	_stand("shaker-salt", Vector2(418, 140), 50.0)
	_stand("bottle-ketchup", Vector2(860, 140), 54.0)
	_stand("shaker-pepper", Vector2(915, 140), 44.0)
	_stand("bottle-oil", Vector2(1005, 140), 50.0)
	_stand("pepper-mill", Vector2(1078, 140), 52.0)
	draw_rect(Rect2(0, 134, W, 14), Color("6f4628"))
	draw_rect(Rect2(0, 134, W, 3), Color("a8733f"))
	draw_rect(Rect2(0, 146, W, 2), Color("3b2616"))


func _jar(x: float, w: float, h: float, content: Color) -> void:
	var base := 140.0
	Paint.box(self, Rect2(x, base - h, w, h), content, 6, content.darkened(0.5), 2)
	Paint.box(self, Rect2(x + 5, base - h + 9, 5, h - 18), Color(1, 1, 1, 0.3), 2)
	Paint.box(self, Rect2(x - 1, base - h - 7, w + 2, 9), Color("9aa2a8"), 3, Color("4b5258"), 1)
	Paint.box(self, Rect2(x + 6, base - h * 0.6, w - 12, h * 0.3), Color("f3e9cf"), 2)


func _counter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var tones := [Color("b9824f"), Color("c28b56"), Color("b07a48")]
	var top := COUNTER_Y + 12.0
	var x := 0.0
	var i := 0
	while x < W:
		draw_rect(Rect2(x, top, 160.0, H - top), tones[i % 3])
		draw_rect(Rect2(x, top, 3.0, H - top), Color(0.3, 0.17, 0.08, 0.85))
		for g in 7:
			var gx := x + rng.randf_range(8.0, 152.0)
			var gy := rng.randf_range(top + 8.0, H - 40.0)
			draw_line(Vector2(gx, gy), Vector2(gx + rng.randf_range(-3, 3), gy + rng.randf_range(60, 200)),
					Color(0.35, 0.2, 0.1, 0.15), 2.0)
		for g in 4:
			var gx := x + rng.randf_range(8.0, 152.0)
			var gy := rng.randf_range(top + 8.0, H - 40.0)
			draw_line(Vector2(gx, gy), Vector2(gx, gy + rng.randf_range(40, 120)),
					Color(1, 0.85, 0.6, 0.12), 2.0)
		if i % 2 == 0:
			var knot := Vector2(x + rng.randf_range(30, 130), rng.randf_range(top + 60, H - 80))
			draw_set_transform(knot, 0.0, Vector2(1.0, 1.9))
			draw_circle(Vector2.ZERO, 8.0, Color(0.33, 0.19, 0.09, 0.4))
			draw_circle(Vector2.ZERO, 4.5, Color(0.28, 0.15, 0.07, 0.5))
			draw_set_transform(Vector2.ZERO)
		x += 160.0
		i += 1
	# Lip at the front of the counter, then shade under the shelf and toward the bottom.
	draw_rect(Rect2(0, COUNTER_Y, W, 12), Color("d29a5f"))
	draw_rect(Rect2(0, COUNTER_Y, W, 3), Color("efc58a"))
	draw_rect(Rect2(0, COUNTER_Y + 9, W, 3), Color("6e4527"))
	Paint.vgrad(self, Rect2(0, top, W, 90), Color(0, 0, 0, 0.32), Color(0, 0, 0, 0))
	Paint.vgrad(self, Rect2(0, H - 150, W, 150), Color(0, 0, 0, 0), Color(0, 0, 0, 0.3))


## Soft lamp light pooled around the stove.
func _warm_light() -> void:
	for i in 7:
		Paint.ellipse(self, Vector2(stove_center.x, stove_center.y + 20.0),
				300.0 + i * 55.0, 210.0 + i * 38.0, Color(1.0, 0.82, 0.55, 0.028))


func _stove() -> void:
	var c := stove_center
	var plate := Rect2(c.x - 245.0, 205.0, 490.0, 497.0)
	Paint.box(self, plate, Color("2e3338"), 34, Color("6b747c"), 4, 20)
	Paint.vgrad(self, Rect2(plate.position.x + 22, plate.position.y + 4, plate.size.x - 44, 150),
			Color(1, 1, 1, 0.09), Color(1, 1, 1, 0))
	# Burner bowl and the grate fingers that reach toward the corners.
	var burner := c + Vector2(0, 80)
	Paint.ellipse(self, burner, 244.0, 192.0, Color("15171a"))
	Paint.ellipse_arc(self, burner, 244.0, 192.0, 0.0, TAU, Color("50585f"), 3.0)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var from := burner + Vector2(corner.x * 190.0, corner.y * 140.0)
		var to := burner + Vector2(corner.x * 235.0, corner.y * 205.0)
		draw_line(from, to, Color("0f1113"), 18.0, true)
		draw_line(from, to, Color("353b41"), 6.0, true)
	# Knob strip on the front edge.
	for k in 4:
		var p := Vector2(c.x - 105.0 + k * 70.0, 689.0)
		draw_circle(p, 11.0, Color("0f1113"))
		draw_circle(p, 8.0, Color("a1abb3"))
		draw_line(p, p + Vector2(0, -7), Color("2e3338"), 2.0)


## Every vegetable waits on a round white plate: a different shape and colour from the square gold
## frame that marks the next one to take.
func _crate(point: Vector2) -> void:
	_plate(point)


func _tray(point: Vector2) -> void:
	_plate(point)


func _plate(point: Vector2) -> void:
	Paint.ellipse(self, point + Vector2(5, 12), 74.0, 66.0, Color(0, 0, 0, 0.32))
	Paint.ellipse(self, point, 72.0, 66.0, Color("d9dde0"))
	Paint.ellipse(self, point, 69.0, 63.0, Color("fbfbfa"))
	Paint.ellipse(self, point, 52.0, 47.0, Color("eceeee"))
	Paint.ellipse(self, point, 49.0, 44.0, Color("fdfdfc"))
	Paint.ellipse_arc(self, point, 66.0, 60.0, PI * 1.05, PI * 1.6, Color(1, 1, 1, 0.9), 3.0)


func _basket(c: Vector2, r: float, items: Array) -> void:
	Paint.ellipse(self, c + Vector2(4, 12), r + 8.0, (r + 8.0) * 0.8, Color(0, 0, 0, 0.28))
	Paint.ellipse(self, c, r + 4.0, (r + 4.0) * 0.8, Color("3b2616"))
	Paint.ellipse(self, c, r, r * 0.8, Color("a8743c"))
	for k in 12:
		var a := TAU * k / 12.0
		draw_line(c + Vector2(cos(a) * r * 0.55, sin(a) * r * 0.44), c + Vector2(cos(a) * r, sin(a) * r * 0.8),
				Color(0.4, 0.24, 0.1, 0.5), 2.0)
	Paint.ellipse(self, c, r * 0.82, r * 0.82 * 0.8, Color("3f2a1a"))
	for item: Array in items:
		var tex := Sprites.veg(item[0])
		if tex != null:
			Sprites.draw_fit(self, tex, c + (item[1] as Vector2) + Vector2(0, -10), item[2])
	# Front lip of the basket, drawn over the produce.
	Paint.ellipse_arc(self, c, r - 1.0, (r - 1.0) * 0.8, 0.15, PI - 0.15, Color("a8743c"), 9.0)
	Paint.ellipse_arc(self, c, r + 3.0, (r + 3.0) * 0.8, 0.15, PI - 0.15, Color("3b2616"), 3.0)


## A prop picture standing on a surface.
func _stand(prop_name: String, base: Vector2, size: float) -> void:
	var tex := Sprites.prop(prop_name)
	if tex != null:
		Sprites.draw_standing(self, tex, base, size)


func _prop(prop_name: String, centre: Vector2, size: float) -> void:
	var tex := Sprites.prop(prop_name)
	if tex != null:
		Sprites.draw_fit(self, tex, centre, size)


func _veg(sprite_name: String, centre: Vector2, size: float) -> void:
	var tex := Sprites.veg(sprite_name)
	if tex != null:
		Sprites.draw_fit(self, tex, centre, size)


func _shadow(centre: Vector2, rx: float) -> void:
	Paint.ellipse(self, centre, rx, rx * 0.3, Color(0, 0, 0, 0.25))


func _left_produce() -> void:
	# Chopping station beside the stove.
	_shadow(Vector2(292, 372), 70.0)
	_prop("cutting-board", Vector2(290, 335), 128.0)
	_veg("carrot", Vector2(274, 330), 66.0)
	_prop("cooking-knife", Vector2(318, 350), 92.0)
	# Greens heaped in the bottom corner.
	_shadow(Vector2(250, 690), 80.0)
	_prop("cabbage", Vector2(258, 660), 108.0)
	_veg("celery", Vector2(346, 652), 124.0)
	_veg("zucchini", Vector2(360, 592), 88.0)


func _right_produce() -> void:
	_shadow(Vector2(992, 372), 66.0)
	_prop("knife-block", Vector2(990, 330), 112.0)
	_shadow(Vector2(985, 696), 86.0)
	_prop("corn", Vector2(944, 668), 96.0)
	_veg("pumpkin", Vector2(1024, 652), 118.0)
