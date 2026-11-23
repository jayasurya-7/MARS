class_name ChasePair
extends Node3D
## An original cat-and-mouse pair. The cat chases the mouse around the room; when it
## catches up they tussle in a cloud of dust, then split and the chase starts again.
## They leave mess (dust piles) for the player to mop up.

signal dropped(pos: Vector3)       # a pile of dust should be created here
signal tussle(pos: Vector3)        # the fight just started

var bounds := Vector2(3.0, 2.0)
var obstacles: Array[Rect2] = []
var level := 1
var dust_rate := 1.0         # 0 = no dust, 1 = normal, 4 = lots

var _cat: Node3D
var _mouse: Node3D
var _cat_legs: Array[Node3D] = []
var _mouse_legs: Array[Node3D] = []
var _cat_tail: Node3D
var _mouse_tail: Node3D
var _cat_pos := Vector2(-2.0, 1.5)
var _mouse_pos := Vector2(1.0, 1.5)
var _mouse_target := Vector2.ZERO
var _retarget := 0.0
var _fight_t := 0.0
var _fight_center := Vector2.ZERO
var _cat_rest := 0.0
var _boost := 0.0
var _stumble := 6.0
var _drop_timer := 2.0
var _t := 0.0
var _cat_yaw := 0.0
var _mouse_yaw := 0.0
## Set to true to use the .glb models (static meshes: they hop and lean, limbs do not move).
const USE_GLB_MODELS := false
const TOM_PATH := "res://games/mopping/tom_-_tom_and_jerry.glb"
const JERRY_PATH := "res://games/mopping/jerry_-_tom_and_jerry.glb"
const TOM_HEIGHT := 0.75       # metres tall in the room
const JERRY_HEIGHT := 0.4
## If a model walks backwards, set its flip to true.
const FLIP_TOM := false
const FLIP_JERRY := false

var _cat_margin := 0.2         # how close the cat may get to furniture
var _catch_dist := 0.45        # distance at which the chase turns into a fight
var _detour_t := 0.0
var _detour_p := Vector2.ZERO
var _stuck := 0.0
var _cloud: CPUParticles3D
var _rng := RandomNumberGenerator.new()
var _recent: Array[Vector2] = []     # places already used, so new spots are spread around the room


func _ready() -> void:
	_rng.randomize()
	_build_cat()
	_build_mouse()
	_cloud = _make_cloud()
	add_child(_cloud)
	_cat_pos = _free_point()
	_mouse_pos = _free_point()
	_pick_target()
	_place()


# ---------------------------------------------------------------- behaviour
func _process(delta: float) -> void:
	_t += delta
	if _fight_t > 0.0:
		_fight(delta)
		return

	# --- mouse: wanders, runs away when the cat is close
	_retarget -= delta
	_stumble -= delta
	var to_cat := _cat_pos - _mouse_pos
	var m_speed := 1.5 + 0.08 * level
	if _boost > 0.0:
		_boost -= delta
		m_speed *= 1.5
	if _stumble < 0.0:                         # now and then the mouse trips, so the cat can catch it
		if _stumble < -1.8:
			_stumble = _rng.randf_range(6.0, 10.0)
		m_speed *= 0.45
	if to_cat.length() < 1.5 and _cat_rest <= 0.0:
		_mouse_target = _flee_point(to_cat)
		_retarget = _rng.randf_range(0.5, 1.0)
	elif _retarget <= 0.0:
		_pick_target()
	_mouse_pos = _step(_mouse_pos, _mouse_target, m_speed * delta, 0.12)
	_face(_mouse, _mouse_pos, _mouse_target, true, delta)

	# --- cat: chases (or recovers after a fight)
	var c_speed := 1.35 + 0.08 * level
	if _cat_rest > 0.0:
		_cat_rest -= delta
	else:
		var goal := _mouse_pos
		if _detour_t > 0.0:
			_detour_t -= delta
			goal = _detour_p
		var before := _cat_pos
		_cat_pos = _step(_cat_pos, goal, c_speed * delta, _cat_margin)
		_face(_cat, _cat_pos, goal, false, delta)
		# Stuck behind furniture? Take a detour through open floor.
		if (_cat_pos - before).length() < c_speed * delta * 0.3:
			_stuck += delta
			if _stuck > 0.8:
				_stuck = 0.0
				_detour_p = _free_point()
				_detour_t = 1.5
		else:
			_stuck = 0.0
	if _cat_pos.distance_to(_mouse_pos) < _catch_dist and _cat_rest <= 0.0:
		_start_fight()
		return

	# --- crumbs the mouse drops while running
	_drop_timer -= delta * dust_rate          # higher rate = crumbs come sooner
	if _drop_timer <= 0.0:
		_drop_timer = _rng.randf_range(6.0, 9.0)
		if dust_rate >= 0.05:
			dropped.emit(Vector3(_mouse_pos.x, 0.0, _mouse_pos.y))

	_animate(delta)
	_place()


