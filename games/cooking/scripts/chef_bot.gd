class_name ChefBot
extends Node2D
## A little hovering robot chef who keeps the patient company. It flies to the side of the
## kitchen nearest the action, points at what to pick up next, cheers each vegetable into
## the pot, pulls faces that follow the stirring and celebrates every soup.
## main.gd drives it; this script only animates and draws.

enum Face { CALM, HAPPY, LOVE, WORRIED, SURPRISED, DIZZY }

const LEFT_HOME := Vector2(290, 540)
const RIGHT_HOME := Vector2(990, 540)
const INK := Color("2a1d14")
const SHELL := Color("f3f0ea")
const METAL := Color("cfd8de")
const SCREEN := Color("1b2a35")
const LED := Color("62f2ff")
const SCARF := Color("e0473c")
const BUBBLE_SECONDS := 1.8
## The bot is drawn smaller so it stays out of the way of the plates and the pot.
const BOT_SCALE := 0.62

var face := Face.CALM

var _time := randf() * 10.0
var _home := LEFT_HOME
var _pointing := false
var _point_target := Vector2.ZERO
var _arm_dir := Vector2.DOWN
var _look := Vector2.ZERO
var _tilt := 0.0
var _hop := 0.0
var _cheer := 0.0
var _shake := 0.0
var _dance := 0.0
var _blink := 0.0
var _next_blink := 2.5
var _bubble := ""
var _bubble_left := 0.0
var _sparkles: Array = []


func _ready() -> void:
	z_index = 6
	position = _home


## Flies to the left or right side of the stove, whichever is nearer screen_x.
func go_near(screen_x: float) -> void:
	_home = LEFT_HOME if screen_x < 640.0 else RIGHT_HOME


func point_at(world_point: Vector2) -> void:
	_pointing = true
	_point_target = world_point


func stop_pointing() -> void:
	_pointing = false


func say(text: String) -> void:
	_bubble = text
	_bubble_left = BUBBLE_SECONDS


func is_speaking() -> bool:
	return _bubble_left > 0.0


func hop() -> void:
	_hop = 1.0


## A short happy jump with sparkles. big adds a spin dance.
func cheer(big := false) -> void:
	_cheer = 1.0
	_hop = 1.0
	if big:
		_dance = 1.6
	for i in (16 if big else 8):
		_sparkles.append({
			"pos": Vector2(0, -40),
			"vel": Vector2.from_angle(randf() * TAU) * randf_range(90.0, 220.0) + Vector2(0, -80),
			"life": randf_range(0.6, 1.1),
			"size": randf_range(5.0, 10.0),
		})


func wobble() -> void:
	_shake = 1.0


func _process(delta: float) -> void:
	_time += delta
	var before := position
	position = position.lerp(_home, 1.0 - exp(-delta * 3.0))
	var speed := (position.x - before.x) / maxf(delta, 0.0001)
	_tilt = lerpf(_tilt, clampf(speed / 900.0, -0.35, 0.35), 1.0 - exp(-delta * 8.0))
	_hop = maxf(_hop - delta * 2.2, 0.0)
	_cheer = maxf(_cheer - delta * 1.2, 0.0)
	_shake = maxf(_shake - delta * 2.0, 0.0)
	_dance = maxf(_dance - delta, 0.0)
	_bubble_left = maxf(_bubble_left - delta, 0.0)

	var wanted_arm := Vector2(0.35, 1.0).normalized()
	var wanted_look := Vector2.ZERO
	if _pointing:
		var to := _point_target - (global_position + Vector2(0, -10))
		wanted_arm = to.normalized()
		wanted_look = to.normalized() * 5.0
	_arm_dir = _arm_dir.slerp(wanted_arm, 1.0 - exp(-delta * 9.0)).normalized()
	_look = _look.lerp(wanted_look, 1.0 - exp(-delta * 8.0))

	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.14
		_next_blink = randf_range(2.0, 4.5)
	_blink = maxf(_blink - delta, 0.0)

	for s: Dictionary in _sparkles:
		s.life -= delta
		s.vel += Vector2(0, 260) * delta
		s.pos += s.vel * delta
	_sparkles = _sparkles.filter(func(s: Dictionary) -> bool: return s.life > 0.0)
	queue_redraw()


