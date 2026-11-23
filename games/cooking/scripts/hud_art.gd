class_name HudArt
extends Control
## The painted HUD furniture: vignette, timer panel, sign, score panel with stars and the
## accuracy dial. The text on top of it is ordinary Labels, laid out in hud.tscn.

const W := 1280.0
const H := 720.0
const DIAL_CENTER := Vector2(1198, 88)

## Accuracy shown by the dial, in percent (0 to 100).
var value := 0.0
## Stars earned, 0 to 3.
var stars := 0:
	set(new_value):
		stars = new_value
		queue_redraw()

var ticket_points := PackedVector2Array()
var ticket_name := ""

var _shown := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	var before := _shown
	_shown = lerpf(_shown, value, 1.0 - exp(-delta * 8.0))
	if absf(_shown - before) > 0.005:
		queue_redraw()


func _draw() -> void:
	_vignette()
	_ticket()
	_sign()


## Pins the order ticket: the path to follow, drawn small, and its name.
func set_order(points: PackedVector2Array, pattern_name: String) -> void:
	ticket_points = points
	ticket_name = pattern_name
	queue_redraw()


func _ticket() -> void:
	if ticket_name == "" or ticket_points.is_empty():
		return
	var rect := Rect2(16, 104, 124, 44)
	Paint.box(self, rect, Color("f4e6c0"), 6, Color("8a6a3a"), 2, 6)
	draw_circle(rect.position + Vector2(rect.size.x * 0.5, 3), 4.0, Color("c0392b"))
	var centre := rect.position + Vector2(32, 26)
	var loop := PackedVector2Array()
	for point in ticket_points:
		loop.append(centre + point * 0.1)
	loop.append(loop[0])
	draw_polyline(loop, Color("a33a2a"), 2.5, true)
	draw_circle(loop[0], 3.2, Color("2e7d32"))
	var font := ThemeDB.fallback_font
	draw_string(font, rect.position + Vector2(60, 19), "ORDER", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("8a6a3a"))
	var words := ticket_name.to_upper().split(" ")
	for i in words.size():
		draw_string(font, rect.position + Vector2(60, 31 + i * 11), words[i],
				HORIZONTAL_ALIGNMENT_LEFT, 62, 11, Color("3a2414"))


func _vignette() -> void:
	var dark := Color(0, 0, 0, 0.4)
	var clear := Color(0, 0, 0, 0)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(190, 0), Vector2(190, H), Vector2(0, H)]),
			PackedColorArray([dark, clear, clear, dark]))
	draw_polygon(PackedVector2Array([Vector2(W, 0), Vector2(W - 190, 0), Vector2(W - 190, H), Vector2(W, H)]),
			PackedColorArray([dark, clear, clear, dark]))
	draw_polygon(PackedVector2Array([Vector2(0, H), Vector2(W, H), Vector2(W, H - 120), Vector2(0, H - 120)]),
			PackedColorArray([dark, dark, clear, clear]))


## A steel-framed wooden board.
func _board(rect: Rect2, radius: int) -> void:
	Paint.box(self, rect, Color("59636c"), radius + 4, Color("2c3338"), 4, 10)
	Paint.box(self, rect.grow(-7), Color("a46d40"), radius, Color("5e3a1f"), 3)
	for i in int(rect.size.y / 16.0):
		var y := rect.position.y + 16.0 + i * 15.0
		draw_line(Vector2(rect.position.x + 14, y), Vector2(rect.end.x - 14, y),
				Color(0.35, 0.2, 0.1, 0.16), 2.0)
	for corner: Vector2 in [Vector2(11, 11), Vector2(rect.size.x - 11, 11),
			Vector2(11, rect.size.y - 11), Vector2(rect.size.x - 11, rect.size.y - 11)]:
		draw_circle(rect.position + corner, 5.0, Color("aab4bc"))
		draw_circle(rect.position + corner + Vector2(-1.5, -1.5), 2.0, Color.WHITE)


func _timer_panel() -> void:
	var rect := Rect2(16, 10, 124, 88)
	_board(rect, 10)
	_caption("TIME", Vector2(rect.position.x, 32), rect.size.x)


func _sign() -> void:
	var rect := Rect2(390, 8, 500, 94)
	_board(rect, 12)


func _score_panel() -> void:
	var rect := Rect2(905, 14, 170, 88)
	for x: float in [925.0, 1055.0]:
		draw_line(Vector2(x, 0), Vector2(x, 20), Color("2c3338"), 6.0)
		draw_line(Vector2(x, 0), Vector2(x, 20), Color("8c97a0"), 3.0)
	_board(rect, 10)
	_caption("MONEY", Vector2(rect.position.x, 34), rect.size.x)
	for i in 3:
		var c := Vector2(rect.position.x + rect.size.x * 0.5 + (i - 1) * 36.0, 86.0)
		Paint.star(self, c, 13.0, Color("ffcf3d") if i < stars else Color("4a382a"))


func _caption(text: String, at: Vector2, width: float) -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, at + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, width, 13, Color(0, 0, 0, 0.6))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_CENTER, width, 13, Color("f3dcab"))


func _dial() -> void:
	var c := DIAL_CENTER
	draw_circle(c + Vector2(3, 6), 68.0, Color(0, 0, 0, 0.35))
	draw_circle(c, 67.0, Color("2c1c10"))
	draw_circle(c, 65.0, Color("8a5a33"))
	draw_circle(c, 58.0, Color("aeb7bf"))
	draw_circle(c, 54.0, Color("232019"))
	draw_arc(c, 62.0, PI * 1.05, PI * 1.55, 14, Color(1, 1, 1, 0.35), 4.0, true)
	var start := PI * 0.75
	var sweep := PI * 1.5
	var fraction := clampf(_shown / 100.0, 0.0, 1.0)
	var n := 45
	for i in n:
		var f := float(i) / n
		var color := Color.from_hsv(f * 0.36, 0.85, 1.0, 1.0 if f < fraction else 0.22)
		draw_arc(c, 39.0, start + sweep * f, start + sweep * (f + 1.2 / n), 3, color, 10.0)
	for i in 11:
		var a := start + sweep * i / 10.0
		draw_line(c + Vector2.from_angle(a) * 47.0, c + Vector2.from_angle(a) * 51.0,
				Color(1, 1, 1, 0.5), 2.0, true)
	var angle := start + sweep * fraction
	var tip := c + Vector2.from_angle(angle) * 34.0
	draw_line(c, tip, Color(0, 0, 0, 0.6), 7.0, true)
	draw_line(c, tip, Color("f4f1ea"), 3.5, true)
	draw_circle(c, 8.0, Color("3b2616"))
	draw_circle(c, 6.0, Color("d9a441"))
	draw_arc(c, 46.0, PI * 1.1, PI * 1.4, 10, Color(1, 1, 1, 0.1), 10.0, true)