func _start_fight() -> void:
	_fight_t = _rng.randf_range(0.8, 1.6)
	_fight_center = (_cat_pos + _mouse_pos) * 0.5
	_remember(_fight_center)
	_remember(_fight_center)
	_cloud.position = Vector3(_fight_center.x, 0.25, _fight_center.y)
	_cloud.restart()
	_cloud.emitting = true
	var c := Vector3(_fight_center.x, 0.0, _fight_center.y)
	tussle.emit(c)
	for i in (0 if dust_rate < 0.05 else maxi(1, roundi(1.0 * dust_rate))):   # the scuffle knocks dust everywhere
		var a := _rng.randf() * TAU
		var q := LivingRoom.push_out(
			_fight_center + Vector2(cos(a), sin(a)) * _rng.randf_range(0.2, 0.5), obstacles, 0.1)
		dropped.emit(Vector3(q.x, 0.0, q.y))


func _fight(delta: float) -> void:
	_fight_t -= delta
	_cat.position = Vector3(_fight_center.x + 0.12, 0.05 + absf(sin(_t * 18.0)) * 0.1, _fight_center.y)
	_mouse.position = Vector3(_fight_center.x - 0.12, 0.03 + absf(sin(_t * 22.0)) * 0.12, _fight_center.y)
	_cat.rotation.y += delta * 13.0
	_mouse.rotation.y -= delta * 17.0
	_cat_tail.rotation.z = sin(_t * 30.0) * 0.9
	_mouse_tail.rotation.z = sin(_t * 36.0) * 0.9
	if _fight_t <= 0.0:
		# Mouse escapes, cat is dazed for a moment.
		var away := (_mouse_pos - _cat_pos)
		if away.length() < 0.01:
			away = Vector2.RIGHT
		away = away.rotated(_rng.randf_range(-1.2, 1.2))
		_mouse_pos = _clamp_point(_fight_center + away.normalized() * 0.7)
		_cat_pos = _clamp_point(_fight_center - away.normalized() * 0.2)
		_cat_rest = 1.6
		_boost = 1.4
		_stumble = _rng.randf_range(6.0, 10.0)
		_pick_target()
		_place()


# ---------------------------------------------------------------- movement helpers
func _clamp_point(p: Vector2) -> Vector2:
	p = p.clamp(-bounds, bounds)
	return LivingRoom.push_out(p, obstacles, 0.2)


func _free_point() -> Vector2:
	# Try several random spots and keep the one furthest from places used recently.
	var best := Vector2(0.5, 1.5)
	var best_score := -1.0
	for _i in 12:
		var p := Vector2(_rng.randf_range(-bounds.x, bounds.x), _rng.randf_range(-bounds.y, bounds.y))
		if LivingRoom.blocked(p, obstacles, 0.35):
			continue
		var score := _rng.randf() * 0.8
		var nearest := 99.0
		for r in _recent:
			nearest = minf(nearest, p.distance_to(r))
		score += minf(nearest, 3.0)
		if score > best_score:
			best_score = score
			best = p
	return best


