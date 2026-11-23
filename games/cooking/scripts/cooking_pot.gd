class_name CookingPot
extends Area2D
## Accepts ingredients, plays the splash, then runs the stirring phase and turns stir
## quality into points. Drawn in a 3/4 view: the origin is the centre of the opening.

signal ingredient_added(ingredient: Ingredient)
signal all_ingredients_added
signal stir_points(points: float)
signal stir_completed

enum Phase { CLOSED, COLLECTING, STIRRING }

## Half-width and half-height of the opening, and the height of the visible front wall.
const RX := 218.0
const RY := 182.0
const WALL := 72.0
## How much the view squashes the liquid surface vertically.
const ASPECT := RY / RX
## The stirring path is drawn well beyond the pot so the stir uses much of the patient's range,
## not just the pot (MARS HOMER). Tolerances grow with it.
const STIR_RADIUS := 330.0
## How far inside the opening (0 is the centre, 1 the rim) a carried vegetable must be to drop.
const DROP_DEPTH := 0.7

## Points per radian of perfect stirring, so one perfect lap earns about 126.
@export var points_per_radian := 20.0
## Below this quality a stroke still moves the lap on, but earns no points.
@export_range(0.0, 1.0, 0.05) var scoring_threshold := 0.5

var phase := Phase.CLOSED
var required_ingredients := 3
var added := 0

var _soup_warmth := 0.0
var _t := 0.0
## Soup pieces as (angle, radius, kind); the first few appear as ingredients go in.
var _pieces: Array[Vector3] = []
## Ripples as [position, age in seconds].
var _ripples: Array = []

@onready var splash: CPUParticles2D = $Splash
@onready var contents: Node2D = $Contents
@onready var tracker: StirTracker = $StirTracker
@onready var spoon: Spoon = $Spoon


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	tracker.arc_travelled.connect(_on_arc_travelled)
	tracker.laps_completed.connect(_on_laps_completed)
	tracker.aspect = ASPECT
	tracker.radius = STIR_RADIUS
	tracker.tolerance = 22.0 * STIR_RADIUS / 125.0
	tracker.max_deviation = 80.0 * STIR_RADIUS / 125.0
	tracker.set_training_side(MarsInput.training_side)
	tracker._rebuild()
	spoon.set_rest_point(tracker.start_point())
	close()


func open_for_ingredients(count: int, pattern: int = StirPatterns.Id.CIRCLE) -> void:
	phase = Phase.COLLECTING
	required_ingredients = count
	added = 0
	_soup_warmth = 0.0
	for item in contents.get_children():
		item.queue_free()
	_pieces.clear()
	for i in 16:
		_pieces.append(Vector3(randf() * TAU, 20.0 + sqrt(randf()) * 125.0, i % 4))
	tracker.visible = false
	tracker.aspect = ASPECT
	tracker.set_pattern(pattern)
	tracker.set_training_side(MarsInput.training_side)
	tracker.reset_round()
	spoon.enabled = false
	spoon.set_rest_point(tracker.start_point())
	queue_redraw()


func close() -> void:
	phase = Phase.CLOSED
	tracker.visible = false
	spoon.enabled = false


## Returns true if the ingredient went in.
func accept_ingredient(item: Ingredient) -> bool:
	if phase != Phase.COLLECTING:
		return false
	added += 1
	splash.global_position = item.global_position
	splash.restart()
	_ripples.append([to_local(item.global_position), 0.0])
	var angle := randf() * TAU
	item.settle_in(contents, Vector2(cos(angle), sin(angle) * ASPECT) * randf_range(25.0, 90.0))
	_soup_warmth = float(added) / required_ingredients
	ingredient_added.emit(item)
	if added >= required_ingredients:
		phase = Phase.STIRRING
		tracker.visible = true
		spoon.enabled = true
		all_ingredients_added.emit()
	return true


func coaching_text() -> String:
	if spoon.holder == null:
		return "Grab the wooden spoon"
	match tracker.feedback:
		StirTracker.Feedback.OFF_PATH:
			return "Bring the spoon back to the ring"
		StirTracker.Feedback.WRONG_WAY:
			return "Follow the arrows"
		StirTracker.Feedback.IDLE:
			return "Keep stirring"
	return "Stir along the ring: lap %d of %d" % [
		mini(tracker.lap_count() + 1, tracker.required_laps), tracker.required_laps,
	]


func _physics_process(delta: float) -> void:
	if phase == Phase.STIRRING and spoon.holder != null:
		tracker.add_sample(to_local(spoon.global_position), delta)
	elif phase == Phase.COLLECTING:
		_drop_carried_ingredients()


## Carrying a vegetable well into the opening is enough; the patient need not open the grip.
## Brushing past the edge does not count.
func _drop_carried_ingredients() -> void:
	for area in get_overlapping_areas():
		if not area is Ingredient or area.state != Ingredient.State.HELD or area.holder == null:
			continue
		var local := to_local(area.global_position)
		if Vector2(local.x / RX, local.y / RY).length() < DROP_DEPTH:
			area.holder.force_release()
			return


