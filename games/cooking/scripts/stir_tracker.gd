class_name StirTracker
extends Node2D
## Scores how closely a moving point follows a stirring path, and draws the guide.
##
## The path is any closed loop from StirPatterns. For each sample the tracker finds the
## nearest point on the path, near where the spoon was last time so loops that cross
## themselves (the figure eight) stay unambiguous. The distance to that point is the
## deviation, and the movement along the path says how far, and which way, the patient went.
##
## Each sample is weighted by the distance moved since the last one. A time average would
## give 100% to a patient holding still on the path. Here, not moving earns nothing and
## changes nothing.

## Fired for movement in the correct direction. `radians` is the loop fraction travelled
## times TAU, so one full lap is always TAU whatever the shape. Quality runs from 0 to 1.
signal arc_travelled(radians: float, quality: float)
signal laps_completed

enum Feedback { GOOD, OFF_PATH, WRONG_WAY, IDLE }

const IDLE_AFTER_SECONDS := 1.5
## How many path segments either side of the last position are searched.
const WINDOW := 28
## The loop has this many checkpoints. Progress cannot run more than about one checkpoint
## ahead of the last one the spoon actually reached, so shortcuts and wiggling where a path
## crosses itself earn no laps.
const CHECKPOINTS := 8
## Half-width of a checkpoint, as a fraction of the loop.
const CHECKPOINT_REACH := 0.03

## The pattern is drawn at radius / 125 times its reference size.
@export var radius := 125.0
## Deviation in pixels that still scores 100%. Widen this for patients with less control.
@export var tolerance := 22.0
## Deviation in pixels at which the score reaches 0%.
@export var max_deviation := 80.0
## Movement below this many pixels is ignored, so sensor noise and tremor at low speed
## are not scored as tiny backward strokes.
@export var min_step := 4.0
## Distance in pixels over which the live accuracy reading settles.
@export var accuracy_window := 90.0
@export var required_laps := 2
## Vertical squash of the path on screen (1.0 is flat). Points are divided by this before
## scoring, so a path drawn squashed in a 3/4 view is still scored in its true shape.
@export_range(0.3, 1.0, 0.01) var aspect := 1.0

var pattern := StirPatterns.Id.CIRCLE
## +1 or -1: which way the soup swirls for a correct stir (-1 is counter-clockwise on screen).
var direction := -1
## Recent accuracy (0..1), for the dial.
var live_accuracy := 0.0
## Correct-direction travel on the path this round, as laps times TAU.
var progress := 0.0
var feedback := Feedback.GOOD

var _path := PackedVector2Array()
var _cumulative := PackedFloat32Array()
var _total := 1.0
var _mirror := false

var _anchor := Vector2.ZERO
var _anchor_s := 0.0
var _anchor_index := 0
var _has_anchor := false
var _has_live_value := false
var _idle_time := 0.0
var _finished := false
var _arrow_phase := 0.0
var _raw_progress := 0.0
var _passed := 0

var _weighted_quality := 0.0
var _travelled := 0.0
var _round_weighted := 0.0
var _round_travelled := 0.0
var _round_wrong := 0.0
var _round_off := 0.0
var _round_idle := 0.0


func _ready() -> void:
	if _path.is_empty():
		_rebuild()


func set_pattern(id: int) -> void:
	pattern = id
	_rebuild()


## Right arm: lateral is screen right and anterior is up. Left arm is the mirror image.
func set_training_side(side: int) -> void:
	direction = -1 if side == MarsInput.Side.RIGHT else 1
	_mirror = side != MarsInput.Side.RIGHT
	_rebuild()


func start_point() -> Vector2:
	if _path.is_empty():
		_rebuild()
	return _to_screen(_path[0])


## A point a given fraction (0 to 1) of the way round the path, on screen.
func point_at(fraction: float) -> Vector2:
	return _to_screen(_path[int(fposmod(fraction, 1.0) * _path.size())])


## The whole loop as it appears on screen, for the order ticket.
func preview_points() -> PackedVector2Array:
	if _path.is_empty():
		_rebuild()
	var points := PackedVector2Array()
	for point in _path:
		points.append(_to_screen(point))
	return points


func _rebuild() -> void:
	var points := StirPatterns.points(pattern, radius / 125.0)
	if _mirror:
		for i in points.size():
			points[i].x = -points[i].x
	_path = points
	var count := _path.size()
	_cumulative.resize(count + 1)
	var run := 0.0
	for i in count:
		_cumulative[i] = run
		run += _path[i].distance_to(_path[(i + 1) % count])
	_cumulative[count] = run
	_total = run
	_has_anchor = false
	queue_redraw()


