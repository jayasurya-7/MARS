class_name Asteroid
extends Area3D
## Pooled obstacle. Area3D = overlap detection only, no physics cost.
##
## Node tree (built in _ready):
## Asteroid (Area3D)                   <- this script
## ├─ Mesh (MeshInstance3D, noise-displaced rock + normal-mapped material)
## └─ CollisionShape3D (SphereShape3D r=0.85)

const VARIANTS := 4

static var _meshes: Array[Mesh] = []
static var _material: StandardMaterial3D

static var _crystals: Array[StandardMaterial3D] = []

var tumble := Vector3.ZERO
var active := false
var passed := false
var _mi: MeshInstance3D


func _ready() -> void:
	if _meshes.is_empty():
		_build_shared()
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = _meshes[randi() % VARIANTS]
	_mi = mi
	add_child(mi)

	var shape := SphereShape3D.new()
	shape.radius = 0.85
	var cs := CollisionShape3D.new()
	cs.shape = shape
	add_child(cs)
	deactivate()


func _process(delta: float) -> void:
	if not active:
		return
	rotate_x(tumble.x * delta)
	rotate_y(tumble.y * delta)


func activate(pos: Vector3, size: float) -> void:
	global_position = pos
	scale = Vector3.ONE * size
	tumble = Vector3(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5), 0.0)
	rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
	active = true
	passed = false
	visible = true
	# Scenery only: never monitorable, so rocks are harmless.
	# ~20% are softly glowing crystal rocks.
	_mi.material_override = _crystals[randi() % _crystals.size()] if randf() < 0.08 else null


func deactivate() -> void:
	active = false
	visible = false
	monitorable = false


# --- shared rock meshes & material (built once) ------------------------------

static func _build_shared() -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.03

	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.32, 0.28, 0.26)
	_material.roughness = 0.95
	_material.metallic = 0.1
	_material.normal_enabled = true
	_material.normal_scale = 3.0
	var ntex := NoiseTexture2D.new()
	ntex.noise = noise
	ntex.as_normal_map = true
	ntex.bump_strength = 12.0
	ntex.seamless = true
	ntex.width = 512
	ntex.height = 512
	_material.normal_texture = ntex
	_material.uv1_scale = Vector3(3, 2, 1)

	for glow in [Color(0.3, 0.6, 1.0), Color(0.8, 0.35, 1.0), Color(1.0, 0.55, 0.75)]:
		var c := _material.duplicate() as StandardMaterial3D
		c.albedo_color = glow * 0.35
		c.emission_enabled = true
		c.emission = glow
		c.emission_energy_multiplier = 0.7
		c.rim_enabled = true
		c.rim = 0.3
		_crystals.append(c)

	for i in VARIANTS:
		_meshes.append(_make_rock(i * 17 + 3))


static func _make_rock(seed_value: int) -> ArrayMesh:
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.frequency = 1.1
	var sphere := SphereMesh.new()
	sphere.radial_segments = 16
	sphere.rings = 10
	sphere.radius = 1.0
	sphere.height = 2.0
	var arrays := sphere.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]

	for i in verts.size():
		var v := verts[i]
		verts[i] = v * (1.0 + n.get_noise_3dv(v * 2.0) * 0.45)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in idx:           # un-indexed so generate_normals gives faceted, jagged shading
		st.set_uv(uvs[i])
		st.add_vertex(verts[i])
	st.generate_normals()
	st.generate_tangents()
	st.set_material(_material)
	return st.commit()
