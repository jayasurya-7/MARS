class_name StickerShelf
extends Node2D
## A row of collected star stickers along the bottom edge. One is earned per finished
## game and saved to disk, so progress carries over between sessions.

const SAVE_PATH := "user://sorting_progress.cfg"
const MAX_SHOWN := 24
const COLORS := [
	Color(0.86, 0.55, 0.47), Color(0.5, 0.65, 0.84), Color(0.5, 0.74, 0.62),
	Color(0.87, 0.73, 0.48), Color(0.84, 0.58, 0.67), Color(0.64, 0.59, 0.82)]

var stickers := 0
var _pop := 1.0
var _t := 0.0


func _ready() -> void:
	z_index = 20
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		stickers = int(cfg.get_value("progress", "stickers", 0))


func add_sticker() -> void:
	stickers += 1
	_pop = 0.0
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)  # keep any other saved values
	cfg.set_value("progress", "stickers", stickers)
	cfg.save(SAVE_PATH)
	var shown := mini(stickers, MAX_SHOWN)
	SortFx.burst(get_parent(), to_global(_slot(shown - 1, shown)), Color(0.95, 0.88, 0.65), 20)


func _process(delta: float) -> void:
	_t += delta
	_pop = minf(1.0, _pop + delta * 1.5)
	queue_redraw()


func _slot(i: int, shown: int) -> Vector2:
	return Vector2((i - (shown - 1) * 0.5) * 50.0, 0.0)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	if stickers == 0:
		draw_string(font, Vector2(-300, 10), "Finish a game to earn a sticker", HORIZONTAL_ALIGNMENT_CENTER, 600, 26,
			Color(1, 1, 1, 0.5))
		return
	var shown := mini(stickers, MAX_SHOWN)
	for i in shown:
		var s := 1.0
		if i == shown - 1 and _pop < 1.0:
			s = sin(_pop * PI * 0.5) * (1.0 + 0.5 * sin(_pop * PI))  # pop in with a little overshoot
		var c: Color = COLORS[(stickers - shown + i) % COLORS.size()]
		_sticker(_slot(i, shown), s, c, sin(_t * 1.5 + i) * 0.12)
	if stickers > MAX_SHOWN:
		draw_string(font, _slot(0, shown) + Vector2(-110, 10), "x%d" % stickers, HORIZONTAL_ALIGNMENT_RIGHT, 80, 28,
			Color(1, 1, 1, 0.8))


func _sticker(p: Vector2, s: float, c: Color, rot: float) -> void:
	if s <= 0.01:
		return
	draw_circle(p, 22.0 * s, Color(1.0, 0.97, 0.9, 0.95))
	draw_arc(p, 22.0 * s, 0.0, TAU, 32, c.darkened(0.25), 3.0, true)
	var pts := PackedVector2Array()
	for k in 10:
		var r := (15.0 if k % 2 == 0 else 6.5) * s
		var ang := rot - PI / 2.0 + k * PI / 5.0
		pts.append(p + Vector2(cos(ang), sin(ang)) * r)
	draw_colored_polygon(pts, c)
