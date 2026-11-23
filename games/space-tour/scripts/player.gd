class_name Player
extends CharacterBody3D
## The shooting star. Glides along the tour route (PathTrack) and steers sideways.
## Collected lights join it as orbiting, glowing companions.
##
## Node tree (built in _ready):
## Player (CharacterBody3D)            <- this script
## ├─ Mesh   (MeshInstance3D, emissive gold sphere)
## ├─ Halo   (MeshInstance3D, billboard glow)
## ├─ Light  (OmniLight3D)
## ├─ Tail   (GPUParticles3D, world-space spark trail)
## ├─ CollectArea (Area3D) → CollisionShape3D (SphereShape3D)
## └─ Companion x N (Node3D: core + halo + OmniLight3D)

signal collected(count: int, note: int)
## Space Tour (ML): the game steers the ship from the patient's hand and sets the forward speed.

const Fx = preload("res://games/space-tour/scripts/fx.gd")
const PT = preload("res://games/space-tour/scripts/path_track.gd")
const MAX_COMPANIONS := 14

@export var x_limit := 6.0
@export var steer_smooth := 12.0   # how quickly the ship follows the hand

## Forward speed (route units per second) and the lateral position the hand asks for.
var forward_speed := 12.0
var target_lx := 0.0

var current_mult := 1.0     # forward speed relative to a comfortable pace (drives the camera field of view)
var active := false         # false on the title screen
var s := 0.0                # distance along the route
var lx := 0.0               # sideways offset from the route
var lateral_velocity := 0.0
var star_count := 0

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _halo: MeshInstance3D
var _light: OmniLight3D
var _tail: GPUParticles3D
var _tails: Array[GPUParticles3D] = []
var _companions: Array[Dictionary] = []
var _t := 0.0


func _ready() -> void:
	_build_visuals()
	_build_tail()
	_place()


## One step of flight, called by the game each frame it is running (not paused or held).
func step(delta: float) -> void:
	if not active:
		return
	current_mult = clampf(forward_speed / 14.0, 0.5, 1.8)
	s += forward_speed * delta
	var follow := 1.0 - exp(-steer_smooth * delta)
	var next_lx := lerpf(lx, clampf(target_lx, -x_limit, x_limit), follow)
	lateral_velocity = (next_lx - lx) / maxf(delta, 0.0001)
	lx = next_lx
	_place()
	_mesh.scale = Vector3(1, 1, 1.0 + (current_mult - 1.0) * 0.25)


func _process(delta: float) -> void:
	_t += delta
	# The further the player reaches sideways, the fuller the tails glow.
	var edge := absf(lx) / x_limit
	for tl in _tails:
		tl.amount_ratio = lerpf(0.6, 1.0, edge)
	var base := 1.0 + minf(0.02 * star_count, 0.5)
	_halo.scale = Vector3.ONE * (base + 0.03 * sin(_t * 3.0))
	for c in _companions:
		c["angle"] += c["speed"] * delta
		var a: float = c["angle"]
		var r: float = c["radius"]
		(c["node"] as Node3D).position = Vector3(cos(a) * r, sin(a * 1.7 + r) * 0.6, sin(a) * r)


func _place() -> void:
	global_transform = Transform3D(PT.frame(s), PT.point(s, lx, 0.0))


func _base_light() -> float:
	return 1.5 + minf(star_count * 0.06, 1.5)


## The game calls this when the ship reaches a target in line: the light joins the ship.
func collect(other: Pickup) -> void:
	var c: Color = other.color
	var note: int = other.note
	other.collect()
	star_count += 1
	_mat.emission_energy_multiplier = 1.6 + minf(star_count * 0.05, 1.2)
	_light.light_energy = _base_light() + 2.0
	create_tween().tween_property(_light, "light_energy", _base_light(), 0.6)
	_add_companion(c)
	collected.emit(star_count, note)


func _add_companion(c: Color) -> void:
	if _companions.size() >= MAX_COMPANIONS:
		var old: Dictionary = _companions.pop_front()
		(old["node"] as Node3D).queue_free()

	var n := Node3D.new()
	n.name = "Companion"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c.lightened(0.6)
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 2.5
	var sm := SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.14
	sm.material = mat
	var core := MeshInstance3D.new()
	core.mesh = sm
	n.add_child(core)
	n.add_child(Fx.halo(0.7, Color(c.r, c.g, c.b, 0.4)))
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 0.4
	l.omni_range = 5.0
	n.add_child(l)
	add_child(n)

	_companions.append({
		"node": n,
		"angle": randf() * TAU,
		"radius": randf_range(1.3, 2.7),
		"speed": randf_range(1.2, 2.4) * (1.0 if randf() < 0.5 else -1.0),
	})


