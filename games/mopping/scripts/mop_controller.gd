class_name MopController
extends Node3D
## The PLAYER. Accepts continuous float ML (medio-lateral) / AP (anterior-posterior)
## values from a MARS device (or any sensor) and maps them directly onto this
## node's Transform3D. The character walks, leans and swings the mop in front of
## itself, so weight-shifting in the real world becomes sweeping in the game.
##
## Feed it from anywhere:   player.set_ml_ap(ml, ap)
## or over UDP (port 4242), packets as  "ml,ap"  or  {"ml":0.1,"ap":-0.2}.
## With no device feeding it, the mouse cursor drives the player instead (walks toward the cursor).

signal calibrated(origin: Vector2)

@export var floor_center := Vector3.ZERO
@export var room_half_extents := Vector2(2.8, 1.8)    # clamp for the player's feet
@export var head_bounds := Vector2(2.92, 1.92)        # clamp for the mop head
@export var input_scale := Vector2.ONE                # world metres per device unit (x, z)
@export var invert_ml := false
@export var invert_ap := false
@export var swap_axes := false
@export var auto_scale_range := false                 # fit the patient's reachable range to the room
@export var min_device_range := 0.05
@export var smoothing := 14.0
@export var enable_udp := true
@export var udp_port := 4242
@export var debug_speed := 2.2
@export var external_timeout := 0.5
@export var mop_reach := 0.62                         # metres in front of the player

const UPPER_ARM := 0.30
const FOREARM := 0.29

var raw_input := Vector2.ZERO        # latest incoming (x = ML, y = world Z) in sensor space
var origin := Vector2.ZERO           # sensor-space point treated as room centre
var obstacles: Array[Rect2] = []     # furniture footprints (world XZ)
var mop_area: Area3D
var head: Node3D                     # mop head (parent of mop_area)
var speed := 0.0                     # smoothed m/s
var velocity := Vector2.ZERO         # world X/Z m/s

var _pos := Vector2.ZERO
var _yaw := 0.0
var _last_external_time := -100.0
var _udp: PacketPeerUDP
var _range_min := Vector2.ZERO
var _range_max := Vector2.ZERO
var _walk_phase := 0.0
var _t := 0.0

var _body: Node3D
var _skull: Node3D
var _hip_l: Node3D
var _hip_r: Node3D
var _knee_l: Node3D
var _knee_r: Node3D
var _handle: Node3D
var _up_l: Node3D
var _up_r: Node3D
var _fo_l: Node3D
var _fo_r: Node3D
var _hand_l: Node3D
var _hand_r: Node3D
var _elbow_l: Node3D
var _elbow_r: Node3D


func _ready() -> void:
	_build_player()
	if enable_udp:
		_udp = PacketPeerUDP.new()
		if _udp.bind(udp_port) != OK:
			push_warning("MopController: could not bind UDP port %d" % udp_port)
			_udp = null


# ---------------------------------------------------------------- input API
## Device-facing API. ML: +right. AP: +anterior (forward, away from camera).
func set_ml_ap(ml: float, ap: float) -> void:
	var a := ml
	var b := ap
	if swap_axes:
		a = ap
		b = ml
	if invert_ml:
		a = -a
	if invert_ap:
		b = -b
	set_input(a, -b)   # anterior = forward = -Z in the room


## Raw room-axis API (x right, z toward camera).
func set_input(x: float, z: float) -> void:
	raw_input = Vector2(x, z)
	_last_external_time = Time.get_ticks_msec() / 1000.0


## Treat the current incoming coordinate as the room's (0,0) centre.
func calibrate() -> void:
	origin = raw_input
	_range_min = Vector2.ZERO
	_range_max = Vector2.ZERO
	_pos = Vector2.ZERO
	velocity = Vector2.ZERO
	global_position = floor_center
	calibrated.emit(origin)


func is_device_live() -> bool:
	return Time.get_ticks_msec() / 1000.0 - _last_external_time < external_timeout


