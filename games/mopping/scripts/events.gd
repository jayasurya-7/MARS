class_name RoomEvents
extends Node
## Random things that happen while you mop, so no two sessions are the same:
##  - the dog runs through with muddy paws (re-dirties the floor)
##  - a breeze blows leaves in through the window (sweep them up)
##  - a glass of juice spills and spreads (mop it before it grows)

signal announce(text: String)
signal points(amount: int, pos: Vector3)

var room := Vector2(7.0, 5.0)
var painter: FloorPainter
var mop: MopController
var obstacles: Array[Rect2] = []
var active := true
var first_delay := 14.0
var min_gap := 18.0
var max_gap := 30.0

var _timer := 14.0
var _rng := RandomNumberGenerator.new()
var _last := -1


func _ready() -> void:
	_rng.randomize()
	_timer = first_delay


func _process(delta: float) -> void:
	if not active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = _rng.randf_range(min_gap, max_gap)
		_fire_random()


## Removes anything still on the floor (used when changing rooms).
func clear_all() -> void:
	for c in get_children():
		c.queue_free()
	_timer = first_delay


func _fire_random() -> void:
	var pick := _rng.randi() % 3
	if pick == _last:
		pick = (pick + 1) % 3
	_last = pick
	match pick:
		0: _dog()
		1: _breeze()
		2: _spill()


func _free_spot(margin := 0.4) -> Vector3:
	var hx := room.x * 0.5 - 0.5
	var hz := room.y * 0.5 - 0.5
	for _i in 30:
		var p := Vector3(_rng.randf_range(-hx, hx), 0.0, _rng.randf_range(-hz, hz))
		if LivingRoom.blocked(Vector2(p.x, p.z), obstacles, margin):
			continue
		if mop != null and p.distance_to(mop.global_position) < 1.0:
			continue
		return p
	return Vector3(0.5, 0.0, 1.3)


# ---------------------------------------------------------------- events
func _dog() -> void:
	announce.emit("The dog ran in with muddy paws!")
	var d := Dog.new()
	d.painter = painter
	d.lane_z = 1.55
	var from_left := _rng.randf() < 0.5
	var edge := room.x * 0.5 - 0.3
	d.start_x = -edge if from_left else edge
	d.end_x = edge if from_left else -edge
	add_child(d)


func _breeze() -> void:
	announce.emit("A breeze blew leaves in - sweep them up!")
	for i in 5:
		var leaf := Leaf.new()
		leaf.painter = painter
		leaf.mop = mop
		leaf.events = self
		leaf.start = Vector3(_rng.randf_range(0.8, 3.0), 1.7, -room.y * 0.5 + 0.2)
		leaf.target = _free_spot(0.3)
		leaf.delay = i * 0.25
		add_child(leaf)


func _spill() -> void:
	announce.emit("Juice spill! Mop it before it spreads!")
	var p := Puddle.new()
	p.painter = painter
	p.mop = mop
	p.events = self
	p.position = _free_spot(0.5)
	add_child(p)


# ---------------------------------------------------------------- leaf
class Leaf extends Node3D:
	var painter: FloorPainter
	var mop: MopController
	var events: RoomEvents
	var start := Vector3.ZERO
	var target := Vector3.ZERO
	var delay := 0.0
	var _t := 0.0
	var _landed := false
	var _mesh: MeshInstance3D

	func _ready() -> void:
		var m := StandardMaterial3D.new()
		var cols := [Color(0.55, 0.38, 0.12), Color(0.7, 0.5, 0.15), Color(0.35, 0.5, 0.15)]
		m.albedo_color = cols[randi() % cols.size()]
		m.roughness = 0.9
		var b := BoxMesh.new()
		b.size = Vector3(0.13, 0.008, 0.08)
		_mesh = MeshInstance3D.new()
		_mesh.mesh = b
		_mesh.material_override = m
		add_child(_mesh)
		position = start
		visible = false

	func _process(delta: float) -> void:
		_t += delta
		if _t < delay:
			return
		visible = true
		if not _landed:
			var k := clampf((_t - delay) / 1.8, 0.0, 1.0)
			var pos := start.lerp(target, k)
			pos.y = lerpf(start.y, 0.01, k * k)
			pos.x += sin(k * 9.0) * 0.12 * (1.0 - k)       # flutter
			position = pos
			rotation.y += delta * 4.0
			rotation.z = sin(k * 8.0) * 0.5 * (1.0 - k)
			if k >= 1.0:
				_landed = true
				rotation.z = 0.0
				if painter != null:
					painter.dirty_spot(Vector3(position.x, 0.0, position.z), 0.2)
			return
		if mop != null:
			var d := mop.head.global_position - global_position
			d.y = 0.0
			if d.length() < 0.38:
				events.points.emit(25, global_position)
				queue_free()


# ---------------------------------------------------------------- puddle
class Puddle extends Node3D:
	var painter: FloorPainter
	var mop: MopController
	var events: RoomEvents
	var radius := 0.12
	var max_radius := 0.6
	var _t := 0.0
	var _next_dirty := 0.0
	var _mat: StandardMaterial3D
	var _disc: MeshInstance3D
	var _gone := false

	func _ready() -> void:
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = Color(0.95, 0.55, 0.1, 0.7)
		_mat.roughness = 0.05
		_mat.metallic = 0.2
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var c := CylinderMesh.new()
		c.top_radius = 1.0
		c.bottom_radius = 1.0
		c.height = 0.004
		c.radial_segments = 32
		_disc = MeshInstance3D.new()
		_disc.mesh = c
		_disc.material_override = _mat
		_disc.position.y = 0.007
		add_child(_disc)
		# A tipped glass next to the puddle.
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color(0.8, 0.9, 1.0, 0.4)
		gm.roughness = 0.05
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var gc := CylinderMesh.new()
		gc.top_radius = 0.045
		gc.bottom_radius = 0.035
		gc.height = 0.12
		var glass := MeshInstance3D.new()
		glass.mesh = gc
		glass.material_override = gm
		glass.position = Vector3(0.18, 0.04, 0.1)
		glass.rotation_degrees = Vector3(0, 0, 88)
		add_child(glass)

	func _process(delta: float) -> void:
		if _gone:
			return
		_t += delta
		radius = minf(radius + delta * 0.08, max_radius)         # keeps spreading
		_disc.scale = Vector3(radius, 1.0, radius)
		if _t >= _next_dirty and painter != null:
			_next_dirty = _t + 0.6
			painter.dirty_spot(Vector3(position.x, 0.0, position.z), radius)
		if mop != null:
			var d := mop.head.global_position - global_position
			d.y = 0.0
			if d.length() < radius + 0.25:
				_gone = true
				events.points.emit(100, global_position)
				var tw := create_tween()
				tw.tween_property(_mat, "albedo_color:a", 0.0, 0.4)
				tw.tween_callback(queue_free)
