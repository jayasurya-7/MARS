class_name LevelData
extends RefCounted
## 50 picture templates built from simple reusable objects.
##
## A picture = background colour + optional ground + objects.
## Object entry: [kind, x, y, scale, optional main colour]  (x,y = base point on the 1200x680 canvas)
## `back` objects are drawn before (behind) the ground, `o` objects after (in front of) it.
## Regions are coloured in drawing order (bottom -> top), so the background is always first.

const CANVAS_SIZE := Vector2(1200, 680)

# Order here = order of the palette buttons (top to bottom).
const PALETTE := {
	&"blue": Color("4aa8f0"),
	&"yellow": Color("ffd23f"),
	&"orange": Color("ff8c2e"),
	&"red": Color("e8383d"),
	&"brown": Color("8a5a35"),
	&"green": Color("3fb454"),
}

const SPECS := [
	{t = "Sunny House", bg = &"blue", g = &"green", back = [[&"sun", 190, 150, 1.0]],
		o = [[&"house", 560, 550, 1.5], [&"tree", 960, 550, 1.4]]},
	{t = "Big Apple", bg = &"yellow", g = &"", o = [[&"apple", 600, 620, 3.3]]},
	{t = "Rocket Trip", bg = &"blue", g = &"", o = [[&"star", 160, 150, 0.9], [&"star", 1040, 190, 0.7],
		[&"star", 1000, 520, 0.6], [&"moon", 200, 480, 1.2], [&"rocket", 600, 520, 2.0]]},
	{t = "Goldfish", bg = &"blue", g = &"yellow", o = [[&"weed", 160, 600, 1.4], [&"weed", 1040, 600, 1.6],
		[&"fish", 520, 300, 1.8, &"orange"], [&"fish", 900, 430, 1.1, &"red"], [&"fish", 260, 450, 1.0, &"green"]]},
	{t = "Sailboat", bg = &"orange", g = &"blue", back = [[&"sun", 850, 300, 1.6]],
		o = [[&"boat", 450, 540, 1.7, &"red"]]},
	{t = "Rainbow", bg = &"blue", g = &"green", back = [[&"rainbow", 600, 560, 2.0], [&"sun", 1050, 140, 0.9]],
		o = [[&"flower", 250, 590, 1.3, &"red"], [&"flower", 950, 590, 1.2, &"orange"]]},
	{t = "Camping", bg = &"blue", g = &"green", back = [[&"sun", 1050, 130, 0.9]],
		o = [[&"pine", 200, 550, 1.5], [&"pine", 920, 550, 1.8], [&"tent", 560, 570, 1.8, &"red"]]},
	{t = "Pumpkin Night", bg = &"blue", g = &"brown", back = [[&"moon", 220, 200, 1.4], [&"star", 900, 170, 0.8],
		[&"star", 1040, 300, 0.6]], o = [[&"pumpkin", 600, 610, 2.8]]},
	{t = "Butterfly Garden", bg = &"blue", g = &"green", back = [[&"sun", 1050, 130, 0.9]],
		o = [[&"flower", 250, 570, 1.6, &"red"], [&"flower", 950, 570, 1.5, &"orange"],
		[&"flower", 1090, 590, 1.1, &"yellow"], [&"butterfly", 580, 300, 1.6]]},
	{t = "Duck Pond", bg = &"blue", g = &"green", back = [[&"sun", 1050, 130, 0.8]],
		o = [[&"pond", 600, 540, 3.2], [&"duck", 560, 540, 1.5], [&"duck", 830, 575, 1.15]]},
	{t = "Mushroom Forest", bg = &"blue", g = &"green", o = [[&"pine", 1010, 550, 1.5],
		[&"mushroom", 380, 590, 2.1, &"red"], [&"mushroom", 780, 600, 1.6, &"orange"]]},
	{t = "Ladybug", bg = &"green", g = &"", o = [[&"ladybug", 600, 540, 3.4]]},
	{t = "Ice Cream", bg = &"blue", g = &"", o = [[&"icecream", 380, 620, 2.0, &"red"],
		[&"icecream", 820, 620, 2.0, &"green"]]},
	{t = "Balloons", bg = &"blue", g = &"", o = [[&"balloon", 260, 600, 1.5, &"red"], [&"balloon", 520, 570, 1.7, &"yellow"],
		[&"balloon", 790, 600, 1.5, &"orange"], [&"balloon", 1020, 570, 1.6, &"green"]]},
	{t = "Kite Day", bg = &"blue", g = &"green", back = [[&"sun", 190, 140, 1.0]],
		o = [[&"tree", 1000, 560, 1.3], [&"kite", 640, 560, 1.8, &"red"]]},
	{t = "Rainy Day", bg = &"yellow", g = &"", o = [[&"pond", 600, 600, 1.5], [&"umbrella", 600, 600, 2.3, &"red"]]},
	{t = "Snail Walk", bg = &"blue", g = &"green", back = [[&"sun", 1050, 130, 0.9]],
		o = [[&"flower", 180, 570, 1.3, &"orange"], [&"snail", 560, 560, 2.2], [&"flower", 1010, 570, 1.6, &"red"]]},
	{t = "Turtle Beach", bg = &"blue", g = &"yellow", back = [[&"sun", 1030, 140, 1.0]],
		o = [[&"turtle", 600, 580, 2.6]]},
	{t = "Castle", bg = &"blue", g = &"green", back = [[&"sun", 1060, 130, 0.9]], o = [[&"castle", 600, 570, 2.1]]},
	{t = "Windmill", bg = &"blue", g = &"green", back = [[&"sun", 1050, 140, 0.9]],
		o = [[&"tree", 950, 560, 1.5], [&"windmill", 430, 570, 1.7]]},
	{t = "Lighthouse", bg = &"orange", g = &"blue", back = [[&"sun", 250, 300, 1.3]],
		o = [[&"lighthouse", 650, 560, 1.8], [&"boat", 1000, 560, 1.0, &"yellow"]]},
	{t = "Desert", bg = &"blue", g = &"yellow", back = [[&"sun", 1000, 150, 1.2]],
		o = [[&"cactus", 220, 570, 1.4], [&"cactus", 950, 580, 1.6], [&"cactus", 600, 590, 2.1]]},
	{t = "Crab", bg = &"blue", g = &"yellow", back = [[&"sun", 1000, 140, 1.1]], o = [[&"crab", 600, 590, 2.4]]},
	{t = "Cherries", bg = &"yellow", g = &"", o = [[&"cherry", 600, 620, 2.9]]},
	{t = "Cupcakes", bg = &"blue", g = &"", o = [[&"cupcake", 380, 610, 2.3, &"red"], [&"cupcake", 820, 610, 2.3, &"yellow"]]},
	{t = "Presents", bg = &"blue", g = &"", o = [[&"gift", 380, 610, 2.0, &"red"], [&"gift", 780, 610, 2.3, &"green"],
		[&"gift", 1040, 610, 1.4, &"orange"]]},
	{t = "School Bus", bg = &"blue", g = &"green", back = [[&"sun", 190, 140, 1.0]],
		o = [[&"tree", 1050, 560, 1.4], [&"bus", 560, 580, 2.0]]},
	{t = "Red Car", bg = &"blue", g = &"green", back = [[&"sun", 1020, 140, 1.0]],
		o = [[&"tree", 180, 560, 1.5], [&"car", 620, 590, 2.4]]},
	{t = "Busy Bee", bg = &"blue", g = &"green", back = [[&"sun", 1050, 130, 0.8]],
		o = [[&"flower", 230, 580, 1.8, &"red"], [&"flower", 950, 580, 1.8, &"orange"], [&"bee", 590, 420, 2.0]]},
	{t = "Little Bird", bg = &"yellow", g = &"", o = [[&"bird", 600, 600, 3.2, &"red"]]},
	{t = "Night Sky", bg = &"blue", g = &"", o = [[&"moon", 300, 300, 2.4], [&"star", 700, 160, 1.0],
		[&"star", 900, 300, 1.3, &"orange"], [&"star", 1050, 150, 0.8], [&"star", 650, 450, 0.9], [&"star", 980, 520, 1.1]]},
	{t = "Hearts", bg = &"blue", g = &"", o = [[&"heart", 420, 390, 2.2, &"red"], [&"heart", 850, 320, 1.6, &"orange"],
		[&"heart", 800, 540, 1.0, &"red"]]},
	{t = "Stars", bg = &"blue", g = &"", o = [[&"star", 250, 260, 1.6], [&"star", 600, 350, 2.2, &"orange"],
		[&"star", 950, 260, 1.6, &"red"], [&"star", 400, 540, 1.0, &"green"], [&"star", 820, 540, 1.1]]},
	{t = "Mountains", bg = &"blue", g = &"green", back = [[&"sun", 190, 150, 1.0], [&"mountain", 330, 560, 1.6],
		[&"mountain", 930, 560, 1.4], [&"mountain", 640, 560, 2.1]], o = []},
	{t = "Forest Walk", bg = &"blue", g = &"green", back = [[&"sun", 1060, 130, 0.9]],
		o = [[&"pine", 180, 560, 1.6], [&"tree", 470, 570, 1.7], [&"pine", 760, 560, 1.9], [&"tree", 1050, 570, 1.5]]},
	{t = "Garden Fence", bg = &"blue", g = &"green", back = [[&"sun", 1050, 130, 0.9]],
		o = [[&"fence", 600, 520, 2.6], [&"flower", 220, 600, 1.5, &"red"], [&"flower", 480, 610, 1.3, &"orange"],
		[&"flower", 760, 610, 1.4, &"yellow"], [&"flower", 1010, 600, 1.5, &"red"]]},
	{t = "Farm", bg = &"blue", g = &"green", back = [[&"sun", 190, 140, 1.0]],
		o = [[&"barn", 520, 560, 2.0], [&"tree", 960, 560, 1.5]]},
	{t = "Beach Day", bg = &"blue", g = &"yellow", back = [[&"sun", 1020, 140, 1.1]],
		o = [[&"umbrella", 340, 590, 1.9, &"red"], [&"crab", 850, 590, 1.3]]},
	{t = "Pond Friends", bg = &"green", g = &"", o = [[&"pond", 600, 430, 3.0], [&"duck", 480, 430, 1.4],
		[&"duck", 760, 460, 1.2], [&"mushroom", 200, 610, 1.3, &"red"], [&"mushroom", 1000, 610, 1.3, &"orange"]]},
	{t = "Planets", bg = &"blue", g = &"", o = [[&"planet", 820, 300, 1.7, &"orange"], [&"planet", 240, 190, 0.9, &"green"],
		[&"star", 1050, 540, 0.9], [&"star", 500, 150, 0.7], [&"rocket", 450, 500, 1.6]]},
	{t = "Ocean Friends", bg = &"blue", g = &"yellow", o = [[&"weed", 130, 600, 1.5], [&"weed", 1060, 600, 1.6],
		[&"fish", 330, 250, 1.4, &"red"], [&"fish", 820, 230, 1.7, &"orange"], [&"fish", 600, 420, 1.1, &"green"]]},
	{t = "Fruit Basket", bg = &"blue", g = &"", o = [[&"apple", 470, 560, 1.5, &"red"], [&"apple", 660, 560, 1.4, &"green"],
		[&"apple", 800, 570, 1.3, &"orange"], [&"basket", 630, 620, 2.2]]},
	{t = "Carrots", bg = &"yellow", g = &"", o = [[&"carrot", 300, 640, 1.7], [&"carrot", 600, 640, 2.0], [&"carrot", 900, 640, 1.6]]},
	{t = "Pumpkin Patch", bg = &"blue", g = &"green", back = [[&"moon", 220, 160, 1.0]],
		o = [[&"pumpkin", 300, 580, 1.6], [&"pumpkin", 700, 590, 2.1], [&"pumpkin", 1010, 570, 1.3]]},
	{t = "Little Town", bg = &"blue", g = &"green", back = [[&"sun", 1060, 130, 0.8]],
		o = [[&"house", 220, 560, 1.0, &"orange"], [&"tree", 430, 570, 1.0], [&"house", 640, 560, 1.3, &"yellow"],
		[&"house", 1000, 560, 1.1, &"brown"]]},
	{t = "Hot Air Balloon", bg = &"blue", g = &"green", o = [[&"hotair", 200, 330, 0.8, &"orange"],
		[&"hotair", 1000, 380, 0.7, &"green"], [&"hotair", 600, 600, 1.6, &"red"]]},
	{t = "Flower Field", bg = &"blue", g = &"green", back = [[&"sun", 1050, 130, 0.9]],
		o = [[&"flower", 180, 570, 1.3, &"red"], [&"flower", 360, 600, 1.8, &"orange"], [&"flower", 560, 580, 1.4, &"yellow"],
		[&"flower", 760, 610, 1.9, &"red"], [&"flower", 960, 580, 1.5, &"orange"], [&"flower", 1085, 600, 1.1, &"yellow"]]},
	{t = "Sunset Sea", bg = &"orange", g = &"blue", back = [[&"sun", 600, 440, 2.0]],
		o = [[&"boat", 360, 560, 1.5, &"red"], [&"boat", 920, 540, 1.1, &"yellow"]]},
	{t = "Autumn Trees", bg = &"blue", g = &"green", back = [[&"sun", 1050, 130, 0.9]],
		o = [[&"tree", 260, 570, 1.7, &"orange"], [&"tree", 940, 570, 1.6, &"orange"], [&"tree", 600, 580, 2.1, &"red"]]},
	{t = "Bug Party", bg = &"blue", g = &"green", back = [[&"sun", 1060, 130, 0.8]],
		o = [[&"ladybug", 260, 580, 1.4], [&"snail", 640, 580, 1.1], [&"bee", 940, 300, 1.5], [&"butterfly", 480, 280, 1.3]]},
]