# ---------------------------------------------------------------- update loop
func _process(delta: float) -> void:
	_t += delta
	_poll_udp()
	if not is_device_live():
		_follow_mouse(delta)


## Mouse control: the player walks toward the point on the floor under the cursor.
func _follow_mouse(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var mp := GamePointer.screen(self)
	var from := cam.project_ray_origin(mp)
	var dir := cam.project_ray_normal(mp)
	if absf(dir.y) < 0.001:
		return
	var t := -from.y / dir.y
	if t < 0.0:
		return
	var hit := from + dir * t
	# The mop is held in front of the player, so aim the body a little behind the cursor.
	var target := Vector2(hit.x - floor_center.x, hit.z - floor_center.z) + origin
	var to := target - raw_input
	var step := debug_speed * 1.6 * delta
	if to.length() > 0.04:
		raw_input += to.limit_length(step)


func _physics_process(delta: float) -> void:
	var dev := raw_input - origin
	_range_min = _range_min.min(dev)
	_range_max = _range_max.max(dev)

	var scale_v := input_scale
	if auto_scale_range:
		var rx := maxf(maxf(absf(_range_min.x), absf(_range_max.x)), min_device_range)
		var rz := maxf(maxf(absf(_range_min.y), absf(_range_max.y)), min_device_range)
		scale_v = Vector2(room_half_extents.x / rx, room_half_extents.y / rz)

	var target := (dev * scale_v).clamp(-room_half_extents, room_half_extents)
	var prev := _pos
	if smoothing > 0.0:
		_pos = _pos.lerp(target, 1.0 - exp(-smoothing * delta))
	else:
		_pos = target
	_pos = LivingRoom.push_out(_pos, obstacles, 0.3)    # can't walk through furniture

	velocity = (_pos - prev) / maxf(delta, 0.0001)
	speed = lerpf(speed, velocity.length(), 1.0 - exp(-10.0 * delta))
	if velocity.length() > 0.2:
		_yaw = lerp_angle(_yaw, atan2(-velocity.x, -velocity.y), 1.0 - exp(-6.0 * delta))

	# Device coordinates -> Transform3D, directly.
	global_transform = Transform3D(
		Basis(Vector3.UP, _yaw),
		floor_center + Vector3(_pos.x, 0.0, _pos.y))
	_animate(delta)


func _poll_udp() -> void:
	if _udp == null:
		return
	while _udp.get_available_packet_count() > 0:
		_parse_packet(_udp.get_packet().get_string_from_utf8())


func _parse_packet(text: String) -> void:
	text = text.strip_edges()
	if text.begins_with("{"):
		var d: Variant = JSON.parse_string(text)
		if d is Dictionary:
			var ml: Variant = d.get("ml", d.get("x", null))
			var ap: Variant = d.get("ap", d.get("z", null))
			if ml != null and ap != null:
				set_ml_ap(float(ml), float(ap))
		return
	var parts := text.replace(";", ",").replace("\t", ",").replace(" ", ",").split(",", false)
	if parts.size() >= 2 and parts[0].is_valid_float() and parts[1].is_valid_float():
		set_ml_ap(parts[0].to_float(), parts[1].to_float())


# ---------------------------------------------------------------- animation
func _animate(delta: float) -> void:
	var moving := clampf(speed / 0.8, 0.0, 1.0)
	var lv := global_transform.basis.inverse() * Vector3(velocity.x, 0.0, velocity.y)
	var k := 1.0 - exp(-8.0 * delta)

	# Lean into the direction of travel (balance-board feel).
	_body.rotation.x = lerpf(_body.rotation.x, clampf(lv.z * 0.1, -0.3, 0.3), k)
	_body.rotation.z = lerpf(_body.rotation.z, clampf(-lv.x * 0.1, -0.3, 0.3), k)

	# Walk cycle: thighs swing, knees bend as the foot lifts.
	_walk_phase += speed * delta * 6.0
	var s := sin(_walk_phase)
	_hip_l.rotation.x = s * 0.55 * moving
	_hip_r.rotation.x = -s * 0.55 * moving
	_knee_l.rotation.x = -(0.08 + 0.7 * maxf(0.0, -s)) * moving
	_knee_r.rotation.x = -(0.08 + 0.7 * maxf(0.0, s)) * moving
	_body.position.y = 0.94 + absf(s) * 0.025 * moving + sin(_t * 1.8) * 0.004
	_body.rotation.y = lerpf(_body.rotation.y, -s * 0.03 * moving, k)    # slight shoulder turn

	# The mop head stays straight in front of the player and goes wherever you move.
	head.position = Vector3(0.0, 0.0, -mop_reach)
	head.rotation.y = 0.0
	var hp := head.global_position
	hp.x = clampf(hp.x, floor_center.x - head_bounds.x, floor_center.x + head_bounds.x)
	hp.z = clampf(hp.z, floor_center.z - head_bounds.y, floor_center.z + head_bounds.y)
	var hxz := LivingRoom.push_out(Vector2(hp.x, hp.z), obstacles, 0.05)
	hp.x = hxz.x
	hp.z = hxz.y
	head.global_position = hp

	# Handle from mop head up through the hands; arms solved with 2-bone IK.
	var grip := _body.to_global(Vector3(0.0, 0.02, -0.3))
	var hpos := head.global_position + Vector3(0, 0.03, 0)
	_stretch(_handle, hpos, hpos + (grip - hpos) * 1.35)
	var right := global_transform.basis.x
	for side: float in [-1.0, 1.0]:
		var sh := _body.to_global(Vector3(side * 0.2, 0.46, 0.0))
		var hand := grip + right * side * 0.09
		var elbow := _arm_ik(sh, hand, side)
		var up: Node3D = _up_l if side < 0.0 else _up_r
		var fo: Node3D = _fo_l if side < 0.0 else _fo_r
		var hd: Node3D = _hand_l if side < 0.0 else _hand_r
		_stretch(up, sh, elbow)
		_stretch(fo, elbow, hand)
		hd.global_position = hand


func _arm_ik(shoulder: Vector3, hand: Vector3, side: float) -> Vector3:
	var to := hand - shoulder
	var d := clampf(to.length(), 0.1, UPPER_ARM + FOREARM - 0.005)
	var dir := to.normalized()
	var a := (UPPER_ARM * UPPER_ARM - FOREARM * FOREARM + d * d) / (2.0 * d)
	var h := sqrt(maxf(UPPER_ARM * UPPER_ARM - a * a, 0.0))
	var b := global_transform.basis
	var pole := (Vector3.DOWN + b.x * side * 0.8 + b.z * 0.3).normalized()
	pole = (pole - dir * pole.dot(dir)).normalized()
	return shoulder + dir * a + pole * h


func _stretch(limb: Node3D, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var len := d.length()
	if len < 0.001:
		return
	limb.global_position = a
	var up := Vector3.UP if absf(d.normalized().y) < 0.99 else Vector3.RIGHT
	limb.look_at(b, up)
	limb.scale = Vector3(1, 1, len)


# ---------------------------------------------------------------- visuals
func _mat(c: Color, rough := 0.7, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sph(parent: Node3D, r: float, mat: Material, pos: Vector3, sc := Vector3.ONE) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 24
	s.rings = 12
	var mi := _mesh(parent, s, mat, pos)
	mi.scale = sc
	return mi


func _cyl(parent: Node3D, rt: float, rb: float, h: float, mat: Material, pos: Vector3) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = 16
	return _mesh(parent, c, mat, pos)


func _bx(parent: Node3D, size: Vector3, mat: Material, pos: Vector3) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mesh(parent, b, mat, pos)


## Unit-length cylinder along -Z, to be stretched with _stretch().
func _make_limb(mat: Material, radius: float) -> Node3D:
	var n := Node3D.new()
	var mi := _cyl(n, radius, radius, 1.0, mat, Vector3(0, 0, -0.5))
	mi.rotation.x = deg_to_rad(-90.0)
	add_child(n)
	return n


## Returns [hip_pivot, knee_pivot].
func _make_leg(x: float, jeans: Material, shoe: Material, sole: Material) -> Array:
	var hip := Node3D.new()
	hip.position = Vector3(x, 0.94, 0)
	add_child(hip)
	_sph(hip, 0.1, jeans, Vector3(0, -0.02, 0))
	_cyl(hip, 0.092, 0.07, 0.46, jeans, Vector3(0, -0.23, 0))
	var knee := Node3D.new()
	knee.position = Vector3(0, -0.46, 0)
	hip.add_child(knee)
	_sph(knee, 0.07, jeans, Vector3.ZERO)
	_cyl(knee, 0.07, 0.052, 0.4, jeans, Vector3(0, -0.2, 0))
	_cyl(knee, 0.056, 0.056, 0.03, shoe, Vector3(0, -0.405, 0))                         # sock/ankle
	_sph(knee, 0.07, shoe, Vector3(0, -0.43, -0.05), Vector3(0.95, 0.75, 1.9))          # rounded sneaker
	_sph(knee, 0.062, sole, Vector3(0, -0.47, -0.05), Vector3(1.0, 0.32, 2.0))          # white sole
	return [hip, knee]


func _build_player() -> void:
	var shirt := _mat(Color(0.16, 0.58, 0.64), 0.9)
	var shirt_dark := _mat(Color(0.12, 0.45, 0.5), 0.9)
	var jeans := _mat(Color(0.2, 0.3, 0.52), 0.85)
	var skin := _mat(Color(0.93, 0.72, 0.58), 0.55)
	var hair := _mat(Color(0.32, 0.18, 0.1), 0.55)
	var shoe := _mat(Color(0.95, 0.95, 0.93), 0.7)
	var sole := _mat(Color(0.3, 0.55, 0.85), 0.6)
	var belt := _mat(Color(0.45, 0.3, 0.18), 0.5)
	var glove := _mat(Color(1.0, 0.85, 0.15), 0.4)
	var white := _mat(Color(1, 1, 1), 0.25)
	var dark := _mat(Color(0.07, 0.05, 0.04), 0.2)

	var l := _make_leg(-0.1, jeans, shoe, sole)
	_hip_l = l[0]
	_knee_l = l[1]
	var r := _make_leg(0.1, jeans, shoe, sole)
	_hip_r = r[0]
	_knee_r = r[1]

	# Torso (pivot at the hips).
	_body = Node3D.new()
	_body.position.y = 0.94
	add_child(_body)
	_sph(_body, 0.17, jeans, Vector3(0, 0.0, 0), Vector3(1.15, 0.75, 0.9))              # hips
	_cyl(_body, 0.165, 0.165, 0.035, belt, Vector3(0, 0.09, 0))                          # belt
	_sph(_body, 0.15, shirt, Vector3(0, 0.15, 0), Vector3(1.2, 0.95, 0.9))               # waist
	_sph(_body, 0.19, shirt, Vector3(0, 0.31, 0), Vector3(1.12, 1.25, 0.8))              # chest
	_sph(_body, 0.085, shirt_dark, Vector3(0, 0.5, 0), Vector3(1.6, 0.6, 1.0))           # collar / shoulders
	_cyl(_body, 0.05, 0.055, 0.1, skin, Vector3(0, 0.56, 0))                             # neck
	_bx(_body, Vector3(0.12, 0.1, 0.02), shirt_dark, Vector3(0, 0.26, 0.145))            # back pocket patch
	for sx in [-1.0, 1.0]:
		_sph(_body, 0.058, shirt, Vector3(sx * 0.205, 0.45, 0))                            # shoulders

	# Head: big, friendly proportions.
	_skull = Node3D.new()
	_skull.position = Vector3(0, 0.72, 0)
	_body.add_child(_skull)
	_sph(_skull, 0.125, skin, Vector3.ZERO, Vector3(0.95, 1.05, 1.0))                    # head
	_sph(_skull, 0.136, hair, Vector3(0, 0.025, 0.02), Vector3(1.0, 0.98, 1.0))          # hair cap
	_sph(_skull, 0.05, hair, Vector3(0, -0.06, 0.12), Vector3(1.5, 1.2, 0.9))            # hair at the nape
	_sph(_skull, 0.045, hair, Vector3(0, 0.06, 0.15), Vector3(1.0, 1.0, 1.0))            # ponytail base
	_sph(_skull, 0.034, hair, Vector3(0, 0.0, 0.2), Vector3(1.0, 1.4, 1.0))
	_sph(_skull, 0.028, hair, Vector3(0, -0.07, 0.215), Vector3(1.0, 1.5, 1.0))
	_sph(_skull, 0.065, hair, Vector3(0, 0.085, -0.085), Vector3(1.5, 0.55, 0.75))         # fringe
	for sx in [-1.0, 1.0]:
		_sph(_skull, 0.026, skin, Vector3(sx * 0.12, -0.01, 0.0), Vector3(0.6, 1.1, 0.9))     # ears
		_sph(_skull, 0.022, white, Vector3(sx * 0.047, -0.005, -0.11), Vector3(1.0, 1.1, 0.6))  # eyes
		_sph(_skull, 0.015, _mat(Color(0.25, 0.14, 0.08), 0.2), Vector3(sx * 0.047, -0.006, -0.117), Vector3(1.0, 1.1, 0.6))
		_sph(_skull, 0.008, dark, Vector3(sx * 0.047, -0.006, -0.123), Vector3(1.0, 1.1, 0.6))
		_sph(_skull, 0.004, white, Vector3(sx * 0.043, -0.0, -0.127))                    # eye sparkle
		_bx(_skull, Vector3(0.045, 0.008, 0.008), hair, Vector3(sx * 0.047, 0.035, -0.112))   # brows
		_sph(_skull, 0.022, _mat(Color(1.0, 0.6, 0.6), 0.6), Vector3(sx * 0.075, -0.045, -0.1), Vector3(1.0, 0.7, 0.4))  # cheeks
	_sph(_skull, 0.017, skin, Vector3(0, -0.03, -0.122), Vector3(0.9, 1.0, 0.9))              # nose
	var mouth := _bx(_skull, Vector3(0.05, 0.008, 0.008), _mat(Color(0.75, 0.3, 0.32), 0.5), Vector3(0, -0.07, -0.108))
	mouth.rotation.z = 0.0

	# Arms (sleeve upper arm, bare forearm, yellow rubber gloves) + mop handle.
	_up_l = _make_limb(shirt, 0.058)
	_up_r = _make_limb(shirt, 0.058)
	_fo_l = _make_limb(skin, 0.042)
	_fo_r = _make_limb(skin, 0.042)
	_elbow_l = _sph(self, 0.046, skin, Vector3.ZERO)
	_elbow_r = _sph(self, 0.046, skin, Vector3.ZERO)
	_hand_l = _sph(self, 0.058, glove, Vector3.ZERO, Vector3(0.95, 0.85, 1.15))
	_hand_r = _sph(self, 0.058, glove, Vector3.ZERO, Vector3(0.95, 0.85, 1.15))
	_handle = _make_limb(_mat(Color(0.75, 0.55, 0.3), 0.5), 0.017)

	# Mop head (+ Area3D that paints the floor).
	head = Node3D.new()
	head.name = "MopHead"
	add_child(head)
	_bx(head, Vector3(0.42, 0.04, 0.13), _mat(Color(0.15, 0.35, 0.95), 0.9), Vector3(0, 0.03, 0))
	_bx(head, Vector3(0.44, 0.018, 0.15), _mat(Color(0.93, 0.93, 0.9), 0.95), Vector3(0, 0.012, 0))
	mop_area = Area3D.new()
	mop_area.name = "MopArea"
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.42, 0.12, 0.2)
	shape.shape = bs
	shape.position.y = 0.03
	mop_area.add_child(shape)
	head.add_child(mop_area)
