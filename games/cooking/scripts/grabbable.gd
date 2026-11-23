class_name Grabbable
extends Area2D
## Anything the hand can hold. Ingredient and Spoon extend this, so the cursor needs no
## knowledge of what it is carrying.

var holder: MarsCursor = null
var highlighted := false


func can_grab() -> bool:
	return holder == null


func grab(cursor: MarsCursor) -> void:
	holder = cursor
	set_highlighted(false)
	_on_grabbed()


## Called by the holding cursor every physics tick.
func follow(point: Vector2) -> void:
	global_position = point


func drop() -> void:
	holder = null
	_on_dropped()


func set_highlighted(on: bool) -> void:
	if on != highlighted:
		highlighted = on
		queue_redraw()


func _on_grabbed() -> void:
	pass


func _on_dropped() -> void:
	pass