func _process(delta: float) -> void:
	_t += delta
	for ripple: Array in _ripples:
		ripple[1] += delta
	_ripples = _ripples.filter(func(r: Array) -> bool: return r[1] < 0.8)
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if area is Ingredient:
		area.target_pot = self


func _on_area_exited(area: Area2D) -> void:
	# An ingredient that has just gone in leaves the area when it is reparented; keep the link.
	if area is Ingredient and area.target_pot == self and area.state != Ingredient.State.IN_POT:
		area.target_pot = null


func _on_arc_travelled(radians: float, quality: float) -> void:
	contents.rotation += radians * tracker.direction * 0.6
	if quality >= scoring_threshold:
		stir_points.emit(radians * quality * points_per_radian)


func _on_laps_completed() -> void:
	close()
	stir_completed.emit()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	Paint.ellipse(self, Vector2(8, WALL + 34.0), RX + 26.0, RY + 12.0, Color(0, 0, 0, 0.4))
	_flames()
	_body()
	_liquid()
	_steam()


## A point on the liquid surface, from a flat polar position.
func _surface(angle: float, radius: float) -> Vector2:
	return Vector2(cos(angle) * radius, sin(angle) * radius * ASPECT + 6.0)


func _flames() -> void:
	var burner := Vector2(0, WALL + 8.0)
	var power := 1.0 if phase != Phase.CLOSED else 0.55
	for i in 4:
		Paint.ellipse(self, burner, 268.0 - i * 10.0, 214.0 - i * 8.0,
				Color(1.0, 0.5, 0.12, (0.05 + 0.025 * i) * power))
	# Low flames licking out from under the pot, on the front and sides only.
	var n := 40
	for i in n:
		var a := TAU * i / n
		if sin(a) < -0.25:
			continue
		var flick := 0.5 + 0.5 * sin(_t * 9.0 + i * 1.7)
		var dir := Vector2(cos(a), sin(a) * 0.85).normalized()
		var side := dir.orthogonal()
		var base := burner + Vector2(cos(a) * 214.0, sin(a) * 168.0)
		var length := (9.0 + 11.0 * flick) * power
		var sway := side * sin(_t * 6.0 + i) * 2.0
		draw_colored_polygon(PackedVector2Array([base - side * 11.0, base + side * 11.0, base + dir * length + sway]),
				Color(1.0, 0.48, 0.1, 0.9))
		draw_colored_polygon(PackedVector2Array([base - side * 6.0, base + side * 6.0, base + dir * length * 0.6 + sway]),
				Color(1.0, 0.82, 0.3, 0.95))


func _body() -> void:
	var steel_dark := Color("4b535b")
	Paint.ellipse(self, Vector2(0, WALL), RX, RY, steel_dark)
	var left := Color("59626b")
	var light := Color("c1cad2")
	var mid := Color("8d97a0")
	draw_polygon(
		PackedVector2Array([
			Vector2(-RX, 0), Vector2(-RX * 0.4, 0), Vector2(RX * 0.35, 0), Vector2(RX, 0),
			Vector2(RX, WALL), Vector2(RX * 0.35, WALL), Vector2(-RX * 0.4, WALL), Vector2(-RX, WALL),
		]),
		PackedColorArray([left, light, mid, steel_dark, steel_dark, mid, light, left]))
	draw_line(Vector2(-RX * 0.62, 8.0), Vector2(-RX * 0.62, WALL + RY * 0.62), Color(1, 1, 1, 0.2), 12.0, true)
	draw_line(Vector2(RX * 0.7, 8.0), Vector2(RX * 0.7, WALL + RY * 0.55), Color(0, 0, 0, 0.18), 14.0, true)
	Paint.ellipse_arc(self, Vector2(0, WALL), RX - 1.0, RY - 1.0, 0.0, PI, Color("262b30"), 4.0)
	# Rainbow band on the front wall, echoing the stirring ring.
	for i in 28:
		var a0 := 0.32 + (PI - 0.64) * i / 28.0
		Paint.ellipse_arc(self, Vector2(0, WALL), RX - 14.0, RY - 38.0, a0, a0 + 0.14,
				Color.from_hsv(float(i) / 28.0 * 0.85, 0.7, 1.0, 0.9), 7.0)
	# Handles with rivets.
	for side: float in [-1.0, 1.0]:
		var centre := Vector2(side * (RX + 12.0), 34.0)
		var from := PI * 0.5 if side < 0.0 else -PI * 0.5
		draw_arc(centre, 27.0, from, from + PI, 20, Color("2b3036"), 13.0, true)
		draw_arc(centre, 27.0, from, from + PI, 20, Color("98a3ad"), 7.0, true)
		draw_circle(Vector2(side * (RX - 6.0), 34.0), 7.0, Color("2b3036"))
		draw_circle(Vector2(side * (RX - 6.0), 34.0), 5.0, Color("c8d0d7"))
	# Rim and inner wall of the opening.
	Paint.ellipse(self, Vector2.ZERO, RX, RY, Color("2b3036"))
	Paint.ellipse(self, Vector2.ZERO, RX - 3.0, RY - 3.0, Color("c4cdd5"))
	Paint.ellipse(self, Vector2.ZERO, RX - 14.0, RY - 12.0, Color("7f8993"))
	Paint.ellipse(self, Vector2.ZERO, RX - 20.0, RY - 17.0, Color("33383f"))
	Paint.ellipse_arc(self, Vector2.ZERO, RX - 8.0, RY - 7.0, PI * 1.05, PI * 1.6, Color(1, 1, 1, 0.7), 6.0)


