class_name FreshBackground
extends Node2D
## Calm, fresh scenery behind the game: soft sky, warm sun glow, slowly drifting clouds,
## layered pastel hills with little trees and flowers, gently rising light specks, a few birds.
## Everything is soft, low-contrast and slow so it refreshes without distracting.

const SCREEN := Vector2(1920, 1080)

@export var animated := true

var _t := 0.0
var _clouds: Array = []        # [pos: Vector2, scale: float, speed: float]
var _birds: Array = []         # [pos: Vector2, speed: float, phase: float]
var _hills: Array = []         # [polygon, color, edge polyline]
var _trees: Array = []         # [base: Vector2, size: float]
var _flowers: Array = []       # [pos, radius, color]
var _clouds_layer: Node2D
var _scenery_layer: Node2D


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7                       # same pleasant layout every time

	# sky gradient: fresh aqua -> mint -> warm cream
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("a8dcf2"), Color("d4f0ec"), Color("fbf3e2")])
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var sky_tex := GradientTexture2D.new()
	sky_tex.gradient = g
	sky_tex.width = 8
	sky_tex.height = 256
	sky_tex.fill_to = Vector2(0, 1)
	var sky := TextureRect.new()
	sky.texture = sky_tex
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.size = SCREEN
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)

	# warm sun glow (top right, behind the palette)
	var glow_g := Gradient.new()
	glow_g.colors = PackedColorArray([Color(1.0, 0.95, 0.7, 0.85), Color(1.0, 0.93, 0.65, 0.35), Color(1, 0.93, 0.65, 0.0)])
	glow_g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	var glow_tex := GradientTexture2D.new()
	glow_tex.gradient = glow_g
	glow_tex.fill = GradientTexture2D.FILL_RADIAL
	glow_tex.fill_from = Vector2(0.5, 0.5)
	glow_tex.fill_to = Vector2(1.0, 0.5)
	glow_tex.width = 256
	glow_tex.height = 256
	var glow := Sprite2D.new()
	glow.texture = glow_tex
	glow.position = Vector2(1560, 110)
	glow.scale = Vector2.ONE * 3.4
	add_child(glow)

	_clouds_layer = Node2D.new()
	_clouds_layer.draw.connect(_draw_clouds)
	add_child(_clouds_layer)
	for i in 6:
		_clouds.append([Vector2(rng.randf_range(0, SCREEN.x), rng.randf_range(50, 330)),
			rng.randf_range(0.7, 1.35), rng.randf_range(6.0, 14.0)])
	for i in 2:
		_birds.append([Vector2(rng.randf_range(0, SCREEN.x), rng.randf_range(90, 260)),
			rng.randf_range(28.0, 40.0), rng.randf() * TAU])

	# hills: back -> front, each a soft wave
	var specs := [
		[790.0, 38.0, 0.0030, 0.4, Color("cdebd0")],
		[870.0, 30.0, 0.0042, 2.1, Color("b6e2b3")],
		[950.0, 24.0, 0.0055, 4.0, Color("9fd69a")],
	]
	for sp in specs:
		var poly := PackedVector2Array()
		for x in range(0, int(SCREEN.x) + 21, 20):
			poly.append(Vector2(x, _hill_y(x, sp)))
		var edge := poly.duplicate()
		poly.append(Vector2(SCREEN.x, SCREEN.y))
		poly.append(Vector2(0, SCREEN.y))
		_hills.append([poly, sp[4], edge])
	# little trees on the middle hill, flowers on the front hill
	for x in [70.0, 250.0, 1640.0, 1830.0, 1900.0]:
		_trees.append([Vector2(x, _hill_y(x, specs[1]) + 6), rng.randf_range(0.8, 1.2)])
	var flower_cols := [Color("ffd7e0"), Color("fff3b0"), Color(1, 1, 1), Color("ffd2b0")]
	for i in 34:
		var x := rng.randf_range(0, SCREEN.x)
		var y := _hill_y(x, specs[2]) + rng.randf_range(14, 110)
		_flowers.append([Vector2(x, y), rng.randf_range(4.0, 7.0), flower_cols.pick_random()])

	_scenery_layer = Node2D.new()
	_scenery_layer.draw.connect(_draw_scenery)
	add_child(_scenery_layer)

	# gently rising light specks
	var specks := CPUParticles2D.new()
	specks.texture = Shapes.circle(64, 0.0)
	specks.amount = 26
	specks.lifetime = 16.0
	specks.preprocess = 16.0
	specks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	specks.emission_rect_extents = Vector2(SCREEN.x * 0.5, 40)
	specks.position = Vector2(SCREEN.x * 0.5, SCREEN.y + 20)
	specks.direction = Vector2.UP
	specks.spread = 12.0
	specks.gravity = Vector2.ZERO
	specks.initial_velocity_min = 35.0
	specks.initial_velocity_max = 70.0
	specks.scale_amount_min = 0.12
	specks.scale_amount_max = 0.3
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	fade.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	specks.color_ramp = fade
	specks.emitting = animated
	add_child(specks)