# ───────────────────────────── public API ─────────────────────────────

static func count() -> int:
	return SPECS.size()

## Returns {title, regions:[{name,color,poly,details,step}]} for picture `index` (wraps around).
static func build(index: int) -> Dictionary:
	var sp: Dictionary = SPECS[posmod(index, SPECS.size())]
	var regions: Array = []
	regions.append(_r("Background", sp.bg, rect(20, 20, 1180, 660)))
	for o: Array in sp.get("back", []):
		regions.append_array(_obj(o))
	if sp.g != &"":
		regions.append(_r(_ground_name(sp.g), sp.g, _hills()))
	for o: Array in sp.o:
		regions.append_array(_obj(o))
	for i in regions.size():
		regions[i].step = i
	return {title = sp.t, regions = regions}


# ───────────────────────────── geometry helpers ─────────────────────────────

static func rect(x0: float, y0: float, x1: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])

static func ellipse(c: Vector2, rx: float, ry: float, n: int = 48) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

## Upper half of an ellipse with a flat bottom.
static func half(c: Vector2, rx: float, ry: float, n: int = 28) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := PI + PI * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

static func tri(a: Vector2, b: Vector2, c: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a, b, c])

static func poly(coords: Array) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(0, coords.size(), 2):
		pts.append(Vector2(coords[i], coords[i + 1]))
	return pts