func _liquid() -> void:
	# Clear water, then golden stock, then rich tomato broth as vegetables go in.
	var water := Color("86b4c6")
	var stock := Color("d9b45f")
	var broth := Color("e0502a")
	var warmth := clampf(_soup_warmth, 0.0, 1.0)
	var liquid := water.lerp(stock, warmth / 0.34) if warmth < 0.34 \
			else stock.lerp(broth, (warmth - 0.34) / 0.66)
	Paint.ellipse(self, Vector2(0, 5), RX - 28.0, RY - 24.0, liquid.darkened(0.42))
	Paint.ellipse(self, Vector2(0, 6), RX - 34.0, RY - 30.0, liquid)
	Paint.ellipse(self, Vector2(-6, 3), RX - 72.0, RY - 66.0, liquid.lightened(0.07))
	Paint.ellipse_arc(self, Vector2(0, 6), RX - 46.0, RY - 42.0, PI * 1.1, PI * 1.45, Color(1, 1, 1, 0.3), 8.0)
	if _soup_warmth <= 0.0:
		return
	var turn := contents.rotation
	for k in 3:
		var from := turn + k * 2.1
		var points := PackedVector2Array()
		for s in 21:
			points.append(_surface(from + 1.6 * s / 20.0, 62.0 + k * 34.0))
		draw_polyline(points, liquid.lightened(0.2) * Color(1, 1, 1, 0.6), 7.0, true)
	var visible_pieces := roundi(_soup_warmth * _pieces.size())
	for i in visible_pieces:
		_piece(_pieces[i], turn)
	for i in 16:
		var phase_t := fposmod(_t * 0.45 + i * 0.37, 1.0)
		var size := 3.0 + phase_t * 8.0
		var at := _surface(i * 2.399, 30.0 + fposmod(i * 47.0, 120.0))
		var alpha := sin(phase_t * PI) * clampf(_soup_warmth * 2.0, 0.0, 1.0)
		draw_arc(at, size, 0.0, TAU, 14, Color(1, 1, 1, 0.55 * alpha), 2.0, true)
		draw_circle(at + Vector2(-size * 0.3, -size * 0.3), size * 0.25, Color(1, 1, 1, 0.7 * alpha))
	for ripple: Array in _ripples:
		var age: float = ripple[1]
		var centre: Vector2 = ripple[0]
		Paint.ellipse_arc(self, centre, 10.0 + age * 170.0, (10.0 + age * 170.0) * ASPECT, 0.0, TAU,
				Color(1, 1, 1, 0.75 * (1.0 - age / 0.8)), 4.0)


func _piece(piece: Vector3, turn: float) -> void:
	var angle := piece.x + turn
	var at := _surface(angle, piece.y)
	match int(piece.z):
		0:
			Paint.ball(self, at, 7.0, Color("78b449"))
		1:
			var cube := PackedVector2Array()
			for corner in 4:
				cube.append(at + Vector2.from_angle(angle + PI * 0.25 + corner * PI * 0.5) * 11.0)
			draw_colored_polygon(cube, Color("f0cd7a"))
			var outline := cube.duplicate()
			outline.append(cube[0])
			draw_polyline(outline, Color("b88a3c"), 2.0, true)
		2:
			draw_circle(at, 9.0, Color("c76a10"))
			draw_circle(at, 7.0, Color("f58a1f"))
			draw_circle(at, 3.5, Color("ffb35a"))
		3:
			var tri := PackedVector2Array()
			for corner in 3:
				tri.append(at + Vector2.from_angle(angle + corner * TAU / 3.0) * 10.0)
			draw_colored_polygon(tri, Color("d63a2f"))


func _steam() -> void:
	var strength := clampf(_soup_warmth * 1.5, 0.0, 1.0) * (1.0 if phase == Phase.STIRRING else 0.75)
	if strength <= 0.0:
		return
	for i in 7:
		var life := fposmod(_t * 0.22 + i / 7.0, 1.0)
		var x := (i - 3.0) * 36.0 + sin(_t * 1.3 + i * 2.0) * 16.0
		var y := -70.0 - life * 220.0
		draw_circle(Vector2(x, y), 22.0 + life * 40.0, Color(1, 1, 1, sin(life * PI) * 0.16 * strength))