func _to_screen(flat: Vector2) -> Vector2:
	return Vector2(flat.x, flat.y * aspect)


func _to_flat(screen: Vector2) -> Vector2:
	return Vector2(screen.x, screen.y / aspect)


## Forget the last position, so grabbing the spoon elsewhere is not scored as movement.
func begin_stroke() -> void:
	_has_anchor = false
	_idle_time = 0.0
	feedback = Feedback.GOOD


func reset_round() -> void:
	progress = 0.0
	_raw_progress = 0.0
	_passed = 0
	_finished = false
	_round_weighted = 0.0
	_round_travelled = 0.0
	_round_wrong = 0.0
	_round_off = 0.0
	_round_idle = 0.0
	begin_stroke()
	queue_redraw()


func reset_session() -> void:
	reset_round()
	live_accuracy = 0.0
	_has_live_value = false
	_weighted_quality = 0.0
	_travelled = 0.0


## 1.0 within tolerance, falling linearly to 0.0 at max_deviation.
func quality_at(point: Vector2) -> float:
	if _path.is_empty():
		_rebuild()
	return _quality(_nearest(_to_flat(point), 0, _path.size()).x)


func _quality(deviation: float) -> float:
	return 1.0 - clampf((deviation - tolerance) / maxf(max_deviation - tolerance, 0.001), 0.0, 1.0)


## Distance-weighted accuracy across every stroke this session (0..1), or -1 if none.
func session_accuracy() -> float:
	return _weighted_quality / _travelled if _travelled > 0.0 else -1.0


## How the current round went, for the customer's feedback. Fractions are of the distance
## the spoon travelled.
func round_stats() -> Dictionary:
	var travelled := maxf(_round_travelled, 0.001)
	return {
		"accuracy": _round_weighted / travelled if _round_travelled > 0.0 else 0.0,
		"wrong_way": _round_wrong / travelled,
		"off_path": _round_off / travelled,
		"idle_seconds": _round_idle,
		"distance": _round_travelled,
	}


func lap_count() -> int:
	return int(progress / TAU)


## The nearest point on `count` consecutive segments starting at `first`.
## Returns (distance, arc length along the path, segment index).
func _nearest(point: Vector2, first: int, count: int) -> Vector3:
	var size := _path.size()
	var best := Vector3(INF, 0.0, 0.0)
	for k in count:
		var i := posmod(first + k, size)
		var a := _path[i]
		var ab := _path[(i + 1) % size] - a
		var length_sq := ab.length_squared()
		var t := clampf((point - a).dot(ab) / length_sq, 0.0, 1.0) if length_sq > 0.0 else 0.0
		var distance := point.distance_to(a + ab * t)
		if distance < best.x:
			best = Vector3(distance, _cumulative[i] + t * sqrt(length_sq), float(i))
	return best


## point is relative to the pot's centre. Call once per physics tick while stirring.
func add_sample(screen_point: Vector2, delta: float) -> void:
	if _path.is_empty():
		_rebuild()
	var point := _to_flat(screen_point)
	var count := _path.size()
	if not _has_anchor:
		_set_anchor(point, _nearest(point, 0, count))
		_has_anchor = true
		return

	var step := point.distance_to(_anchor)
	if step < min_step:
		_idle_time += delta
		if _idle_time >= IDLE_AFTER_SECONDS:
			feedback = Feedback.IDLE
			_round_idle += delta
		return
	_idle_time = 0.0

	var found := _nearest(point, _anchor_index - WINDOW, WINDOW * 2 + 1)
	if found.x > max_deviation:
		# Far from where we expected: take the nearest point anywhere if it is clearly better.
		var anywhere := _nearest(point, 0, count)
		if anywhere.x < found.x * 0.7:
			found = anywhere
	var moved := wrapf(found.y - _anchor_s, -_total * 0.5, _total * 0.5)
	var previous_s := _anchor_s
	_set_anchor(point, found)

	# A quarter of the loop in one sample is a tracking jump, not a movement. Don't score it.
	if absf(moved) > _total * 0.25:
		return

	var turned := moved / _total * TAU
	var quality := _quality(found.x)
	if quality <= 0.0:
		feedback = Feedback.OFF_PATH
		_round_off += step
	elif turned < 0.0:
		quality = 0.0
		feedback = Feedback.WRONG_WAY
		_round_wrong += step
	else:
		feedback = Feedback.GOOD

	_weighted_quality += quality * step
	_travelled += step
	_round_weighted += quality * step
	_round_travelled += step
	var blend := 1.0 - exp(-step / accuracy_window)
	live_accuracy = lerpf(live_accuracy, quality, blend) if _has_live_value else quality
	_has_live_value = true

	if quality > 0.0:
		_raw_progress += turned
		_advance_checkpoints(previous_s, moved)
		var allowed := (_passed + 1.2) * TAU / CHECKPOINTS
		var credited := minf(_raw_progress, allowed)
		var gain := credited - progress
		if gain > 0.0:
			progress = credited
			arc_travelled.emit(gain, quality)
		if not _finished and lap_count() >= required_laps:
			_finished = true
			laps_completed.emit()


