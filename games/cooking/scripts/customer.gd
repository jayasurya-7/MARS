class_name Customer
extends Node2D
## The customer at the serving window. Drawn in code, with a different face each time:
## skin, hair, clothes and accessories vary. Their expression follows how the stirring is
## going, and they taste the soup and react when it is done.

signal tasted(mood: int)

const WIDTH := 236.0
const HEIGHT := 124.0
const SKIN := [Color("f2c6a0"), Color("e0a97c"), Color("c68642"), Color("8d5524"), Color("f6d5b8")]
const HAIR := [Color("2b1b12"), Color("5a3825"), Color("a86a2c"), Color("d9b44a"), Color("8a8a8a"), Color("b8402a")]
const SHIRTS := [Color("4f8fd0"), Color("d95f4f"), Color("5fae6a"), Color("9a6bc4"), Color("e0a23c"), Color("4aa6a0")]
const INK := Color("3a2414")
## The figure is drawn this much larger than its design size, so the face fills the window.
const FIGURE_SCALE := 1.2
## Seconds an expression must be wanted before the face changes, so it does not flicker.
const MOOD_DELAY := 0.35

enum Hair { SHORT, LONG, BUN, BALD }
enum Extra { NONE, GLASSES, HAT }

var mood := CustomerFeedback.Mood.NEUTRAL

var _skin := SKIN[0]
var _hair_color := HAIR[0]
var _shirt := SHIRTS[0]
var _hair := Hair.SHORT
var _extra := Extra.NONE

var _time := 0.0
var _wanted_mood := CustomerFeedback.Mood.NEUTRAL
var _wanted_since := 0.0
var _blink := 0.0
var _next_blink := 2.0
var _look := Vector2.ZERO
var _look_target := Vector2.ZERO
var _hidden := 1.0
var _pop := 0.0
var _chew_left := 0.0
var _after_chew := -1
var _hearts: Array = []
var _heart_timer := 0.0

var _window := Node2D.new()
var _figure := Node2D.new()
var _frame := Node2D.new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_window.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(_window)
	_window.add_child(_figure)
	add_child(_frame)
	_window.draw.connect(_draw_window)
	_figure.draw.connect(_draw_figure)
	_frame.draw.connect(_draw_frame)
	new_customer()


## A fresh person walks up. `seed_value` makes the face repeatable for tests.
func new_customer(seed_value: int = -1) -> void:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	_skin = SKIN[rng.randi() % SKIN.size()]
	_hair_color = HAIR[rng.randi() % HAIR.size()]
	_shirt = SHIRTS[rng.randi() % SHIRTS.size()]
	_hair = (rng.randi() % 4) as Hair
	_extra = [Extra.NONE, Extra.GLASSES, Extra.HAT, Extra.NONE][rng.randi() % 4] as Extra
	if _hair == Hair.BUN and _extra == Extra.HAT:
		_extra = Extra.NONE
	_chew_left = 0.0
	_after_chew = -1
	_hearts.clear()
	force_mood(CustomerFeedback.Mood.NEUTRAL)
	_hidden = 1.0
	create_tween().tween_property(self, "_hidden", 0.0, 0.5) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Asks for an expression; it changes only if still wanted a moment later.
func set_mood(wanted: int) -> void:
	if wanted != _wanted_mood:
		_wanted_mood = wanted
		_wanted_since = _time


## Changes the face at once, with a little bounce.
func force_mood(new_mood: int) -> void:
	mood = new_mood
	_wanted_mood = new_mood
	_wanted_since = _time
	_pop = 1.0


func taste(final_mood: int) -> void:
	_chew_left = 1.3
	_after_chew = final_mood


func is_tasting() -> bool:
	return _chew_left > 0.0


func look_toward(world_point: Vector2) -> void:
	var offset := (world_point - global_position) / 220.0
	_look_target = offset.limit_length(1.0) * 2.8


