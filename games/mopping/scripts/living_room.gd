class_name LivingRoom
extends Node3D
## Furnishes the room (sofa, coffee table, TV stand, toy basket, plant, windows,
## curtains, baseboards) from primitives. Exposes the furniture footprints as
## `obstacles` (world XZ rects) so the player, mop and the cat and mouse can avoid them.

var room := Vector2(7.0, 5.0)
var obstacles: Array[Rect2] = []


# ---------------------------------------------------------------- obstacle helpers
static func push_out(p: Vector2, rects: Array, margin: float) -> Vector2:
	for r in rects:
		var e: Rect2 = (r as Rect2).grow(margin)
		if e.has_point(p):
			var dl := p.x - e.position.x
			var dr := e.end.x - p.x
			var dt := p.y - e.position.y
			var db := e.end.y - p.y
			var m := minf(minf(dl, dr), minf(dt, db))
			if m == dl:
				p.x = e.position.x
			elif m == dr:
				p.x = e.end.x
			elif m == dt:
				p.y = e.position.y
			else:
				p.y = e.end.y
	return p


static func blocked(p: Vector2, rects: Array, margin := 0.0) -> bool:
	for r in rects:
		if (r as Rect2).grow(margin).has_point(p):
			return true
	return false


# ---------------------------------------------------------------- build
func _ready() -> void:
	_build()


## Override in subclasses (KitchenRoom, BedroomRoom) to furnish a different room.
func _build() -> void:
	var hx := room.x * 0.5
	var hz := room.y * 0.5
	_baseboards(hx, hz)
	_sofa(Vector3(-1.6, 0.0, -hz + 0.5))
	_coffee_table(Vector3(-1.5, 0.0, -0.6))
	_side_table(Vector3(-0.15, 0.0, -hz + 0.35))
	_tv_stand(Vector3(hx - 0.3, 0.0, -0.3))
	_toy_basket(Vector3(-hx + 0.5, 0.0, 0.9))
	_plant(Vector3(hx - 0.4, 0.0, -hz + 0.4))
	_window(Vector3(1.9, 1.55, -hz), 0.0, Vector2(1.6, 1.4))
	_window(Vector3(hx, 1.55, 1.6), -90.0, Vector2(1.2, 1.4))


func _obstacle(center: Vector2, size: Vector2) -> void:
	obstacles.append(Rect2(center - size * 0.5, size))


