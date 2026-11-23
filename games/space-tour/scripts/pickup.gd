class_name Pickup
extends Area3D
## Pooled collectable light. Flying through it adds a glowing companion to the ship.
## Can also appear as a big glowing ring to fly through (is_ring).
##
## Pickup (Area3D)                     <- this script
## ├─ Core (MeshInstance3D, emissive sphere)
## ├─ Ring (MeshInstance3D, torus)
## ├─ Halo (MeshInstance3D, billboard glow)
## └─ CollisionShape3D (SphereShape3D)

const Fx = preload("res://games/space-tour/scripts/fx.gd")

var active := false
var color := Color.WHITE
var note := 0               # which bell note this plays when collected
var is_ring := false
var base_scale := 1.0
var _facing := Basis.IDENTITY
var _mat: StandardMaterial3D
var _halo_mat: StandardMaterial3D
var _core: MeshInstance3D
var _ring: MeshInstance3D
var _shape: SphereShape3D


func _ready() -> void:
	add_to_group("pickup")
	_mat = StandardMaterial3D.new()
	_mat.emission_enabled = true
	_mat.emission_energy_multiplier = 3.2

	var core := SphereMesh.new()
	core.radius = 0.36
	core.height = 0.72
	core.material = _mat
	_core = MeshInstance3D.new()
	_core.name = "Core"
	_core.mesh = core
	add_child(_core)

	var torus := TorusMesh.new()
	torus.inner_radius = 0.5
	torus.outer_radius = 0.62
	torus.material = _mat
	_ring = MeshInstance3D.new()
	_ring.name = "Ring"
	_ring.mesh = torus
	add_child(_ring)

	var halo := Fx.halo(2.8, Color.WHITE)
	_halo_mat = (halo.mesh as QuadMesh).material as StandardMaterial3D
	add_child(halo)

	_shape = SphereShape3D.new()
	_shape.radius = 1.1
	var cs := CollisionShape3D.new()
	cs.shape = _shape
	add_child(cs)
	position = Vector3(0, -100000, 0)   # parked far away while pooled
	monitorable = false
	deactivate()


func _process(delta: float) -> void:
	if active and not is_ring:
		rotate_y(2.5 * delta)
		rotate_x(1.4 * delta)


## The current target breathes a little larger so the next place to reach is easy to find.
func highlight(amount: float) -> void:
	var factor := 1.0 + amount
	scale = Vector3.ONE * base_scale * factor
	if is_ring:
		global_transform.basis = _facing.scaled(scale)


## Orbs spin freely; rings are oriented to face down the route (torus axis = route direction).
func activate(pos: Vector3, c: Color, ring: bool = false, facing: Basis = Basis.IDENTITY) -> void:
	color = c
	is_ring = ring
	_mat.albedo_color = c.lightened(0.6)
	_mat.emission = c
	_halo_mat.albedo_color = Color(c.r, c.g, c.b, 0.25 if ring else 0.7)
	_core.visible = not ring
	_shape.radius = 0.55 if ring else 1.1
	base_scale = 3.0 if ring else 1.0
	scale = Vector3.ONE * base_scale
	_ring.rotation_degrees = Vector3(90, 0, 0) if ring else Vector3.ZERO
	global_position = pos
	global_transform.basis = facing.scaled(scale) if ring else Basis.IDENTITY.scaled(scale)
	_facing = facing
	active = true
	visible = true
	set_deferred("monitorable", true)


func collect() -> void:
	deactivate()


func deactivate() -> void:
	active = false
	visible = false
	set_deferred("monitorable", false)