static func loop(pts: PackedVector2Array) -> PackedVector2Array:
	var p := pts.duplicate()
	p.append(p[0])
	return p

static func eye(c: Vector2, r: float = 7.0) -> PackedVector2Array:
	return loop(ellipse(c, r, r, 12))

static func line(coords: Array) -> PackedVector2Array:
	return poly(coords)

static func star_poly(r_out: float, r_in: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var r := r_out if i % 2 == 0 else r_in
		pts.append(Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * r)
	return pts

static func heart_poly(k: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 64:
		var t := TAU * i / 64.0
		pts.append(Vector2(16.0 * pow(sin(t), 3.0),
			-(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * k)
	return pts

static func rot_rect(len_: float, w: float, ang: float, origin: Vector2) -> PackedVector2Array:
	var pts := rect(0, -w * 0.5, len_, w * 0.5)
	for i in pts.size():
		pts[i] = origin + pts[i].rotated(ang)
	return pts

static func band(r_out: float, r_in: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 41:
		pts.append(Vector2.from_angle(PI + PI * i / 40.0) * r_out)
	for i in range(40, -1, -1):
		pts.append(Vector2.from_angle(PI + PI * i / 40.0) * r_in)
	return pts

static func _hills() -> PackedVector2Array:
	var pts := PackedVector2Array([Vector2(20, 660)])
	for x in range(20, 1181, 40):
		pts.append(Vector2(x, 470.0 + 18.0 * sin(x / 150.0)))
	pts.append(Vector2(1180, 660))
	return pts

static func _ground_name(c: StringName) -> String:
	match c:
		&"blue": return "Sea"
		&"yellow": return "Sand"
		&"brown": return "Soil"
	return "Grass"

static func _r(name: String, color: StringName, pts: PackedVector2Array, details: Array = []) -> Dictionary:
	return {name = name, color = color, poly = pts, details = details}

static func _c(c: StringName, d: StringName) -> StringName:
	return c if c != &"" else d

static func _xf(pts: PackedVector2Array, pos: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(pos + p * s)
	return out

static func _obj(o: Array) -> Array:
	var pos := Vector2(float(o[1]), float(o[2]))
	var s := float(o[3])
	var c: StringName = o[4] if o.size() > 4 else &""
	var out: Array = []
	for p: Dictionary in _parts(o[0], c):
		var det: Array = []
		for l: PackedVector2Array in p.details:
			det.append(_xf(l, pos, s))
		out.append({name = p.name, color = p.color, poly = _xf(p.poly, pos, s), details = det})
	return out


# ───────────────────────── object library (local coordinates, y up = negative) ─────────────────────────

static func _parts(kind: StringName, c: StringName) -> Array:
	match kind:
		&"tree":
			return [_r("Trunk", &"brown", rect(-16, -110, 16, 0)),
				_r("Crown", _c(c, &"green"), ellipse(Vector2(0, -170), 78, 72))]
		&"pine":
			return [_r("Trunk", &"brown", rect(-14, -50, 14, 0)),
				_r("Lower leaves", &"green", tri(Vector2(-95, -40), Vector2(0, -150), Vector2(95, -40))),
				_r("Upper leaves", &"green", tri(Vector2(-68, -110), Vector2(0, -235), Vector2(68, -110)))]
		&"house":
			var w1 := rect(-95, -110, -55, -70)
			var w2 := rect(55, -110, 95, -70)
			return [_r("Wall", _c(c, &"orange"), rect(-110, -130, 110, 0)),
				_r("Roof", &"red", tri(Vector2(-135, -128), Vector2(0, -240), Vector2(135, -128))),
				_r("Door", &"brown", rect(-22, -75, 22, 0)),
				_r("Window", &"blue", w1, [line([-75, -110, -75, -70]), line([-95, -90, -55, -90])]),
				_r("Window", &"blue", w2, [line([75, -110, 75, -70]), line([55, -90, 95, -90])])]
		&"barn":
			return [_r("Wall", _c(c, &"red"), rect(-120, -120, 120, 0)),
				_r("Roof", &"brown", poly([-135, -115, -95, -190, 95, -190, 135, -115])),
				_r("Door", &"yellow", rect(-38, -90, 38, 0),
					[line([-38, -90, 38, 0]), line([38, -90, -38, 0])])]
		&"sun":
			var rays: Array = []
			for i in 12:
				var d := Vector2.from_angle(TAU * i / 12.0)
				rays.append(PackedVector2Array([d * 90.0, d * 122.0]))
			return [_r("Sun", _c(c, &"yellow"), ellipse(Vector2.ZERO, 70, 70), rays)]
		&"flower":
			var petals := PackedVector2Array()
			for i in 60:
				var t := TAU * i / 60.0
				petals.append(Vector2(0, -170) + Vector2.from_angle(t) * 60.0 * (1.0 + 0.3 * cos(5.0 * t)))
			var pc := _c(c, &"red")
			return [_r("Stem", &"green", rect(-8, -150, 8, 0)),
				_r("Petals", pc, petals),
				_r("Centre", &"orange" if pc == &"yellow" else &"yellow", ellipse(Vector2(0, -170), 26, 26))]
		&"fish":
			return [_r("Tail", _c(c, &"orange"), tri(Vector2(70, 0), Vector2(145, -50), Vector2(145, 50))),
				_r("Body", _c(c, &"orange"), ellipse(Vector2.ZERO, 92, 54), [eye(Vector2(-52, -12))])]
		&"boat":
			var sail2 := &"orange" if c == &"yellow" else &"yellow"
			return [_r("Hull", &"brown", poly([-110, 0, 110, 0, 75, 45, -75, 45])),
				_r("Sail", _c(c, &"red"), tri(Vector2(-5, -10), Vector2(-5, -175), Vector2(95, -10)),
					[line([-5, -178, -5, -5])]),
				_r("Small sail", sail2, tri(Vector2(-15, -10), Vector2(-15, -135), Vector2(-85, -10)))]
		&"car":
			return [_r("Body", _c(c, &"red"), poly([-120, -10, -120, -50, -65, -52, -40, -100, 55, -100, 80, -52, 120, -50, 120, -10])),
				_r("Windows", &"blue", poly([-52, -56, -35, -90, 48, -90, 65, -56]), [line([6, -90, 6, -56])]),
				_r("Wheel", &"brown", ellipse(Vector2(-70, -8), 30, 30)),
				_r("Wheel", &"brown", ellipse(Vector2(70, -8), 30, 30))]
		&"bus":
			return [_r("Body", _c(c, &"yellow"), rect(-155, -125, 155, -12)),
				_r("Window", &"blue", rect(-130, -105, -80, -62)),
				_r("Window", &"blue", rect(-45, -105, 5, -62)),
				_r("Window", &"blue", rect(40, -105, 90, -62)),
				_r("Wheel", &"brown", ellipse(Vector2(-90, -12), 32, 32)),
				_r("Wheel", &"brown", ellipse(Vector2(90, -12), 32, 32))]
		&"apple":
			return [_r("Apple", _c(c, &"red"), ellipse(Vector2(0, -62), 66, 62)),
				_r("Stem", &"brown", rect(-7, -168, 7, -112)),
				_r("Leaf", &"green", ellipse(Vector2(32, -150), 36, 16))]
		&"star":
			return [_r("Star", _c(c, &"yellow"), star_poly(100, 42))]
		&"heart":
			return [_r("Heart", _c(c, &"red"), heart_poly(6.5))]
		&"butterfly":
			return [_r("Wing", _c(c, &"orange"), ellipse(Vector2(-58, -30), 56, 72)),
				_r("Wing", _c(c, &"orange"), ellipse(Vector2(58, -30), 56, 72)),
				_r("Lower wing", &"red" if _c(c, &"orange") != &"red" else &"yellow", ellipse(Vector2(-40, 48), 40, 46)),
				_r("Lower wing", &"red" if _c(c, &"orange") != &"red" else &"yellow", ellipse(Vector2(40, 48), 40, 46)),
				_r("Body", &"brown", ellipse(Vector2(0, 0), 14, 88))]
		&"moon":
			var cres: Array = Geometry2D.clip_polygons(ellipse(Vector2.ZERO, 80, 80, 64), ellipse(Vector2(38, -8), 68, 68, 64))
			return [_r("Moon", _c(c, &"yellow"), cres[0])]
		&"rocket":
			return [_r("Flame", &"yellow", tri(Vector2(-22, -4), Vector2(0, 70), Vector2(22, -4))),
				_r("Fin", &"orange", tri(Vector2(-36, -50), Vector2(-90, 8), Vector2(-30, -8))),
				_r("Fin", &"orange", tri(Vector2(36, -50), Vector2(90, 8), Vector2(30, -8))),
				_r("Body", _c(c, &"red"), ellipse(Vector2(0, -100), 44, 102)),
				_r("Window", &"blue", ellipse(Vector2(0, -120), 22, 22))]
		&"mountain":
			return [_r("Mountain", _c(c, &"brown"), tri(Vector2(-160, 0), Vector2(0, -200), Vector2(160, 0)))]
		&"duck":
			return [_r("Tail", &"yellow", tri(Vector2(-65, -62), Vector2(-150, -112), Vector2(-60, -5))),
				_r("Body", &"yellow", ellipse(Vector2(0, -40), 82, 50)),
				_r("Head", &"yellow", ellipse(Vector2(70, -100), 38, 38), [eye(Vector2(80, -108), 6)]),
				_r("Beak", &"orange", tri(Vector2(100, -120), Vector2(160, -96), Vector2(100, -70)))]
		&"mushroom":
			return [_r("Stem", &"yellow", rect(-26, -75, 26, 0)),
				_r("Cap", _c(c, &"red"), half(Vector2(0, -75), 92, 76),
					[eye(Vector2(-35, -115), 11), eye(Vector2(25, -135), 12), eye(Vector2(45, -100), 9)])]
		&"pumpkin":
			return [_r("Pumpkin", _c(c, &"orange"), ellipse(Vector2(0, -58), 94, 62),
					[line([-32, -117, -52, -58, -32, 0]), line([32, -117, 52, -58, 32, 0])]),
				_r("Stem", &"green", rect(-12, -152, 12, -104))]
		&"carrot":
			return [_r("Leaf", &"green", ellipse(Vector2(-22, -225), 20, 44)),
				_r("Leaf", &"green", ellipse(Vector2(22, -225), 20, 44)),
				_r("Leaf", &"green", ellipse(Vector2(0, -238), 18, 52)),
				_r("Carrot", _c(c, &"orange"), tri(Vector2(-40, -190), Vector2(40, -190), Vector2(0, 0)),
					[line([-20, -150, 8, -150]), line([-8, -100, 18, -100]), line([-4, -55, 8, -55])])]
		&"icecream":
			return [_r("Cone", &"orange", tri(Vector2(-54, -115), Vector2(54, -115), Vector2(0, 0)),
					[line([-30, -115, 8, -20]), line([30, -115, -8, -20])]),
				_r("Scoop", _c(c, &"red"), ellipse(Vector2(0, -155), 66, 66))]
		&"balloon":
			return [_r("Balloon", _c(c, &"red"), ellipse(Vector2(0, -170), 64, 80),
				[line([0, -90, 9, -60, -9, -30, 0, 0])])]
		&"kite":
			return [_r("Kite", _c(c, &"red"), poly([0, -230, 78, -150, 0, -50, -78, -150]),
				[line([0, -230, 0, -50]), line([-78, -150, 78, -150]), line([0, -50, -26, -30, 12, -12, -22, 8, 8, 20])])]
		&"umbrella":
			return [_r("Handle", &"brown", rect(-8, -120, 8, -10)),
				_r("Canopy", _c(c, &"red"), half(Vector2(0, -120), 108, 88),
					[line([0, -208, -50, -120]), line([0, -208, 50, -120])])]
		&"snail":
			return [_r("Body", &"green", ellipse(Vector2(0, -18), 108, 22)),
				_r("Head", &"green", ellipse(Vector2(-98, -52), 17, 38),
					[line([-102, -88, -116, -120]), line([-92, -88, -86, -122])]),
				_r("Shell", &"brown", ellipse(Vector2(25, -72), 60, 60), [eye(Vector2(25, -72), 30), eye(Vector2(25, -72), 12)])]
		&"ladybug":
			return [_r("Head", &"brown", ellipse(Vector2(-70, -52), 28, 32)),
				_r("Body", _c(c, &"red"), ellipse(Vector2(0, -52), 74, 62),
					[line([0, -112, 0, 8]), eye(Vector2(36, -82), 10), eye(Vector2(36, -28), 10),
					eye(Vector2(-34, -84), 10), eye(Vector2(-34, -24), 10)])]
		&"turtle":
			return [_r("Leg", &"green", ellipse(Vector2(-58, -6), 28, 20)),
				_r("Leg", &"green", ellipse(Vector2(58, -6), 28, 20)),
				_r("Tail", &"green", tri(Vector2(-90, -34), Vector2(-135, -18), Vector2(-90, -8))),
				_r("Head", &"green", ellipse(Vector2(108, -52), 32, 30), [eye(Vector2(118, -60), 6)]),
				_r("Shell", _c(c, &"brown"), half(Vector2(0, -30), 105, 75),
					[line([0, -105, 0, -30]), line([-55, -30, -40, -85]), line([55, -30, 40, -85])])]
		&"castle":
			var arch := PackedVector2Array([Vector2(-26, 0), Vector2(-26, -80)])
			arch.append_array(half(Vector2(0, -80), 26, 26))
			arch.append(Vector2(26, 0))
			return [_r("Tower", _c(c, &"orange"), rect(-160, -175, -100, 0)),
				_r("Tower", _c(c, &"orange"), rect(100, -175, 160, 0)),
				_r("Wall", _c(c, &"orange"), rect(-110, -115, 110, 0)),
				_r("Roof", &"red", tri(Vector2(-172, -173), Vector2(-130, -240), Vector2(-88, -173))),
				_r("Roof", &"red", tri(Vector2(88, -173), Vector2(130, -240), Vector2(172, -173))),
				_r("Gate", &"brown", arch)]
		&"windmill":
			var hub := Vector2(0, -160)
			var out: Array = [_r("Tower", _c(c, &"orange"), poly([-50, 0, 50, 0, 33, -150, -33, -150])),
				_r("Roof", &"red", tri(Vector2(-52, -146), Vector2(0, -215), Vector2(52, -146)))]
			for i in 4:
				out.append(_r("Blade", &"brown", rot_rect(120, 30, deg_to_rad(45.0 + 90.0 * i), hub)))
			out.append(_r("Hub", &"yellow", ellipse(hub, 18, 18)))
			return out
		&"lighthouse":
			return [_r("Tower", _c(c, &"red"), poly([-42, 0, 42, 0, 26, -190, -26, -190])),
				_r("Stripe", &"yellow", poly([-36, -70, 36, -70, 32, -120, -32, -120])),
				_r("Lamp", &"yellow", rect(-26, -230, 26, -190), [line([0, -230, 0, -190])]),
				_r("Roof", &"red", tri(Vector2(-34, -228), Vector2(0, -272), Vector2(34, -228)))]
		&"tent":
			return [_r("Tent", _c(c, &"red"), tri(Vector2(-125, 0), Vector2(0, -175), Vector2(125, 0))),
				_r("Door", &"brown", tri(Vector2(-34, 0), Vector2(0, -88), Vector2(34, 0)))]
		&"cactus":
			return [_r("Arm", &"green", poly([-24, -70, -72, -70, -72, -135, -50, -135, -50, -98, -24, -98])),
				_r("Arm", &"green", poly([24, -90, 72, -90, 72, -155, 50, -155, 50, -118, 24, -118])),
				_r("Cactus", &"green", rect(-26, -178, 26, 0)),
				_r("Bloom", &"red", ellipse(Vector2(0, -190), 20, 20))]
		&"crab":
			return [_r("Claw", _c(c, &"red"), ellipse(Vector2(-112, -102), 32, 32)),
				_r("Claw", _c(c, &"red"), ellipse(Vector2(112, -102), 32, 32)),
				_r("Body", _c(c, &"red"), ellipse(Vector2(0, -45), 84, 52),
					[line([-70, -30, -105, -5]), line([-50, -8, -75, 14]), line([70, -30, 105, -5]), line([50, -8, 75, 14]),
					eye(Vector2(-26, -50), 8), eye(Vector2(26, -50), 8),
					line([-82, -60, -104, -86]), line([82, -60, 104, -86])])]
		&"cherry":
			return [_r("Cherry", _c(c, &"red"), ellipse(Vector2(-42, -40), 42, 42), [line([-42, -82, 5, -178])]),
				_r("Cherry", _c(c, &"red"), ellipse(Vector2(44, -30), 42, 42), [line([44, -72, 5, -178])]),
				_r("Leaf", &"green", ellipse(Vector2(34, -172), 36, 15))]
		&"rainbow":
			var out2: Array = []
			var cols: Array[StringName] = [&"red", &"orange", &"yellow", &"green"]
			for i in 4:
				out2.append(_r("Band", cols[i], band(240.0 - 34.0 * i, 206.0 - 34.0 * i)))
			return out2
		&"bee":
			return [_r("Wing", &"blue", ellipse(Vector2(-10, -125), 30, 46)),
				_r("Wing", &"blue", ellipse(Vector2(40, -120), 30, 44)),
				_r("Body", &"yellow", ellipse(Vector2(0, -62), 70, 48),
					[line([-20, -108, -20, -16]), line([15, -110, 15, -14]), line([48, -98, 48, -26])]),
				_r("Head", &"brown", ellipse(Vector2(-74, -66), 32, 32), [eye(Vector2(-84, -72), 6)]),
				_r("Sting", &"brown", tri(Vector2(64, -78), Vector2(112, -60), Vector2(64, -42)))]
		&"bird":
			return [_r("Tail", _c(c, &"red"), tri(Vector2(-60, -55), Vector2(-135, -100), Vector2(-128, -22))),
				_r("Body", _c(c, &"red"), ellipse(Vector2(0, -55), 70, 48)),
				_r("Head", _c(c, &"red"), ellipse(Vector2(58, -102), 32, 32), [eye(Vector2(66, -108), 6)]),
				_r("Beak", &"orange", tri(Vector2(84, -112), Vector2(130, -98), Vector2(84, -84))),
				_r("Wing", &"orange", ellipse(Vector2(-8, -55), 42, 26))]
		&"cupcake":
			var fc := _c(c, &"red")
			return [_r("Cup", &"orange", poly([-64, -75, 64, -75, 48, 0, -48, 0]),
					[line([-22, -75, -16, 0]), line([22, -75, 16, 0])]),
				_r("Frosting", fc, ellipse(Vector2(0, -98), 72, 44)),
				_r("Cherry", &"yellow" if fc == &"red" else &"red", ellipse(Vector2(0, -148), 20, 20))]
		&"gift":
			return [_r("Box", _c(c, &"red"), rect(-85, -100, 85, 0)),
				_r("Ribbon", &"yellow", rect(-14, -100, 14, 0)),
				_r("Ribbon", &"yellow", rect(-85, -62, 85, -38)),
				_r("Bow", &"yellow", ellipse(Vector2(-30, -122), 30, 20)),
				_r("Bow", &"yellow", ellipse(Vector2(30, -122), 30, 20))]
		&"pond":
			return [_r("Water", _c(c, &"blue"), ellipse(Vector2.ZERO, 115, 36))]
		&"weed":
			return [_r("Seaweed", &"green", ellipse(Vector2(0, -75), 24, 80), [line([0, -150, 8, -100, -8, -50, 0, -5])])]
		&"planet":
			return [_r("Planet", _c(c, &"orange"), ellipse(Vector2.ZERO, 90, 90), [loop(ellipse(Vector2.ZERO, 150, 32))])]
		&"fence":
			var out3: Array = []
			for x in [-105, -35, 35, 105]:
				out3.append(_r("Picket", &"brown", poly([x - 24, 0, x - 24, -90, x, -112, x + 24, -90, x + 24, 0])))
			return out3
		&"basket":
			return [_r("Basket", &"brown", poly([-122, -82, 122, -82, 96, 0, -96, 0]),
				[line([-112, -55, 112, -55]), line([-104, -28, 104, -28]), line([-40, -82, -32, 0]), line([40, -82, 32, 0])])]
		&"hotair":
			var env := ellipse(Vector2(0, -210), 96, 106)
			var stripe: Array = Geometry2D.intersect_polygons(env, rect(-32, -330, 32, -100))
			return [_r("Balloon", _c(c, &"red"), env),
				_r("Stripe", &"yellow" if _c(c, &"red") != &"yellow" else &"orange", stripe[0]),
				_r("Basket", &"brown", rect(-34, -62, 34, -26), [line([-70, -125, -34, -62]), line([70, -125, 34, -62])])]
	push_warning("Unknown object kind: %s" % kind)
	return []