## Counts the checkpoints the spoon passed on its way from `from_s` forward by `moved`.
func _advance_checkpoints(from_s: float, moved: float) -> void:
	if moved <= 0.0:
		return
	var reach := _total * CHECKPOINT_REACH
	for guard in CHECKPOINTS:
		var next_s := float((_passed % CHECKPOINTS) + 1) / CHECKPOINTS * _total
		var ahead := wrapf(next_s - from_s, -_total * 0.5, _total * 0.5)
		if ahead > -reach and ahead <= moved + reach:
			_passed += 1
		else:
			break


func _set_anchor(point: Vector2, found: Vector3) -> void:
	_anchor = point
	_anchor_s = found.y
	_anchor_index = int(found.z)


func _process(delta: float) -> void:
	if visible:
		_arrow_phase = fposmod(_arrow_phase + delta * 0.5, 1.0)
		queue_redraw()


func _draw() -> void:
	if _path.is_empty():
		return
	# Drawn flat, then squashed by `aspect` to match the 3/4 view.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, aspect))
	var count := _path.size()
	# The two faint edges mark the full-marks zone: staying between them scores 100%.
	for side: float in [-1.0, 1.0]:
		var edge := PackedVector2Array()
		for i in count:
			var tangent := (_path[(i + 1) % count] - _path[posmod(i - 1, count)]).normalized()
			edge.append(_path[i] + tangent.orthogonal() * tolerance * side)
		edge.append(edge[0])
		draw_polyline(edge, Color(1, 1, 1, 0.42), 2.0, true)

	var done := fposmod(progress, TAU) / TAU
	var stride := 3
	for i in range(0, count, stride):
		var f := float(i) / count
		var a := _path[i]
		var b := _path[(i + stride) % count]
		if f < done:
			draw_line(a, b, Color.from_hsv(f * 0.85, 0.5, 1.0, 1.0), 12.0, true)
		else:
			draw_line(a, b, Color.from_hsv(f * 0.85, 0.8, 1.0, 0.7), 5.0, true)

	# Moving chevrons show the direction of travel.
	for i in 8:
		var f := (i + _arrow_phase) / 8.0
		var index := int(f * count) % count
		var tangent := (_path[(index + 2) % count] - _path[posmod(index - 2, count)]).normalized()
		_draw_chevron(_path[index], tangent.angle())

	var pulse := 1.0 + 0.15 * sin(_arrow_phase * TAU * 2.0)
	var start := _path[0]
	draw_circle(start, 13.0 * pulse, Color(0, 0, 0, 0.45))
	draw_circle(start, 9.5 * pulse, Color("ffe25a"))
	draw_circle(start + Vector2(-2, -2), 3.0, Color(1, 1, 1, 0.8))
	draw_set_transform(Vector2.ZERO)


func _draw_chevron(at: Vector2, heading: float) -> void:
	var forward := Vector2.from_angle(heading)
	var side := forward.orthogonal()
	var tip := at + forward * 9.0
	var wing_a := at - forward * 3.0 + side * 9.0
	var wing_b := at - forward * 3.0 - side * 9.0
	draw_line(tip, wing_a, Color(0, 0, 0, 0.55), 7.0, true)
	draw_line(tip, wing_b, Color(0, 0, 0, 0.55), 7.0, true)
	draw_line(tip, wing_a, Color(1, 1, 1, 0.95), 3.5, true)
	draw_line(tip, wing_b, Color(1, 1, 1, 0.95), 3.5, true)
