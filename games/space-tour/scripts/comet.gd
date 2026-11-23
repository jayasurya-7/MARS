class_name Comet
extends Node3D
## A slow comet drifting past with a long glowing tail. Frees itself when done.

const Fx = preload("res://games/space-tour/scripts/fx.gd")

var velocity := Vector3.ZERO
var _life := 18.0


func _ready() -> void:
	add_child(Fx.halo(3.5, Color(0.8, 0.9, 1.0, 0.7)))

	var t := GPUParticles3D.new()
	t.name = "Tail"
	t.amount = 180
	t.lifetime = 3.0
	t.local_coords = false
	t.draw_pass_1 = Fx.spark_mesh(1.4)
	t.visibility_aabb = AABB(Vector3(-80, -80, -80), Vector3(160, 160, 160))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.6
	pm.gravity = Vector3.ZERO
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 1.5
	pm.scale_min = 0.5
	pm.scale_max = 1.2
	var sc := Curve.new()
	sc.add_point(Vector2(0, 1))
	sc.add_point(Vector2(1, 0.1))
	var sct := CurveTexture.new()
	sct.curve = sc
	pm.scale_curve = sct
	pm.color_ramp = Fx.ramp(PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.6),
		Color(0.6, 0.8, 1.0, 0.35),
		Color(0.4, 0.4, 1.0, 0.0),
	]))
	t.process_material = pm
	add_child(t)


func _process(delta: float) -> void:
	global_position += velocity * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
