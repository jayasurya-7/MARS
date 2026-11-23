class_name StirPatterns
extends RefCounted
## Closed stirring paths, each a loop the patient follows with the spoon.
##
## Every path is returned in a flat, circular space about 125 units across and starts at the
## lateral extreme of the right arm, moving anterior (up the screen) first. Mirror x for the
## left arm. The tracker stretches them into the 3/4 view.

enum Id { CIRCLE, WIDE_OVAL, TALL_OVAL, FIGURE_EIGHT, SQUARE, DIAMOND }

const POINT_COUNT := 360

const NAMES := {
	Id.CIRCLE: "circle",
	Id.WIDE_OVAL: "wide oval",
	Id.TALL_OVAL: "tall oval",
	Id.FIGURE_EIGHT: "figure eight",
	Id.SQUARE: "square",
	Id.DIAMOND: "diamond",
}

## What each shape trains, shown to the therapist and used in the customer's order.
const FOCUS := {
	Id.CIRCLE: "smooth lateral and anterior control",
	Id.WIDE_OVAL: "side-to-side (medial-lateral) reach",
	Id.TALL_OVAL: "forward-and-back (anterior-posterior) reach",
	Id.FIGURE_EIGHT: "changing direction smoothly",
	Id.SQUARE: "sharp turns at the corners",
	Id.DIAMOND: "reaching to four points",
}

## Order the patterns come up in a trial, easiest first.
const SEQUENCE: Array[int] = [
	Id.CIRCLE, Id.WIDE_OVAL, Id.TALL_OVAL, Id.SQUARE, Id.FIGURE_EIGHT, Id.DIAMOND,
]


static func display_name(id: int) -> String:
	return NAMES.get(id, "circle")


## The loop as POINT_COUNT points, without repeating the first at the end.
static func points(id: int, scale: float = 1.0) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in POINT_COUNT:
		var t := TAU * i / POINT_COUNT
		result.append(_at(id, t) * scale)
	return result


## A point on the shape for parameter t, with y negative (up the screen) as t grows from 0.
static func _at(id: int, t: float) -> Vector2:
	match id:
		Id.WIDE_OVAL:
			return Vector2(cos(t) * 150.0, -sin(t) * 82.0)
		Id.TALL_OVAL:
			return Vector2(cos(t) * 82.0, -sin(t) * 150.0)
		Id.FIGURE_EIGHT:
			# Gerono lemniscate: crosses itself in the middle.
			return Vector2(cos(t) * 150.0, -sin(t) * cos(t) * 230.0)
		Id.SQUARE:
			return _superellipse(t, 4.0, 118.0, 118.0)
		Id.DIAMOND:
			return _superellipse(t, 1.15, 145.0, 145.0)
		_:
			return Vector2(cos(t), -sin(t)) * 125.0


static func _superellipse(t: float, power: float, a: float, b: float) -> Vector2:
	var c := cos(t)
	var s := sin(t)
	var exponent := 2.0 / power
	return Vector2(signf(c) * pow(absf(c), exponent) * a, -signf(s) * pow(absf(s), exponent) * b)