func _mat(c: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material,
		rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, r_top: float, r_bot: float, h: float, pos: Vector3,
		mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = 20
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sphere(parent: Node3D, r: float, pos: Vector3, mat: Material,
		sc := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	mi.mesh = s
	mi.material_override = mat
	mi.position = pos
	mi.scale = sc
	parent.add_child(mi)
	return mi


func _root(pos: Vector3, yaw := 0.0) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = yaw
	add_child(n)
	return n


func _baseboards(hx: float, hz: float) -> void:
	var m := _mat(Color(0.97, 0.96, 0.93), 0.5)
	_box(self, Vector3(room.x, 0.12, 0.03), Vector3(0, 0.06, -hz + 0.015), m)
	_box(self, Vector3(0.03, 0.12, room.y), Vector3(-hx + 0.015, 0.06, 0), m)
	_box(self, Vector3(0.03, 0.12, room.y), Vector3(hx - 0.015, 0.06, 0), m)


# ---------------------------------------------------------------- furniture
func _sofa(pos: Vector3) -> void:
	var r := _root(pos)
	var fabric := _mat(Color(0.78, 0.70, 0.58), 1.0)
	var seat := _mat(Color(0.82, 0.74, 0.62), 1.0)
	var leg := _mat(Color(0.2, 0.13, 0.08), 0.5)
	_box(r, Vector3(2.2, 0.26, 0.9), Vector3(0, 0.26, 0), fabric)                 # base
	_box(r, Vector3(2.2, 0.5, 0.22), Vector3(0, 0.63, -0.34), fabric)             # backrest
	for sx in [-1.0, 1.0]:
		_box(r, Vector3(0.2, 0.52, 0.9), Vector3(sx * 1.0, 0.5, 0), fabric)       # arms
	for x in [-0.7, 0.0, 0.7]:
		_box(r, Vector3(0.62, 0.14, 0.62), Vector3(x, 0.46, 0.08), seat)          # seat cushions
		_box(r, Vector3(0.62, 0.38, 0.14), Vector3(x, 0.7, -0.18), seat, Vector3(-10, 0, 0))
	for p in [[-1.0, -0.5], [1.0, -0.5], [-1.0, 0.4], [1.0, 0.4]]:
		_box(r, Vector3(0.06, 0.1, 0.06), Vector3(p[0], 0.05, p[1]), leg)
	_box(r, Vector3(0.38, 0.38, 0.12), Vector3(-0.8, 0.74, -0.04),
		_mat(Color(0.85, 0.65, 0.2), 1.0), Vector3(0, 10, 18))                      # pillows
	_box(r, Vector3(0.38, 0.36, 0.12), Vector3(0.75, 0.73, -0.04),
		_mat(Color(0.35, 0.38, 0.45), 1.0), Vector3(0, -12, -14))
	_box(r, Vector3(0.5, 0.04, 0.42), Vector3(1.0, 0.78, 0.0),
		_mat(Color(0.85, 0.5, 0.5), 1.0), Vector3(0, 0, 8))                         # throw blanket
	_obstacle(Vector2(pos.x, pos.z), Vector2(2.2, 0.9))


func _coffee_table(pos: Vector3) -> void:
	var r := _root(pos)
	var wood := _mat(Color(0.34, 0.2, 0.11), 0.45)
	_box(r, Vector3(1.2, 0.05, 0.6), Vector3(0, 0.42, 0), wood)
	_box(r, Vector3(1.1, 0.03, 0.5), Vector3(0, 0.16, 0), wood)
	for x in [-0.55, 0.55]:
		for z in [-0.25, 0.25]:
			_box(r, Vector3(0.05, 0.4, 0.05), Vector3(x, 0.2, z), wood)
	var cols := [Color(0.85, 0.25, 0.3), Color(0.95, 0.85, 0.3),
		Color(0.3, 0.55, 0.8), Color(0.9, 0.9, 0.88)]
	for i in 4:                                                          # stack of magazines
		_box(r, Vector3(0.28, 0.012, 0.21), Vector3(0.3, 0.456 + i * 0.013, 0.05),
			_mat(cols[i], 0.6), Vector3(0, i * 9 - 10, 0))
	_box(r, Vector3(0.3, 0.008, 0.22), Vector3(-0.25, 0.449, -0.05),
		_mat(Color(0.9, 0.5, 0.55), 0.6), Vector3(0, 25, 0))
	_box(r, Vector3(0.26, 0.008, 0.2), Vector3(0.0, 0.18, 0.0),
		_mat(Color(0.3, 0.6, 0.45), 0.6), Vector3(0, -15, 0))
	_box(r, Vector3(0.24, 0.01, 0.18), Vector3(-0.3, 0.18, 0.08),
		_mat(Color(0.8, 0.8, 0.85), 0.6), Vector3(0, 12, 0))
	_obstacle(Vector2(pos.x, pos.z), Vector2(1.2, 0.6))


func _side_table(pos: Vector3) -> void:
	var r := _root(pos)
	var wood := _mat(Color(0.3, 0.18, 0.1), 0.45)
	_cyl(r, 0.22, 0.22, 0.04, Vector3(0, 0.55, 0), wood)
	_cyl(r, 0.03, 0.03, 0.5, Vector3(0, 0.28, 0), wood)
	_cyl(r, 0.16, 0.16, 0.03, Vector3(0, 0.02, 0), wood)
	_cyl(r, 0.06, 0.05, 0.22, Vector3(0, 0.68, 0), _mat(Color(0.95, 0.94, 0.9), 0.2))   # vase
	_sphere(r, 0.1, Vector3(0, 0.86, 0), _mat(Color(0.35, 0.6, 0.3), 0.9), Vector3(1, 0.8, 1))
	_obstacle(Vector2(pos.x, pos.z), Vector2(0.45, 0.45))


func _tv_stand(pos: Vector3) -> void:
	var r := _root(pos)
	var wood := _mat(Color(0.28, 0.17, 0.1), 0.5)
	var door := _mat(Color(0.2, 0.12, 0.07), 0.4)
	_box(r, Vector3(0.5, 0.5, 2.0), Vector3(0, 0.25, 0), wood)
	_box(r, Vector3(0.02, 0.4, 0.9), Vector3(-0.25, 0.25, -0.5), door)
	_box(r, Vector3(0.02, 0.4, 0.9), Vector3(-0.25, 0.25, 0.5), door)
	_box(r, Vector3(0.18, 0.04, 0.5), Vector3(0, 0.52, 0), _mat(Color(0.05, 0.05, 0.06), 0.3))
	_box(r, Vector3(0.05, 0.72, 1.25), Vector3(0.05, 0.92, 0), _mat(Color(0.02, 0.02, 0.03), 0.12))
	_box(r, Vector3(0.02, 0.66, 1.19), Vector3(0.0, 0.92, 0), _mat(Color(0.03, 0.04, 0.07), 0.05, 0.4))
	_box(r, Vector3(0.2, 0.3, 0.2), Vector3(0, 0.65, 0.8), _mat(Color(0.08, 0.08, 0.09), 0.5))
	_box(r, Vector3(0.25, 0.1, 0.3), Vector3(0, 0.55, -0.85), _mat(Color(0.1, 0.1, 0.11), 0.4))
	_obstacle(Vector2(pos.x, pos.z), Vector2(0.5, 2.0))


func _toy_basket(pos: Vector3) -> void:
	var r := _root(pos)
	var straw := _mat(Color(0.66, 0.5, 0.28), 1.0)
	_cyl(r, 0.34, 0.27, 0.45, Vector3(0, 0.225, 0), straw)
	_cyl(r, 0.31, 0.31, 0.01, Vector3(0, 0.43, 0), _mat(Color(0.12, 0.08, 0.05), 1.0))
	_sphere(r, 0.09, Vector3(-0.1, 0.5, 0.05), _mat(Color(0.9, 0.3, 0.2), 0.5))
	_box(r, Vector3(0.14, 0.14, 0.14), Vector3(0.1, 0.5, -0.05),
		_mat(Color(0.95, 0.8, 0.2), 0.5), Vector3(20, 30, 10))
	_cyl(r, 0.04, 0.05, 0.28, Vector3(0.0, 0.62, 0.1), _mat(Color(0.25, 0.7, 0.3), 0.3))
	_box(r, Vector3(0.16, 0.12, 0.16), Vector3(-0.05, 0.52, -0.12),
		_mat(Color(0.2, 0.45, 0.85), 0.5), Vector3(0, 40, 15))
	# toy car + blocks on the floor nearby
	var car := _root(pos + Vector3(0.75, 0.0, 0.35), 25)
	_box(car, Vector3(0.22, 0.06, 0.11), Vector3(0, 0.07, 0), _mat(Color(0.85, 0.1, 0.1), 0.4))
	_box(car, Vector3(0.11, 0.05, 0.1), Vector3(-0.01, 0.12, 0), _mat(Color(0.8, 0.9, 1.0), 0.2))
	var wheel := _mat(Color(0.05, 0.05, 0.05), 0.8)
	for p in [[-0.07, 0.06], [0.07, 0.06], [-0.07, -0.06], [0.07, -0.06]]:
		var w := _cyl(car, 0.03, 0.03, 0.025, Vector3(p[0], 0.03, p[1]), wheel)
		w.rotation_degrees.x = 90
	var block_cols := [Color(0.9, 0.3, 0.3), Color(0.3, 0.6, 0.9), Color(0.95, 0.8, 0.2)]
	for i in 3:
		_box(self, Vector3(0.08, 0.08, 0.08),
			pos + Vector3(0.55 + i * 0.13, 0.04, -0.45 + i * 0.1),
			_mat(block_cols[i], 0.5), Vector3(0, 20 + i * 25, 0))
	_obstacle(Vector2(pos.x, pos.z), Vector2(0.7, 0.7))


func _plant(pos: Vector3) -> void:
	var r := _root(pos)
	_cyl(r, 0.2, 0.15, 0.35, Vector3(0, 0.175, 0), _mat(Color(0.7, 0.38, 0.25), 0.8))
	_cyl(r, 0.18, 0.18, 0.02, Vector3(0, 0.34, 0), _mat(Color(0.2, 0.13, 0.08), 1.0))
	var leaf := _mat(Color(0.2, 0.5, 0.22), 0.7)
	for i in 7:
		var a := float(i) / 7.0 * TAU
		_sphere(r, 0.14, Vector3(cos(a) * 0.16, 0.6 + (i % 3) * 0.18, sin(a) * 0.16),
			leaf, Vector3(0.8, 1.6, 0.8))
	_obstacle(Vector2(pos.x, pos.z), Vector2(0.45, 0.45))


## Window centred at `pos`; the node's +Z faces into the room.
func _window(pos: Vector3, yaw: float, size: Vector2, curtains := true) -> void:
	var r := _root(pos, yaw)
	var white := _mat(Color(0.97, 0.97, 0.95), 0.4)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1, 1, 1)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.96, 0.85)
	glow.emission_energy_multiplier = 2.6
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var pane := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	pane.mesh = q
	pane.material_override = glow
	pane.position.z = 0.012
	r.add_child(pane)
	var t := 0.06
	_box(r, Vector3(size.x + 2 * t, t, 0.07), Vector3(0, size.y * 0.5 + t * 0.5, 0.035), white)
	_box(r, Vector3(size.x + 2 * t, t, 0.07), Vector3(0, -size.y * 0.5 - t * 0.5, 0.035), white)
	_box(r, Vector3(t, size.y, 0.07), Vector3(-size.x * 0.5 - t * 0.5, 0, 0.035), white)
	_box(r, Vector3(t, size.y, 0.07), Vector3(size.x * 0.5 + t * 0.5, 0, 0.035), white)
	_box(r, Vector3(0.04, size.y, 0.05), Vector3(0, 0, 0.03), white)                 # mullions
	_box(r, Vector3(size.x, 0.04, 0.05), Vector3(0, size.y * 0.1, 0.03), white)
	_box(r, Vector3(size.x + 0.3, 0.05, 0.2), Vector3(0, -size.y * 0.5 - 0.08, 0.1), white)   # sill
	if not curtains:
		return
	var cur := _mat(Color(0.93, 0.88, 0.78), 1.0)
	for sx in [-1.0, 1.0]:
		for k in 3:
			_box(r, Vector3(0.14, size.y + 0.9, 0.05),
				Vector3(sx * (size.x * 0.5 + 0.2 + k * 0.1), -0.05, 0.13 + (k % 2) * 0.04), cur)
	var rod := _cyl(r, 0.015, 0.015, size.x + 1.2,
		Vector3(0, size.y * 0.5 + 0.5, 0.15), _mat(Color(0.3, 0.25, 0.2), 0.4, 0.6))
	rod.rotation_degrees.z = 90
