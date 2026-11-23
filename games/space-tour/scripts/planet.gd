class_name Planet
extends Node3D
## Scenery landmark for the tour: a banded planet with an atmosphere glow and optional ring.

const Fx = preload("res://games/space-tour/scripts/fx.gd")

var _spin := 0.0
var _moons: Array[Dictionary] = []
var _clouds: MeshInstance3D


func setup(radius: float, color: Color, with_ring: bool) -> void:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.012
	noise.seed = randi()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([color.darkened(0.55), color, color.lightened(0.45)])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.color_ramp = grad
	tex.width = 512
	tex.height = 256
	tex.seamless = true

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.85
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.06
	mat.rim_enabled = true
	mat.rim = 0.35
	mat.rim_tint = 0.6

	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 48
	sphere.rings = 24
	sphere.material = mat
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = sphere
	add_child(mi)

	add_child(Fx.halo(radius * 3.4, Color(color.r, color.g, color.b, 0.2)))

	if with_ring:
		var tor := TorusMesh.new()
		tor.inner_radius = radius * 1.4
		tor.outer_radius = radius * 2.2
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = color.lightened(0.5)
		rmat.roughness = 0.9
		rmat.emission_enabled = true
		rmat.emission = color.lightened(0.3)
		rmat.emission_energy_multiplier = 0.2
		tor.material = rmat
		var ring := MeshInstance3D.new()
		ring.name = "Ring"
		ring.mesh = tor
		ring.scale = Vector3(1, 0.02, 1)
		ring.rotation_degrees = Vector3(randf_range(-30, 30), 0, randf_range(-30, 30))
		add_child(ring)

	if randf() < 0.6:
		var cn := FastNoiseLite.new()
		cn.frequency = 0.02
		cn.seed = randi()
		var cr := Gradient.new()
		cr.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 0.85)])
		cr.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		var ctex := NoiseTexture2D.new()
		ctex.noise = cn
		ctex.color_ramp = cr
		ctex.width = 512
		ctex.height = 256
		ctex.seamless = true
		var cmat := StandardMaterial3D.new()
		cmat.albedo_texture = ctex
		cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cmat.roughness = 1.0
		var cs := SphereMesh.new()
		cs.radius = radius * 1.03
		cs.height = radius * 2.06
		cs.radial_segments = 48
		cs.rings = 24
		cs.material = cmat
		_clouds = MeshInstance3D.new()
		_clouds.name = "Clouds"
		_clouds.mesh = cs
		add_child(_clouds)

	for i in randi_range(0, 2):
		var pivot := Node3D.new()
		pivot.rotation = Vector3(randf_range(-0.4, 0.4), randf() * TAU, 0)
		var msphere := SphereMesh.new()
		var mr := radius * randf_range(0.12, 0.25)
		msphere.radius = mr
		msphere.height = mr * 2.0
		var mmat := StandardMaterial3D.new()
		mmat.albedo_color = Color(0.7, 0.7, 0.72)
		mmat.roughness = 0.95
		msphere.material = mmat
		var moon := MeshInstance3D.new()
		moon.name = "Moon"
		moon.mesh = msphere
		moon.position = Vector3(radius * randf_range(2.4, 3.6), 0, 0)
		pivot.add_child(moon)
		add_child(pivot)
		_moons.append({"pivot": pivot, "speed": randf_range(0.05, 0.15)})

	_spin = randf_range(0.02, 0.08)
	rotation = Vector3(randf() * TAU, randf() * TAU, 0)


func _process(delta: float) -> void:
	rotate_y(_spin * delta)
	if _clouds:
		_clouds.rotate_y(_spin * 1.8 * delta)
	for m in _moons:
		(m["pivot"] as Node3D).rotate_y(m["speed"] * delta)