static func _hill_y(x: float, sp: Array) -> float:
	return sp[0] + sp[1] * sin(x * sp[2] + sp[3]) + sp[1] * 0.45 * sin(x * sp[2] * 2.3 + sp[3] * 1.7)


func _process(delta: float) -> void:
	if not animated:
		return
	_t += delta
	for c in _clouds:
		c[0].x += c[2] * delta
		if c[0].x > SCREEN.x + 220:
			c[0].x = -220.0
	for b in _birds:
		b[0].x += b[1] * delta
		b[0].y += sin(_t * 0.6 + b[2]) * 6.0 * delta
		if b[0].x > SCREEN.x + 60:
			b[0].x = -60.0
	_clouds_layer.queue_redraw()


func _draw_clouds() -> void:
	for c in _clouds:
		var p: Vector2 = c[0]
		var s: float = c[1]
		var puffs := [[-70, 8, 42], [-28, -16, 56], [30, -10, 50], [74, 10, 38], [0, 14, 48]]
		for pf in puffs:   # soft shadow underneath
			_clouds_layer.draw_circle(p + Vector2(pf[0], pf[1] + 8) * s, pf[2] * s, Color(0.55, 0.7, 0.8, 0.12))
		for pf in puffs:
			_clouds_layer.draw_circle(p + Vector2(pf[0], pf[1]) * s, pf[2] * s, Color(1, 1, 1, 0.9))
	for b in _birds:
		var flap := sin(_t * 5.0 + b[2]) * 7.0
		var p2: Vector2 = b[0]
		_clouds_layer.draw_polyline(PackedVector2Array([p2 + Vector2(-16, -flap), p2, p2 + Vector2(16, -flap)]),
			Color(0.3, 0.38, 0.45, 0.55), 3.0, true)


func _draw_scenery() -> void:
	for i in _hills.size():
		var h: Array = _hills[i]
		_scenery_layer.draw_colored_polygon(h[0], h[1])
		_scenery_layer.draw_polyline(h[2], h[1].lightened(0.25), 3.0, true)
		if i == 1:
			for tr in _trees:
				var base: Vector2 = tr[0]
				var s: float = tr[1]
				_scenery_layer.draw_rect(Rect2(base + Vector2(-5, -38) * s, Vector2(10, 40) * s), Color("c9a585"))
				_scenery_layer.draw_circle(base + Vector2(0, -52) * s, 26 * s, Color("8fcf8a"))
				_scenery_layer.draw_circle(base + Vector2(-10, -60) * s, 9 * s, Color(1, 1, 1, 0.18))
	for f in _flowers:
		_scenery_layer.draw_circle(f[0], f[1], f[2])
		_scenery_layer.draw_circle(f[0], f[1] * 0.4, Color("ffcf4a"))