# --- construction -----------------------------------------------------------

func _build_visuals() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.56
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.85, 0.92, 1.0)
	_mat.emission_enabled = true
	_mat.emission = Color(0.7, 0.85, 1.0)
	_mat.emission_energy_multiplier = 1.6
	sphere.material = _mat
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	_mesh.mesh = sphere
	add_child(_mesh)

	_halo = Fx.halo(1.8, Color(0.6, 0.8, 1.0, 0.16))
	add_child(_halo)

	_light = OmniLight3D.new()
	_light.name = "Light"
	_light.light_color = Color(0.7, 0.85, 1.0)
	_light.light_energy = 1.5
	_light.omni_range = 16.0
	add_child(_light)


func _build_tail() -> void:
	# Main comet tail: long, fading white -> blue -> violet.
	_tail = _make_tail("Tail", 700, 2.6, 0.22, 3.0, 0.5, 4.0, 14.0, PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.9),
		Color(0.65, 0.85, 1.0, 0.6),
		Color(0.35, 0.45, 1.0, 0.25),
		Color(0.4, 0.2, 0.8, 0.0),
	]))
	# Thin ion streamers: narrow, very long, slightly spread.
	_make_tail("TailIonL", 250, 3.2, 0.12, 5.0, 0.3, 8.0, 18.0, PackedColorArray([
		Color(0.8, 0.95, 1.0, 0.7),
		Color(0.3, 0.7, 1.0, 0.3),
		Color(0.2, 0.3, 0.9, 0.0),
	]))
	# Warm dust tail: shorter, golden sparks.
	_make_tail("TailDust", 300, 1.8, 0.25, 12.0, 0.4, 2.0, 8.0, PackedColorArray([
		Color(1.0, 0.9, 0.6, 0.7),
		Color(1.0, 0.55, 0.2, 0.35),
		Color(0.6, 0.2, 0.2, 0.0),
	]))


func _make_tail(tail_name: String, count: int, life: float, size: float, spread: float,
		radius: float, vmin: float, vmax: float, colors: PackedColorArray) -> GPUParticles3D:
	var t := GPUParticles3D.new()
	t.name = tail_name
	t.amount = count
	t.lifetime = life
	t.local_coords = false        # particles stay behind in world space
	t.draw_pass_1 = Fx.spark_mesh(size)
	t.visibility_aabb = AABB(Vector3(-60, -60, -60), Vector3(120, 120, 120))

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.1
	pm.direction = Vector3(0, 0, 1)   # backwards along the ship's local +Z
	pm.spread = spread
	pm.initial_velocity_min = vmin
	pm.initial_velocity_max = vmax
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0, 1))
	scale_curve.add_point(Vector2(1, 0))
	var sc := CurveTexture.new()
	sc.curve = scale_curve
	pm.scale_curve = sc
	pm.color_ramp = Fx.ramp(colors)
	t.process_material = pm
	add_child(t)
	_tails.append(t)
	return t


## Gentle burst of pastel sparks around the ship for milestones.
func celebrate() -> void:
	var b := GPUParticles3D.new()
	b.name = "Celebrate"
	b.amount = 90
	b.lifetime = 2.5
	b.one_shot = true
	b.explosiveness = 0.9
	b.local_coords = true
	b.draw_pass_1 = Fx.spark_mesh(0.35)
	b.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.5
	pm.direction = Vector3.UP
	pm.spread = 180.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 5.0
	pm.damping_min = 1.5
	pm.damping_max = 2.5
	pm.gravity = Vector3.ZERO
	pm.color_ramp = Fx.ramp(PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.8),
		Color(0.8, 0.9, 1.0, 0.6),
		Color(1.0, 0.85, 0.95, 0.0),
	]))
	b.process_material = pm
	add_child(b)
	b.emitting = true
	get_tree().create_timer(3.5).timeout.connect(b.queue_free)