func _remember(p: Vector2) -> void:
	_recent.append(p)
	if _recent.size() > 6:
		_recent.pop_front()


## Where the mouse runs when the cat is close: a random open spot away from the cat.
func _flee_point(to_cat: Vector2) -> Vector2:
	var best := _clamp_point(_mouse_pos - to_cat.normalized() * 2.0)
	var best_score := -99.0
	for _i in 10:
		var p := _free_point()
		var away := (p - _mouse_pos).normalized().dot(-to_cat.normalized())
		var score := away * 2.0 + _rng.randf()
		if score > best_score:
			best_score = score
			best = p
	return best


func _pick_target() -> void:
	_retarget = _rng.randf_range(1.2, 2.5)
	_mouse_target = _free_point()
	_remember(_mouse_target)


func _step(from: Vector2, to: Vector2, dist: float, margin: float) -> Vector2:
	var d := to - from
	if d.length() < 0.02:
		return from
	var p := from + d.normalized() * minf(dist, d.length())
	return LivingRoom.push_out(p.clamp(-bounds, bounds), obstacles, margin)


func _face(node: Node3D, from: Vector2, to: Vector2, _is_mouse: bool, delta: float) -> void:
	var d := to - from
	if d.length() > 0.05:
		node.rotation.y = lerp_angle(node.rotation.y, atan2(-d.x, -d.y), 1.0 - exp(-12.0 * delta))


func _place() -> void:
	if _fight_t > 0.0:
		return
	_cat.position = Vector3(_cat_pos.x, _cat.position.y, _cat_pos.y)
	_mouse.position = Vector3(_mouse_pos.x, _mouse.position.y, _mouse_pos.y)


func _animate(delta: float) -> void:
	var cat_moving := _cat_rest <= 0.0
	var cp := _t * 14.0
	_cat.position.y = absf(sin(cp)) * 0.05 if cat_moving else 0.0
	for i in _cat_legs.size():
		_cat_legs[i].rotation.x = sin(cp + (0.0 if i % 3 == 0 else PI)) * 0.8 if cat_moving else 0.0
	_cat_tail.rotation.z = sin(_t * 6.0) * (0.25 if cat_moving else 0.7)
	var k := 1.0 - exp(-10.0 * delta)
	_cat.rotation.x = lerpf(_cat.rotation.x, -0.16 if cat_moving else 0.0, k)     # lean into the run
	if not cat_moving:
		_cat.rotation.z = sin(_t * 20.0) * 0.12          # dazed wobble
	else:
		_cat.rotation.z = lerpf(_cat.rotation.z, sin(_t * 7.0) * 0.07, k)         # waddle
	var mp := _t * 22.0
	_mouse.position.y = absf(sin(mp)) * 0.05
	for i in _mouse_legs.size():
		_mouse_legs[i].rotation.x = sin(mp + (0.0 if i % 3 == 0 else PI)) * 0.9
	_mouse_tail.rotation.z = sin(_t * 10.0) * 0.5
	_mouse.rotation.x = lerpf(_mouse.rotation.x, -0.14, k)
	_mouse.rotation.z = lerpf(_mouse.rotation.z, sin(_t * 11.0) * 0.08, k)


