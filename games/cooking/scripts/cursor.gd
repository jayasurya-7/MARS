class_name MarsCursor
extends Area2D
## The virtual hand. Reads MarsInput, moves, and owns grabbing and releasing.

signal grabbed(item: Grabbable)
signal released(item: Grabbable)

## Filters sensor jitter (seconds). Too high and the hand feels laggy.
@export_range(0.0, 0.3, 0.01) var smoothing_time := 0.04
## The grip must stay open this long to count as a release, so a single noisy
## button reading cannot drop what the patient is carrying.
@export_range(0.0, 0.5, 0.01) var release_debounce := 0.08
## Steady hover time before an ingredient is picked up automatically.
@export_range(0.1, 3.0, 0.05) var ingredient_hover_seconds := 0.3

var grip := false
var held: Grabbable = null

var _was_gripping := false
var _release_timer := 0.0
var _hovered: Grabbable = null
var _hover_seconds := 0.0


func _ready() -> void:
	global_position = _target_position()


func _physics_process(delta: float) -> void:
	_update_position(delta)
	_update_grip(delta)
	_update_hover()
	# Only closing-then-opening the grip lets go, so an item picked up by hovering (with the
	# grip never pressed) stays in the hand until it reaches the pot.
	var grip_opened := _was_gripping and not grip
	_was_gripping = grip

	if held == null:
		# Pressing the grip takes whatever is under the hand at once. Vegetables can also be
		# picked up by hovering steadily, for patients who cannot hold the grip.
		if grip and _hovered != null:
			_take(_hovered)
		elif _hovered != null:
			_hover_seconds += delta
			if _hovered.has_method("set_hover_progress"):
				_hovered.set_hover_progress(_hover_seconds / ingredient_hover_seconds)
			if _hover_seconds >= ingredient_hover_seconds:
				_take(_hovered)
	elif grip_opened:
		force_release()
	else:
		held.follow(global_position)


## Lets go of the held item. Also used by the game when the timer runs out.
func force_release() -> void:
	if held == null:
		return
	var item := held
	held = null
	item.drop()
	released.emit(item)
	queue_redraw()


func _take(item: Grabbable) -> void:
	if item is Ingredient:
		item.set_hover_progress(0.0)
	_hovered = null
	_hover_seconds = 0.0
	held = item
	item.grab(self)
	item.follow(global_position)
	grabbed.emit(item)
	queue_redraw()


func _target_position() -> Vector2:
	return MarsInput.normalized_position * get_viewport_rect().size


func _update_position(delta: float) -> void:
	var target := _target_position()
	if smoothing_time <= 0.0:
		global_position = target
	else:
		global_position = global_position.lerp(target, 1.0 - exp(-delta / smoothing_time))


func _update_grip(delta: float) -> void:
	var was_gripping := grip
	if MarsInput.grip:
		grip = true
		_release_timer = 0.0
	elif grip:
		_release_timer += delta
		if _release_timer >= release_debounce:
			grip = false
	if grip != was_gripping:
		queue_redraw()


func _update_hover() -> void:
	var best: Grabbable = null
	if held == null:
		var best_distance := INF
		# The collision mask already limits this to the Ingredients and Spoon layers.
		for area in get_overlapping_areas():
			if area is Grabbable and area.can_grab():
				var distance := global_position.distance_squared_to(area.global_position)
				if distance < best_distance:
					best_distance = distance
					best = area
	if best != _hovered:
		if is_instance_valid(_hovered):
			_hovered.set_highlighted(false)
			if _hovered is Ingredient:
				if _hovered.has_method("set_hover_progress"):
					_hovered.set_hover_progress(0.0)
		_hovered = best
		_hover_seconds = 0.0
		if _hovered != null:
			_hovered.set_highlighted(true)


func _draw() -> void:
	var glove := Color("f4f7fb")
	var line := Color("24415f")
	if grip:
		draw_arc(Vector2.ZERO, 36.0, 0.0, TAU, 48, Color("3ddc84"), 5.0, true)
		_fist(line, 3.0)
		_fist(glove, 0.0)
	else:
		_open_hand(line, 3.0)
		_open_hand(glove, 0.0)


func _fist(color: Color, grow: float) -> void:
	draw_circle(Vector2(0, 5), 19.0 + grow, color)
	for i in 4:
		draw_circle(Vector2(-14.0 + i * 9.5, -9.0), 6.5 + grow, color)
	draw_circle(Vector2(-19, 6), 7.0 + grow, color)


func _open_hand(color: Color, grow: float) -> void:
	draw_circle(Vector2(0, 7), 17.0 + grow, color)
	for i in 4:
		var base := Vector2(-12.0 + i * 8.0, -5.0)
		var tip := base + Vector2((i - 1.5) * 3.0, -21.0)
		_capsule(base, tip, 4.0 + grow, color)
	_capsule(Vector2(-13, 9), Vector2(-28, -3), 4.5 + grow, color)


func _capsule(a: Vector2, b: Vector2, radius: float, color: Color) -> void:
	draw_line(a, b, color, radius * 2.0, true)
	draw_circle(a, radius, color)
	draw_circle(b, radius, color)
