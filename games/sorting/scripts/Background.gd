class_name GameBackground
extends Node2D
## Animated aurora + bokeh backdrop. Purely decorative and slow-moving (calm for patients).

const W := 1920.0
const H := 1080.0
var hue := 0.65  ## set per round by GameManager
var _t := 0.0
var _orbs: Array[Dictionary] = []


func _ready() -> void:
	z_index = -100
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 26:
		_orbs.append({
			"x": rng.randf() * W, "y": rng.randf() * H, "r": rng.randf_range(40.0, 150.0),
			"h": rng.randf_range(0.5, 0.9), "a": rng.randf_range(0.05, 0.12),
			"sp": rng.randf_range(0.1, 0.35), "ph": rng.randf() * TAU})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var top := Color.from_hsv(hue, 0.30, 0.30)
	var mid := Color.from_hsv(hue, 0.26, 0.40)
	var bot := Color.from_hsv(fposmod(hue + 0.06, 1.0), 0.22, 0.45)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H * 0.5), Vector2(0, H * 0.5)]),
		PackedColorArray([top, top, mid, mid]))
	draw_polygon(PackedVector2Array([Vector2(0, H * 0.5), Vector2(W, H * 0.5), Vector2(W, H), Vector2(0, H)]),
		PackedColorArray([mid, mid, bot, bot]))

	# aurora ribbons
	var steps := 40
	for b in 3:
		var base := H * (0.3 + 0.22 * b)
		var ys: Array[float] = []
		for i in steps + 1:
			var x := W * i / steps
			ys.append(base + sin(x * 0.003 + _t * 0.25 + b * 2.1) * 70.0 + sin(x * 0.007 - _t * 0.18 + b) * 30.0)
		for layer in 2:
			var thick := 90.0 + 70.0 * layer + 30.0 * b
			var pts := PackedVector2Array()
			for i in steps + 1:
				pts.append(Vector2(W * i / steps, ys[i]))
			for i in range(steps, -1, -1):
				pts.append(Vector2(W * i / steps, ys[i] + thick))
			draw_colored_polygon(pts, Color.from_hsv(fposmod(hue + 0.04 * b, 1.0), 0.2, 1.0, 0.03))

	# bokeh orbs
	for o in _orbs:
		var p := Vector2(
			o["x"] + sin(_t * o["sp"] + o["ph"]) * 45.0,
			o["y"] + cos(_t * o["sp"] * 0.8 + o["ph"]) * 35.0)
		var r: float = o["r"]
		for k in 4:
			draw_circle(p, r * (1.0 - k * 0.2), Color.from_hsv(o["h"], 0.15, 1.0, float(o["a"]) * 0.3))