# ---------------------------------------------------------------- models
func _mat(c: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _sph(parent: Node3D, r: float, pos: Vector3, mat: Material, sc := Vector3.ONE) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 20
	s.rings = 10
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.material_override = mat
	mi.position = pos
	mi.scale = sc
	parent.add_child(mi)
	return mi


func _cyl(parent: Node3D, rt: float, rb: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = 12
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _leg(parent: Node3D, x: float, z: float, h: float, r: float, fur: Material, paw: Material,
		list: Array[Node3D]) -> void:
	var pivot := Node3D.new()
	pivot.position = Vector3(x, h, z)
	parent.add_child(pivot)
	_cyl(pivot, r, r * 0.9, h, Vector3(0, -h * 0.5, 0), fur)
	_sph(pivot, r * 1.3, Vector3(0, -h, -r * 0.4), paw, Vector3(1, 0.6, 1.3))
	list.append(pivot)


## Loads a .glb character, measures it, and returns a Node3D that:
##  - has its feet at y = 0 and its middle at the origin
##  - faces -Z (the convention used by the movement code)
##  - is scaled to `target_height` metres
## Returns null if the model has not been imported yet.
func _load_actor(path: String, target_height: float, flip: bool) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	if scene == null:
		return null
	var actor := Node3D.new()
	var holder := Node3D.new()
	actor.add_child(holder)
	var model := scene.instantiate() as Node3D
	if model == null:
		return null
	holder.add_child(model)
	add_child(actor)                       # must be in the tree to measure global bounds
	var bb := _bounds(holder)
	if bb.size.z > bb.size.y * 1.3:        # still Z-up: stand it on its feet
		model.rotation_degrees.x -= 90.0
		bb = _bounds(holder)
	if bb.size.y < 0.0001:
		actor.queue_free()
		return null
	var s := target_height / bb.size.y
	var ctr := bb.get_center()
	# These models face +Z when imported; turn them to face -Z (flip reverses that).
	holder.rotation.y = 0.0 if flip else PI
	holder.scale = Vector3.ONE * s
	var rc := holder.basis * Vector3(ctr.x, 0.0, ctr.z)      # rotated + scaled centre offset
	holder.position = Vector3(-rc.x, -bb.position.y * s, -rc.z)
	remove_child(actor)
	return actor


## Bounds of all meshes under `root`, expressed in `root`'s local space.
func _bounds(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var inv := root.global_transform.affine_inverse()
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var local_box := mi.get_aabb()
		var xf := inv * mi.global_transform
		for i in 8:
			var p := xf * local_box.get_endpoint(i)
			if first:
				result = AABB(p, Vector3.ZERO)
				first = false
			else:
				result = result.expand(p)
	return result


func _build_cat() -> void:
	var actor := _load_actor(TOM_PATH, TOM_HEIGHT, FLIP_TOM) if USE_GLB_MODELS else null
	if actor == null:
		_build_cat_primitive()
		return
	_cat = actor
	add_child(_cat)
	_cat_tail = Node3D.new()               # no tail rig on the model; keeps the animation code simple
	_cat.add_child(_cat_tail)
	_cat_margin = 0.35
	_catch_dist = 0.7


func _build_mouse() -> void:
	var actor := _load_actor(JERRY_PATH, JERRY_HEIGHT, FLIP_JERRY) if USE_GLB_MODELS else null
	if actor == null:
		_build_mouse_primitive()
		return
	_mouse = actor
	add_child(_mouse)
	_mouse_tail = Node3D.new()
	_mouse.add_child(_mouse_tail)


func _build_cat_primitive() -> void:
	_cat = Node3D.new()
	_cat.scale = Vector3.ONE * 1.25
	add_child(_cat)
	var fur := _mat(Color(0.93, 0.6, 0.28))              # ginger tabby
	var stripe := _mat(Color(0.74, 0.4, 0.14))
	var light := _mat(Color(0.99, 0.94, 0.86))
	var pink := _mat(Color(0.98, 0.62, 0.68), 0.6)
	var iris := _mat(Color(0.3, 0.8, 0.35), 0.2)
	var white := _mat(Color(1, 1, 1), 0.2)
	var black := _mat(Color(0.04, 0.04, 0.05), 0.3)

	_sph(_cat, 0.15, Vector3(0, 0.25, 0.04), fur, Vector3(1.0, 0.95, 1.8))               # body
	_sph(_cat, 0.105, Vector3(-0.07, 0.22, 0.2), fur, Vector3(1.0, 1.0, 1.1))            # haunches
	_sph(_cat, 0.105, Vector3(0.07, 0.22, 0.2), fur, Vector3(1.0, 1.0, 1.1))
	_sph(_cat, 0.115, Vector3(0, 0.2, -0.14), light, Vector3(0.85, 0.85, 0.9))           # fluffy white chest
	# tabby bands that wrap round the body
	for dz in [-0.04, 0.05, 0.14, 0.23]:
		var rr := 0.15 * sqrt(maxf(1.0 - pow(dz / 0.27, 2.0), 0.05)) + 0.004
		var band := _cyl(_cat, rr, rr, 0.025, Vector3(0, 0.25, 0.04 + dz), stripe)
		band.rotation_degrees.x = 90.0
	# head
	_sph(_cat, 0.135, Vector3(0, 0.38, -0.3), fur, Vector3(1.12, 0.95, 1.0))
	for sx in [-1.0, 1.0]:
		_sph(_cat, 0.06, Vector3(sx * 0.1, 0.34, -0.33), fur)                            # cheek fluff
		_sph(_cat, 0.05, Vector3(sx * 0.03, 0.335, -0.415), light, Vector3(1.1, 0.9, 0.9))   # muzzle
		var ear := _cyl(_cat, 0.0, 0.06, 0.12, Vector3(sx * 0.09, 0.5, -0.29), fur)
		ear.rotation_degrees.z = -sx * 14.0
		var inner := _cyl(_cat, 0.0, 0.038, 0.085, Vector3(sx * 0.088, 0.495, -0.305), pink)
		inner.rotation_degrees.z = -sx * 14.0
		_sph(_cat, 0.034, Vector3(sx * 0.06, 0.395, -0.395), white, Vector3(1.0, 1.15, 0.7))  # eyes
		_sph(_cat, 0.022, Vector3(sx * 0.06, 0.395, -0.415), iris, Vector3(1.0, 1.15, 0.6))
		_sph(_cat, 0.011, Vector3(sx * 0.06, 0.395, -0.425), black, Vector3(0.6, 1.4, 0.6))
		_sph(_cat, 0.005, Vector3(sx * 0.054, 0.405, -0.43), white)                        # eye sparkle
		for k in 3:                                                                       # whiskers
			var w := MeshInstance3D.new()
			var wb := BoxMesh.new()
			wb.size = Vector3(0.15, 0.003, 0.003)
			w.mesh = wb
			w.material_override = white
			w.position = Vector3(sx * 0.13, 0.33 + k * 0.016, -0.41)
			w.rotation_degrees.y = sx * (10.0 + k * 12.0)
			_cat.add_child(w)
	_sph(_cat, 0.018, Vector3(0, 0.355, -0.445), pink, Vector3(1.2, 0.8, 0.8))            # nose
	for k in 3:                                                                           # forehead stripes
		_sph(_cat, 0.012, Vector3((k - 1) * 0.04, 0.46, -0.34), stripe, Vector3(0.6, 1.8, 0.4))
	for p in [[-0.085, -0.15], [0.085, -0.15], [-0.085, 0.2], [0.085, 0.2]]:
		_leg(_cat, p[0], p[1], 0.2, 0.042, fur, light, _cat_legs)
	_cat_tail = Node3D.new()
	_cat_tail.position = Vector3(0, 0.28, 0.32)
	_cat.add_child(_cat_tail)
	var pts := [Vector3(0, 0.02, 0.04), Vector3(0, 0.08, 0.1), Vector3(0, 0.15, 0.14),
		Vector3(0, 0.23, 0.15), Vector3(0, 0.31, 0.13), Vector3(0, 0.37, 0.09)]
	for i in 15:                                             # smooth, dense chain of balls = curved tail
		var t := float(i) / 14.0 * (pts.size() - 1)
		var j := mini(int(t), pts.size() - 2)
		var pp: Vector3 = pts[j].lerp(pts[j + 1], t - j)
		_sph(_cat_tail, 0.036 - i * 0.0012, pp, stripe if (i / 3) % 2 == 1 else fur)
	_sph(_cat_tail, 0.032, Vector3(0, 0.41, 0.06), light)


func _build_mouse_primitive() -> void:
	_mouse = Node3D.new()
	_mouse.scale = Vector3.ONE * 1.9
	add_child(_mouse)
	var fur := _mat(Color(0.7, 0.66, 0.68))
	var belly := _mat(Color(0.96, 0.9, 0.86))
	var pink := _mat(Color(1.0, 0.7, 0.76), 0.6)
	var black := _mat(Color(0.04, 0.04, 0.05), 0.2)
	var white := _mat(Color(1, 1, 1), 0.2)

	_sph(_mouse, 0.07, Vector3(0, 0.075, 0.03), fur, Vector3(0.95, 0.9, 1.5))             # body
	_sph(_mouse, 0.055, Vector3(0, 0.055, 0.0), belly, Vector3(0.8, 0.7, 1.2))            # belly
	_sph(_mouse, 0.058, Vector3(0, 0.095, -0.1), fur, Vector3(0.95, 0.95, 1.1))           # head
	_sph(_mouse, 0.034, Vector3(0, 0.085, -0.165), fur, Vector3(0.8, 0.75, 1.3))          # snout
	_sph(_mouse, 0.014, Vector3(0, 0.088, -0.205), pink)                                  # nose
	for sx in [-1.0, 1.0]:
		var ear := _sph(_mouse, 0.052, Vector3(sx * 0.055, 0.15, -0.085), fur, Vector3(1.0, 1.0, 0.22))
		ear.rotation_degrees.y = sx * 20.0
		var inner := _sph(_mouse, 0.037, Vector3(sx * 0.054, 0.15, -0.095), pink, Vector3(1.0, 1.0, 0.22))
		inner.rotation_degrees.y = sx * 20.0
		_sph(_mouse, 0.017, Vector3(sx * 0.03, 0.11, -0.145), black, Vector3(1.0, 1.2, 0.8))   # eyes
		_sph(_mouse, 0.006, Vector3(sx * 0.026, 0.118, -0.157), white)
		for k in 2:                                                                       # whiskers
			var w := MeshInstance3D.new()
			var wb := BoxMesh.new()
			wb.size = Vector3(0.1, 0.002, 0.002)
			w.mesh = wb
			w.material_override = belly
			w.position = Vector3(sx * 0.06, 0.085 + k * 0.012, -0.18)
			w.rotation_degrees.y = sx * (15.0 + k * 14.0)
			_mouse.add_child(w)
	for p in [[-0.04, -0.06], [0.04, -0.06], [-0.045, 0.1], [0.045, 0.1]]:
		_leg(_mouse, p[0], p[1], 0.05, 0.014, fur, pink, _mouse_legs)
	_mouse_tail = Node3D.new()
	_mouse_tail.position = Vector3(0, 0.07, 0.12)
	_mouse.add_child(_mouse_tail)
	for i in 24:                                             # long curly tail
		var t := float(i) / 23.0
		_sph(_mouse_tail, 0.012 - t * 0.007, Vector3(sin(t * 5.0) * 0.03, 0.005 + t * 0.03, 0.02 + t * 0.2), pink)


func _make_cloud() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.24
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.9, 0.9, 0.9, 0.85)
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.roughness = 1.0
	sm.material = pm
	p.mesh = sm
	p.amount = 18
	p.lifetime = 1.0
	p.one_shot = true
	p.explosiveness = 0.2
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.3
	p.direction = Vector3.UP
	p.spread = 90.0
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.9
	p.gravity = Vector3(0, 0.2, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.4
	p.emitting = false
	return p
