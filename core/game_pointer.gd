class_name GamePointer
extends RefCounted
## Where the patient's hand is, for the combined-movement (MLAP) games that were written for a mouse.
## On the MARS device it is the robot's position inside the patient's assessed range, spread over the
## game's screen (a small margin keeps the edges reachable); in simulation it is the mouse.
## The games call these instead of get_viewport().get_mouse_position() / get_global_mouse_position().

## Fraction of the screen kept free at each edge on the device.
const MARGIN = 0.05

## 0..1 across the game's screen, (0, 0) top-left.
static func normalized(node: Node) -> Vector2:
	if Trial.hardware:
		return Trial.input_position(Vector2(0.5, 0.5))
	var viewport = node.get_viewport()
	var size = viewport.get_visible_rect().size
	return (viewport.get_mouse_position() / size).clamp(Vector2.ZERO, Vector2.ONE)

## In the game viewport's coordinates (like Viewport.get_mouse_position()).
static func screen(node: Node) -> Vector2:
	var viewport = node.get_viewport()
	var size = viewport.get_visible_rect().size
	if Trial.hardware:
		var margin = size * MARGIN
		return margin + Trial.input_position(Vector2(0.5, 0.5)) * (size - margin * 2.0)
	return viewport.get_mouse_position()

## In the canvas coordinates of `node` (like CanvasItem.get_global_mouse_position()).
static func world(node: CanvasItem) -> Vector2:
	return node.get_canvas_transform().affine_inverse() * screen(node)

## In the local coordinates of `node` (like CanvasItem.get_local_mouse_position()).
static func local(node: CanvasItem) -> Vector2:
	return node.get_global_transform_with_canvas().affine_inverse() * screen(node)

## Simulation only: whether the mouse button (the grip stand-in) is down. The MARS handle button is
## kept for pausing and finishing, so on the device the games select by holding still instead.
static func grip() -> bool:
	return not Trial.hardware and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
