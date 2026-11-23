class_name Jelly
extends Node3D
## A gently pulsing, glowing space jellyfish that floats beside the route.

const Fx = preload("res://games/space-tour/scripts/fx.gd")

var _body: Node3D
var _dome: MeshInstance3D
var _tentacles: Array[Node3D] = []
var _t := 0.0


func setup(color: Color, size: float) -> void:
	_t = randf() * 20.0
	scale = Vector3.ONE * size

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.18)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.4
	mat.rim_enabled = true
	mat.rim = 0.3

	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	var dome_mesh := SphereMesh.new()
	dome_mesh.radius = 1.0
	dome_mesh.height = 1.0
	dome_mesh.is_hemisphere = true
	dome_mesh.material = mat
	_dome = MeshInstance3D.new()
	_dome.mesh = dome_mesh
	_body.add_child(_dome)

	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(color.r, color.g, color.b, 0.3)
	tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tmat.emission_enabled = true
	tmat.emission = color
	tmat.emission_energy_multiplier = 0.3
	for i in 7:
		var a := TAU * i / 7.0
		var pivot := Node3D.new()
		pivot.position = Vector3(cos(a) * 0.6, 0, sin(a) * 0.6)
		var cap := CapsuleMesh.new()
		cap.radius = 0.03
		cap.height = 3.0
		cap.material = tmat
		var mi := MeshInstance3D.new()
		mi.mesh = cap
		mi.position = Vector3(0, -1.5, 0)
		pivot.add_child(mi)
		_body.add_child(pivot)
		_tentacles.append(pivot)

	var halo := Fx.halo(5.0, Color(color.r, color.g, color.b, 0.07))
	halo.position = Vector3(0, 0.2, 0)
	_body.add_child(halo)


func _process(delta: float) -> void:
	_t += delta
	var pulse := sin(_t * 1.8)
	_dome.scale = Vector3(1.0 + 0.08 * pulse, 1.0 - 0.12 * pulse, 1.0 + 0.08 * pulse)
	_body.position.y = sin(_t * 0.7) * 0.8
	for i in _tentacles.size():
		_tentacles[i].rotation = Vector3(sin(_t * 1.3 + i) * 0.22, 0, cos(_t * 1.1 + i * 1.7) * 0.22)
