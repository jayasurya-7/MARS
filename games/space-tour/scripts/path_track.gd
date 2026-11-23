extends RefCounted
## The winding "tour route" through space. Everything is placed relative to it:
## s = distance along the route, lx = sideways offset, ly = vertical offset.

static func center(s: float) -> Vector3:
	return Vector3(
		90.0 * sin(s / 300.0) + 35.0 * sin(s / 110.0),
		25.0 * sin(s / 230.0),
		-s)


## Orientation at s: -Z of the basis points backwards, so the ship faces down the route.
static func frame(s: float) -> Basis:
	var fwd := (center(s + 1.0) - center(s - 1.0)).normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	var up := right.cross(fwd).normalized()
	return Basis(right, up, -fwd)


static func point(s: float, lx: float, ly: float) -> Vector3:
	var b := frame(s)
	return center(s) + b.x * lx + b.y * ly