func _process(delta: float) -> void:
	_time += delta
	_pop = maxf(_pop - delta * 2.5, 0.0)
	_look = _look.lerp(_look_target, 1.0 - exp(-delta * 8.0))
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.14
		_next_blink = randf_range(2.5, 5.0)
	_blink = maxf(_blink - delta, 0.0)
	if _chew_left > 0.0:
		_chew_left -= delta
		if _chew_left <= 0.0 and _after_chew >= 0:
			force_mood(_after_chew)
			if mood == CustomerFeedback.Mood.DELIGHTED:
				_heart_timer = 1.6
			_after_chew = -1
			tasted.emit(mood)
	elif _wanted_mood != mood and _time - _wanted_since >= MOOD_DELAY:
		force_mood(_wanted_mood)
	_update_hearts(delta)
	_window.queue_redraw()
	_figure.queue_redraw()


func _update_hearts(delta: float) -> void:
	if _heart_timer > 0.0:
		_heart_timer -= delta
		if randf() < delta * 7.0:
			_hearts.append([randf_range(-46.0, 46.0), 30.0, 0.0])
	for heart: Array in _hearts:
		heart[1] -= delta * 46.0
		heart[2] += delta
	_hearts = _hearts.filter(func(h: Array) -> bool: return h[2] < 1.6)


# ---------------------------------------------------------------- drawing

func _draw_window() -> void:
	var rect := Rect2(-WIDTH * 0.5, -HEIGHT * 0.5, WIDTH, HEIGHT)
	Paint.vgrad(_window, rect, Color("f7e6bd"), Color("e7c48a"))
	_window.draw_circle(Vector2(-84, -26), 30.0, Color(1, 1, 1, 0.16))
	_window.draw_circle(Vector2(88, -10), 22.0, Color(1, 1, 1, 0.12))


func _draw_frame() -> void:
	var half := Vector2(WIDTH, HEIGHT) * 0.5
	var wood := Color("8a5a34")
	var edge := Color("3b2616")
	Paint.box(_frame, Rect2(-half.x - 9, -half.y - 9, WIDTH + 18, 14), wood, 6, edge, 3, 8)
	Paint.box(_frame, Rect2(-half.x - 9, half.y - 5, WIDTH + 18, 14), wood, 6, edge, 3)
	Paint.box(_frame, Rect2(-half.x - 9, -half.y - 9, 14, HEIGHT + 18), wood, 6, edge, 3)
	Paint.box(_frame, Rect2(half.x - 5, -half.y - 9, 14, HEIGHT + 18), wood, 6, edge, 3)
	for corner: Vector2 in [Vector2(-half.x - 2, -half.y - 2), Vector2(half.x + 2, -half.y - 2),
			Vector2(-half.x - 2, half.y + 2), Vector2(half.x + 2, half.y + 2)]:
		_frame.draw_circle(corner, 4.0, Color("aab4bc"))


func _draw_figure() -> void:
	var f := _figure
	var sink := _hidden * 150.0
	var bob := sin(_time * 1.8) * 1.5
	var squash := 0.05 * sin(_pop * PI * 3.0) * _pop
	var tilt := 0.05 * sin(_time * 0.9) + 0.08 * _pop * sin(_pop * 9.0)
	f.draw_set_transform(Vector2(0, 4 + sink + bob), tilt,
			Vector2(1.0 + squash, 1.0 - squash) * FIGURE_SCALE)

	if _hair == Hair.LONG:
		Paint.box(f, Rect2(-40, -12, 80, 56), _hair_color, 16, _hair_color.darkened(0.5), 3)
	# Shoulders, collar and neck.
	Paint.box(f, Rect2(-56, 34, 112, 100), _shirt, 32, _shirt.darkened(0.5), 3)
	f.draw_colored_polygon(PackedVector2Array([Vector2(-13, 34), Vector2(0, 54), Vector2(13, 34)]),
			_skin.darkened(0.08))
	Paint.box(f, Rect2(-9, 18, 18, 22), _skin.darkened(0.1), 4)
	# Head and ears.
	for side: float in [-1.0, 1.0]:
		f.draw_circle(Vector2(side * 31.0, 4.0), 7.5, _skin.darkened(0.55))
		f.draw_circle(Vector2(side * 31.0, 4.0), 5.5, _skin)
	Paint.ellipse(f, Vector2.ZERO, 34.0, 37.0, _skin.darkened(0.55))
	Paint.ellipse(f, Vector2.ZERO, 31.0, 34.0, _skin)
	Paint.ellipse(f, Vector2(-8, -10), 14.0, 12.0, _skin.lightened(0.08))
	_draw_hair()
	_draw_face()
	_draw_extra()
	f.draw_set_transform(Vector2.ZERO)

	if _chew_left > 0.0 or _after_chew >= 0:
		var bowl := Sprites.prop("bowl-soup")
		if bowl != null:
			Sprites.draw_standing(f, bowl, Vector2(0, 88 + sin(_time * 6.0) * 2.0), 74.0)
	for heart: Array in _hearts:
		_draw_heart(Vector2(heart[0], heart[1]), 9.0, Color(1, 0.35, 0.45, 1.0 - heart[2] / 1.6))