func _draw() -> void:
	var float_y := sin(_time * 2.4) * 6.0
	var jump := -sin(_hop * PI) * 34.0
	var lift := float_y + jump
	# Shadow on the counter, smaller when the bot is higher.
	var shadow := 1.0 - (-lift) * 0.008
	Paint.ellipse(self, Vector2(0, 104), 40.0 * shadow * BOT_SCALE, 9.0 * shadow * BOT_SCALE, Color(0, 0, 0, 0.25))

	var spin := sin(_dance * TAU * 1.5) * 0.35 if _dance > 0.0 else 0.0
	var shake := sin(_time * 50.0) * 0.12 * _shake
	draw_set_transform(Vector2(0, lift * BOT_SCALE + 104.0 * (1.0 - BOT_SCALE)), _tilt + spin + shake, Vector2.ONE * BOT_SCALE)
	_draw_thruster()
	_draw_arms(true)
	_draw_body()
	_draw_head()
	_draw_hat()
	_draw_arms(false)
	draw_set_transform(Vector2.ZERO)

	for s: Dictionary in _sparkles:
		var a: float = clampf(s.life * 1.5, 0.0, 1.0)
		Paint.star(self, s.pos + Vector2(0, lift), s.size, Color(1.0, 0.9, 0.35, a))
	if _bubble_left > 0.0:
		_draw_bubble(Vector2(0, -150 * BOT_SCALE + 104.0 * (1.0 - BOT_SCALE) - 20.0 + lift * BOT_SCALE))


func _draw_thruster() -> void:
	var flicker := 0.8 + 0.2 * sin(_time * 31.0)
	for i in 4:
		var r := (16.0 - i * 3.5) * flicker
		draw_circle(Vector2(0, 64 + i * 6), r, Color(0.4, 0.9, 1.0, 0.18 + i * 0.12))
	draw_circle(Vector2(0, 62), 8.0, Color("e8fdff"))


func _draw_body() -> void:
	Paint.ellipse(self, Vector2(0, 22), 47.0, 43.0, INK)
	Paint.ellipse(self, Vector2(0, 22), 44.0, 40.0, SHELL.darkened(0.12))
	Paint.ellipse(self, Vector2(-5, 17), 38.0, 34.0, SHELL)
	Paint.ellipse(self, Vector2(-18, 6), 9.0, 6.0, Color(1, 1, 1, 0.9))
	# Neckerchief.
	draw_colored_polygon(PackedVector2Array([Vector2(-26, -12), Vector2(26, -12), Vector2(0, 16)]),
			INK)
	draw_colored_polygon(PackedVector2Array([Vector2(-22, -10), Vector2(22, -10), Vector2(0, 11)]),
			SCARF)
	# A belly light that glows with the mood.
	var glow := _mood_color()
	draw_circle(Vector2(0, 34), 9.0, INK)
	draw_circle(Vector2(0, 34), 7.0, glow)
	draw_circle(Vector2(-2, 32), 2.5, Color(1, 1, 1, 0.8))


func _draw_head() -> void:
	Paint.box(self, Rect2(-44, -78, 88, 64), METAL, 20, INK, 3)
	Paint.box(self, Rect2(-36, -71, 72, 49), SCREEN, 14)
	draw_line(Vector2(-28, -66), Vector2(-12, -66), Color(1, 1, 1, 0.15), 3.0)
	# Ear bolts.
	for x: float in [-47.0, 47.0]:
		draw_circle(Vector2(x, -46), 7.0, INK)
		draw_circle(Vector2(x, -46), 5.0, METAL.darkened(0.2))
	_draw_face(Vector2(0, -47) + _look)


