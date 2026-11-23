class_name Dog
extends Node3D
## A muddy dog that trots across the room and re-dirties the floor with paw prints.

signal finished(d: Dog)

var painter: FloorPainter
var start_x := -3.2
var end_x := 3.2
var lane_z := 1.55
var speed := 1.9

var _t := 0.0
var _since_print := 0.0
var _side := 1.0
var _legs: Array[Node3D] = []
var _tail: Node3D
var _dir := 1.0


func _ready() -> void:
	_dir = signf(end_x - start_x)
	position = Vector3(start_x, 0.0, lane_z)
	rotation.y = -PI * 0.5 * _dir      # model faces -Z; rotate to face travel direction
	_build()


func _build() -> void:
	var fur := StandardMaterial3D.new()
	fur.albedo_color = Color(0.86, 0.6, 0.32)
	fur.roughness = 1.0
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.08, 0.06)
	dark.roughness = 0.5
	var mud := StandardMaterial3D.new()
	mud.albedo_color = Color(0.25, 0.17, 0.1)
	mud.roughness = 1.0

	var cream := StandardMaterial3D.new()
	cream.albedo_color = Color(0.98, 0.9, 0.75)
	cream.roughness = 1.0
	var brown := StandardMaterial3D.new()
	brown.albedo_color = Color(0.5, 0.3, 0.16)
	brown.roughness = 1.0
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.85, 0.15, 0.2)
	red.roughness = 0.5
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(1.0, 0.8, 0.2)
	gold.metallic = 0.8
	gold.roughness = 0.3
	var pink := StandardMaterial3D.new()
	pink.albedo_color = Color(1.0, 0.5, 0.58)
	pink.roughness = 0.5
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(1, 1, 1)
	white.roughness = 0.2

	_sph(0.16, Vector3(0, 0.4, 0.02), fur, Vector3(0.95, 0.95, 1.9))                      # body
	_sph(0.1, Vector3(0, 0.46, 0.14), brown, Vector3(1.2, 0.5, 1.5))                      # saddle patch
	_sph(0.12, Vector3(0, 0.36, -0.2), cream, Vector3(0.9, 0.9, 0.9))                     # chest
	_sph(0.15, Vector3(0, 0.55, -0.34), fur, Vector3(1.0, 1.0, 1.0))                      # head
	_sph(0.085, Vector3(0, 0.5, -0.49), cream, Vector3(1.0, 0.8, 1.2))                    # snout
	_sph(0.03, Vector3(0, 0.53, -0.58), dark, Vector3(1.2, 0.9, 1.0))                     # nose
	_sph(0.03, Vector3(0, 0.45, -0.52), pink, Vector3(0.9, 0.5, 1.5))                     # tongue
	_cyl_on(self, 0.14, 0.14, 0.035, red, Vector3(0, 0.46, -0.24))                         # collar
	_sph(0.022, Vector3(0, 0.38, -0.36), gold)                                            # tag
	for sx in [-1.0, 1.0]:
		var ear := _sph(0.07, Vector3(sx * 0.15, 0.55, -0.3), brown, Vector3(0.45, 1.5, 0.9))   # floppy ears
		ear.rotation_degrees.z = sx * 12.0
		_sph(0.04, Vector3(sx * 0.065, 0.59, -0.45), white, Vector3(1.0, 1.1, 0.6))        # eyes
		_sph(0.026, Vector3(sx * 0.065, 0.59, -0.47), dark, Vector3(1.0, 1.1, 0.6))
		_sph(0.008, Vector3(sx * 0.058, 0.6, -0.485), white)
		_sph(0.012, Vector3(sx * 0.065, 0.66, -0.43), brown, Vector3(2.0, 0.6, 0.8))       # brows
	for p in [[-0.1, -0.2], [0.1, -0.2], [-0.1, 0.22], [0.1, 0.22]]:
		var leg := Node3D.new()
		leg.position = Vector3(p[0], 0.27, p[1])
		add_child(leg)
		_sph_on(leg, 0.075, Vector3(0, 0.01, 0), fur, Vector3(1, 1.2, 1.3))                # thigh / shoulder
		_cyl_on(leg, 0.055, 0.042, 0.27, fur, Vector3(0, -0.135, 0))
		var paw := _sph_on(leg, 0.055, Vector3(0, -0.265, -0.015), mud, Vector3(1, 0.65, 1.3))
		paw.name = "Paw"
		_legs.append(leg)
	_tail = Node3D.new()
	_tail.position = Vector3(0, 0.5, 0.3)
	add_child(_tail)
	for i in 14:
		var t := float(i) / 13.0
		_sph_on(_tail, 0.04 - t * 0.016, Vector3(0, 0.03 + t * 0.2, 0.03 + sin(t * 2.2) * 0.1), fur if i < 12 else cream)


func _cyl_on(parent: Node3D, rt: float, rb: float, h: float, mat: Material, pos: Vector3) -> void:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	m.mesh = c
	m.material_override = mat
	m.position = pos
	parent.add_child(m)


func _mesh(mesh: Mesh, size: Vector3, pos: Vector3, mat: Material) -> void:
	if mesh is BoxMesh:
		(mesh as BoxMesh).size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


func _sph(r: float, pos: Vector3, mat: Material, sc := Vector3.ONE) -> MeshInstance3D:
	return _sph_on(self, r, pos, mat, sc)


func _sph_on(parent: Node3D, r: float, pos: Vector3, mat: Material, sc := Vector3.ONE) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.material_override = mat
	mi.position = pos
	mi.scale = sc
	parent.add_child(mi)
	return mi


func _process(delta: float) -> void:
	_t += delta
	position.x += _dir * speed * delta
	position.y = absf(sin(_t * 12.0)) * 0.03
	for i in _legs.size():
		_legs[i].rotation.x = sin(_t * 12.0 + (0.0 if i % 3 == 0 else PI)) * 0.7
	_tail.rotation.z = sin(_t * 14.0) * 0.5

	# Paw prints: alternate left / right, re-dirty the mask and leave a fading mark.
	_since_print += speed * delta
	if _since_print >= 0.38:
		_since_print = 0.0
		_side = -_side
		var p := Vector3(position.x, 0.0, lane_z + _side * 0.09)
		if painter != null:
			painter.dirty_spot(p, 0.11)
		_visible_print(p)

	if (_dir > 0.0 and position.x >= end_x) or (_dir < 0.0 and position.x <= end_x):
		finished.emit(self)
		queue_free()


func _visible_print(p: Vector3) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.22, 0.14, 0.08, 0.9)
	m.roughness = 1.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var pad := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.05
	c.bottom_radius = 0.05
	c.height = 0.003
	pad.mesh = c
	pad.material_override = m
	get_parent().add_child(pad)
	pad.global_position = p + Vector3(0, 0.007, 0)
	for k in 3:    # toes
		var toe := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.02
		tc.bottom_radius = 0.02
		tc.height = 0.003
		toe.mesh = tc
		toe.material_override = m
		pad.add_child(toe)
		toe.position = Vector3((k - 1) * 0.045, 0.0, -0.06 - (0.012 if k == 1 else 0.0))
	var tw := pad.create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(m, "albedo_color:a", 0.0, 3.0)
	tw.tween_callback(pad.queue_free)