func _draw_hair() -> void:
	if _hair == Hair.BALD:
		return
	var f := _figure
	var points := PackedVector2Array()
	for i in 17:
		var angle := PI + PI * i / 16.0
		points.append(Vector2(cos(angle) * 35.0, sin(angle) * 39.0 - 2.0))
	for fringe: Vector2 in [Vector2(31, -12), Vector2(17, -21), Vector2(3, -12), Vector2(-12, -22), Vector2(-31, -12)]:
		points.append(fringe)
	f.draw_colored_polygon(points, _hair_color)
	var outline := points.duplicate()
	outline.append(points[0])
	f.draw_polyline(outline, _hair_color.darkened(0.5), 3.0, true)
	f.draw_arc(Vector2(-6, -22), 20.0, PI * 1.15, PI * 1.55, 10, _hair_color.lightened(0.3), 3.0, true)
	if _hair == Hair.BUN:
		f.draw_circle(Vector2(0, -44), 14.0, _hair_color.darkened(0.5))
		f.draw_circle(Vector2(0, -44), 11.5, _hair_color)


func _draw_face() -> void:
	var f := _figure
	var blinking := _blink > 0.0 or _chew_left > 0.0
	for side: float in [-1.0, 1.0]:
		var centre := Vector2(side * 13.0, -1.0)
		if blinking and _chew_left <= 0.0:
			f.draw_line(centre + Vector2(-6, 1), centre + Vector2(6, 1), INK, 3.0, true)
		elif _chew_left > 0.0:
			f.draw_arc(centre + Vector2(0, 2), 6.0, PI * 1.15, PI * 1.85, 8, INK, 3.0, true)
		else:
			Paint.ellipse(f, centre, 8.5, 9.5, INK)
			Paint.ellipse(f, centre, 7.0, 8.0, Color.WHITE)
			f.draw_circle(centre + _look, 4.2, INK)
			f.draw_circle(centre + _look + Vector2(-1.3, -1.5), 1.4, Color.WHITE)
	_draw_brows()
	if mood == CustomerFeedback.Mood.HAPPY or mood == CustomerFeedback.Mood.DELIGHTED:
		for side: float in [-1.0, 1.0]:
			Paint.ellipse(f, Vector2(side * 22.0, 11.0), 7.0, 4.5, Color(1, 0.45, 0.45, 0.4))
	f.draw_circle(Vector2(0, 8), 2.4, _skin.darkened(0.2))
	if _hair == Hair.BALD:
		f.draw_colored_polygon(PackedVector2Array([Vector2(0, 10), Vector2(16, 6), Vector2(14, 13),
				Vector2(0, 12), Vector2(-14, 13), Vector2(-16, 6)]), _hair_color)
	_draw_mouth()
	match mood:
		CustomerFeedback.Mood.WORRIED:
			var drop := Vector2(40, -14 + sin(_time * 3.0) * 2.0)
			f.draw_colored_polygon(PackedVector2Array([drop + Vector2(0, -8), drop + Vector2(5, 2),
					drop + Vector2(0, 7), drop + Vector2(-5, 2)]), Color("8fd3ff"))
		CustomerFeedback.Mood.CONFUSED:
			f.draw_string(ThemeDB.fallback_font, Vector2(34, -18 + sin(_time * 3.0) * 2.0), "?",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 30, INK)