func _draw_face(c: Vector2) -> void:
	var left := c + Vector2(-14, -4)
	var right := c + Vector2(14, -4)
	match face:
		Face.HAPPY:
			for eye in [left, right]:
				draw_arc(eye + Vector2(0, 4), 8.0, PI * 1.1, PI * 1.9, 12, LED, 4.0, true)
			draw_arc(c + Vector2(0, 6), 9.0, PI * 0.15, PI * 0.85, 12, LED, 3.0, true)
			_blush(c)
		Face.LOVE:
			for eye in [left, right]:
				_heart(eye, 8.0, Color("ff6fa8"))
			draw_arc(c + Vector2(0, 5), 10.0, PI * 0.1, PI * 0.9, 12, LED, 3.0, true)
			_blush(c)
		Face.WORRIED:
			for eye in [left, right]:
				draw_circle(eye + Vector2(0, 2), 5.0, LED)
			draw_line(left + Vector2(-7, -8), left + Vector2(6, -11), LED, 3.0, true)
			draw_line(right + Vector2(7, -8), right + Vector2(-6, -11), LED, 3.0, true)
			draw_arc(c + Vector2(0, 16), 7.0, PI * 1.2, PI * 1.8, 10, LED, 3.0, true)
		Face.SURPRISED:
			for eye in [left, right]:
				draw_circle(eye, 8.0, LED)
				draw_circle(eye, 3.5, SCREEN)
			draw_circle(c + Vector2(0, 11), 4.5, LED)
		Face.DIZZY:
			for eye in [left, right]:
				var turn := _time * 6.0
				for k in 2:
					var a := turn + k * PI * 0.5
					var d := Vector2.from_angle(a) * 6.0
					draw_line(eye - d, eye + d, LED, 3.0, true)
			var wave := PackedVector2Array()
			for i in 9:
				wave.append(c + Vector2(-10 + i * 2.5, 11 + sin(i * 1.4 + _time * 8.0) * 2.0))
			draw_polyline(wave, LED, 2.5, true)
		_:
			for eye in [left, right]:
				if _blink > 0.0:
					draw_line(eye + Vector2(-6, 0), eye + Vector2(6, 0), LED, 3.0, true)
				else:
					Paint.box(self, Rect2(eye - Vector2(5, 7), Vector2(10, 14)), LED, 5)
			draw_arc(c + Vector2(0, 6), 6.0, PI * 0.2, PI * 0.8, 10, LED, 3.0, true)


func _blush(c: Vector2) -> void:
	draw_circle(c + Vector2(-25, 8), 5.0, Color(1.0, 0.45, 0.6, 0.55))
	draw_circle(c + Vector2(25, 8), 5.0, Color(1.0, 0.45, 0.6, 0.55))


func _heart(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(-r * 0.45, -r * 0.2), r * 0.55, col)
	draw_circle(c + Vector2(r * 0.45, -r * 0.2), r * 0.55, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.98, 0), c + Vector2(r * 0.98, 0),
			c + Vector2(0, r * 0.95)]), col)


func _draw_hat() -> void:
	var puffs := [Vector2(-22, -104), Vector2(22, -104), Vector2(0, -116)]
	var radii := [18.0, 18.0, 22.0]
	for i in puffs.size():
		draw_circle(puffs[i], radii[i] + 3.0, INK)
	Paint.box(self, Rect2(-33, -96, 66, 22), INK, 4)
	for i in puffs.size():
		draw_circle(puffs[i], radii[i], Color.WHITE)
	Paint.box(self, Rect2(-30, -93, 60, 17), Color("f7f5f0"), 3)
	draw_line(Vector2(-30, -80), Vector2(30, -80), Color(0, 0, 0, 0.12), 3.0)
	draw_circle(Vector2(-8, -122), 6.0, Color(1, 1, 1, 0.9))
	for x: float in [-16.0, 0.0, 16.0]:
		draw_line(Vector2(x, -92), Vector2(x, -82), Color(0, 0, 0, 0.1), 2.0)


