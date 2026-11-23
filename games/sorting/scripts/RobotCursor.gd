class_name RobotCursor
extends Node2D
## Large, high-contrast cursor for the robot-driven pointer, with optional
## "hold still to click" (dwell) that fills a progress ring.

signal dwell_triggered(pos: Vector2)

@export var dwell_enabled := true
@export var dwell_time := 0.3
@export var dwell_radius := 30.0

## Set by GameManager: Callable(pos: Vector2) -> bool, true when a dwell click would do something useful.
var dwell_check: Callable

var _dwell := 0.0
var _anchor := Vector2.ZERO
var _locked := false
var _click_t := 1.0
var _t := 0.0


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_click_t = 0.0


func _process(delta: float) -> void:
	_t += delta
	_click_t = minf(1.0, _click_t + delta * 2.5)
	var mp := GamePointer.screen(self)
	position = mp

	var useful: bool = dwell_enabled and dwell_check.is_valid() and bool(dwell_check.call(mp))
	if useful:
		if mp.distance_to(_anchor) > dwell_radius:
			_anchor = mp
			_dwell = 0.0
			_locked = false
		elif not _locked:
			_dwell += delta
			if _dwell >= dwell_time:
				_dwell = 0.0
				_locked = true
				dwell_triggered.emit(mp)
	else:
		_dwell = maxf(0.0, _dwell - delta * 3.0)
		_anchor = mp
		_locked = false
	queue_redraw()


func _draw() -> void:
	var holding := is_instance_valid(InteractableItem.held)
	draw_circle(Vector2.ZERO, 46.0, Color(1, 1, 1, 0.10 + 0.05 * sin(_t * 3.0)))
	draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 48, Color(0, 0, 0, 0.5), 12.0, true)
	draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 48, Color(1, 1, 1, 0.97), 6.0, true)
	draw_circle(Vector2.ZERO, 8.0, Color(0.92, 0.8, 0.55) if holding else Color.WHITE)
	if holding:
		draw_arc(Vector2.ZERO, 41.0, 0.0, TAU, 48, Color(0.92, 0.8, 0.55, 0.9), 4.0, true)
	if _dwell > 0.0:
		var p := clampf(_dwell / dwell_time, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 41.0, -PI / 2.0, -PI / 2.0 + TAU * p, 48, Color(0.62, 0.84, 0.7), 9.0, true)
	if _click_t < 1.0:
		draw_arc(Vector2.ZERO, 30.0 + 50.0 * _click_t, 0.0, TAU, 48, Color(1, 1, 1, 1.0 - _click_t), 5.0, true)