func _draw_brows() -> void:
	var f := _figure
	for side: float in [-1.0, 1.0]:
		var outer := Vector2(side * 21.0, -15.0)
		var inner := Vector2(side * 6.0, -15.0)
		match mood:
			CustomerFeedback.Mood.HAPPY, CustomerFeedback.Mood.DELIGHTED:
				outer.y -= 3.0
				inner.y -= 5.0
			CustomerFeedback.Mood.WORRIED:
				inner.y -= 6.0
				outer.y += 1.0
			CustomerFeedback.Mood.SAD:
				inner.y -= 8.0
				outer.y += 3.0
			CustomerFeedback.Mood.CONFUSED:
				if side > 0.0:
					outer.y -= 5.0
					inner.y -= 8.0
				else:
					outer.y += 1.0
					inner.y += 1.0
		f.draw_line(outer, inner, _hair_color.darkened(0.3) if _hair != Hair.BALD else INK, 3.5, true)


func _draw_mouth() -> void:
	var f := _figure
	var centre := Vector2(0, 19)
	if _chew_left > 0.0:
		var open := 2.0 + absf(sin(_time * 11.0)) * 5.0
		Paint.ellipse(f, centre, 7.0, open, Color("7a2230"))
		return
	match mood:
		CustomerFeedback.Mood.DELIGHTED:
			var mouth := PackedVector2Array()
			for i in 13:
				var angle := PI * i / 12.0
				mouth.append(centre + Vector2(cos(angle) * 13.0, sin(angle) * 11.0 - 3.0))
			f.draw_colored_polygon(mouth, Color("7a2230"))
			f.draw_line(centre + Vector2(-12, -3), centre + Vector2(12, -3), Color.WHITE, 4.0)
			Paint.ellipse(f, centre + Vector2(0, 5), 6.0, 3.5, Color("e8707a"))
		CustomerFeedback.Mood.HAPPY:
			f.draw_arc(centre + Vector2(0, -4), 11.0, 0.3, PI - 0.3, 12, INK, 3.5, true)
		CustomerFeedback.Mood.WORRIED:
			f.draw_arc(centre + Vector2(0, 6), 8.0, PI + 0.5, TAU - 0.5, 10, INK, 3.5, true)
		CustomerFeedback.Mood.SAD:
			f.draw_arc(centre + Vector2(0, 9), 11.0, PI + 0.4, TAU - 0.4, 12, INK, 3.5, true)
		CustomerFeedback.Mood.CONFUSED:
			var wave := PackedVector2Array()
			for i in 9:
				wave.append(centre + Vector2(-10.0 + i * 2.5, sin(i * 1.4) * 2.5))
			f.draw_polyline(wave, INK, 3.0, true)
		_:
			f.draw_line(centre + Vector2(-7, 0), centre + Vector2(7, 0), INK, 3.5, true)


func _draw_extra() -> void:
	var f := _figure
	match _extra:
		Extra.GLASSES:
			for side: float in [-1.0, 1.0]:
				f.draw_arc(Vector2(side * 13.0, -1.0), 12.0, 0.0, TAU, 20, INK, 3.0, true)
				f.draw_circle(Vector2(side * 13.0, -1.0), 11.0, Color(0.7, 0.9, 1.0, 0.16))
			f.draw_line(Vector2(-2, -3), Vector2(2, -3), INK, 3.0)
		Extra.HAT:
			var cap := PackedVector2Array()
			for i in 17:
				var angle := PI + PI * i / 16.0
				cap.append(Vector2(cos(angle) * 36.0, sin(angle) * 33.0 - 12.0))
			var hat := _shirt.lightened(0.15)
			f.draw_colored_polygon(cap, hat)
			var outline := cap.duplicate()
			outline.append(cap[0])
			f.draw_polyline(outline, hat.darkened(0.5), 3.0, true)
			Paint.box(f, Rect2(-40, -17, 80, 9), hat.darkened(0.15), 4, hat.darkened(0.55), 2)
			f.draw_circle(Vector2(0, -45), 6.0, hat.lightened(0.3))


func _draw_heart(at: Vector2, size: float, color: Color) -> void:
	var f := _figure
	f.draw_circle(at + Vector2(-size * 0.5, -size * 0.3), size * 0.55, color)
	f.draw_circle(at + Vector2(size * 0.5, -size * 0.3), size * 0.55, color)
	f.draw_colored_polygon(PackedVector2Array([at + Vector2(-size * 0.98, -size * 0.1),
			at + Vector2(size * 0.98, -size * 0.1), at + Vector2(0, size)]), color)