## back draws the arm behind the body, otherwise the one in front.
func _draw_arms(back: bool) -> void:
	var cheering := _cheer > 0.0 or _dance > 0.0
	var point_side := 1.0 if _arm_dir.x >= 0.0 else -1.0
	for side: float in [-1.0, 1.0]:
		var in_front := side == point_side if _pointing else side > 0.0
		if in_front == back:
			continue
		var shoulder := Vector2(side * 44.0, 4)
		var dir: Vector2
		if cheering:
			dir = Vector2(side * 0.55, -1.0).rotated(sin(_time * 14.0 + side) * 0.35).normalized()
		elif _pointing and side == point_side:
			dir = _arm_dir
		else:
			dir = Vector2(side * 0.45, 1.0).rotated(sin(_time * 2.4 + side) * 0.12).normalized()
		var reach := 66.0 if _pointing and side == point_side and not cheering else 40.0
		var hand := shoulder + dir * reach
		var bend := shoulder.lerp(hand, 0.5) + dir.orthogonal() * side * -8.0
		var curve := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			curve.append(shoulder.lerp(bend, t).lerp(bend.lerp(hand, t), t))
		draw_polyline(curve, INK, 11.0, true)
		draw_polyline(curve, METAL.darkened(0.1), 7.0, true)
		if _pointing and side == point_side and not cheering:
			# A mitten with a pointing finger.
			draw_circle(hand, 10.0, INK)
			draw_circle(hand, 8.0, Color.WHITE)
			var tip := hand + dir * 14.0
			draw_line(hand, tip, INK, 8.0, true)
			draw_line(hand, tip, Color.WHITE, 5.0, true)
		else:
			draw_circle(hand, 10.0, INK)
			draw_circle(hand, 8.0, Color.WHITE)
			if side < 0.0 and not cheering:
				_draw_ladle(hand)


func _draw_ladle(hand: Vector2) -> void:
	var top := hand + Vector2(-6, -34)
	draw_line(hand + Vector2(1, 6), top, INK, 6.0, true)
	draw_line(hand + Vector2(1, 6), top, Color("b9855a"), 3.5, true)
	draw_circle(top + Vector2(-3, -6), 9.0, INK)
	draw_circle(top + Vector2(-3, -6), 7.0, Color("d9a86b"))


func _draw_bubble(at: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var size := 22
	var text_size := font.get_string_size(_bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var pop := clampf((BUBBLE_SECONDS - _bubble_left) * 8.0, 0.0, 1.0)
	var rect := Rect2(at - Vector2(text_size.x * 0.5 + 18, 22), Vector2(text_size.x + 36, 44))
	# Keep the bubble on screen.
	var global_left := global_position.x + rect.position.x
	var global_right := global_position.x + rect.end.x
	if global_left < 8.0:
		rect.position.x += 8.0 - global_left
	elif global_right > 1272.0:
		rect.position.x -= global_right - 1272.0
	draw_set_transform(at, 0.0, Vector2.ONE * (0.6 + 0.4 * pop))
	rect.position -= at
	draw_colored_polygon(PackedVector2Array([Vector2(-10, 18), Vector2(10, 18), Vector2(0, 36)]),
			Color("d9a441"))
	Paint.box(self, rect, Color("fff8e4"), 18, Color("d9a441"), 3, 6)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, 18), Vector2(7, 18), Vector2(0, 30)]),
			Color("fff8e4"))
	draw_string(font, rect.position + Vector2(18, 30), _bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
			Color("3a2414"))
	draw_set_transform(Vector2.ZERO)


func _mood_color() -> Color:
	match face:
		Face.HAPPY, Face.LOVE:
			return Color("6be38a")
		Face.WORRIED:
			return Color("ffb347")
		Face.DIZZY, Face.SURPRISED:
			return Color("ff6b6b")
	return Color("62f2ff")
