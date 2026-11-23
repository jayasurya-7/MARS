class_name ChaseCamera
extends Camera3D
## Chase camera riding the tour route behind the ship: lags sideways, banks into
## turns, widens FOV with speed.
##
## ChaseCamera (Camera3D)              <- this script
## ├─ Stars (GPUParticles3D)           star dust ahead of the camera
## └─ Streaks (GPUParticles3D)         warp-speed light streaks

const Fx = preload("res://games/space-tour/scripts/fx.gd")
const PT = preload("res://games/space-tour/scripts/path_track.gd")

@export var offset := Vector3(0, 2.6, 9.0)
@export var x_lag := 4.0            # higher = tighter follow
@export var bank_amount := 0.045
@export var base_fov := 72.0
@export var fov_per_speed := 8.0

var target: Player
var trauma := 0.0
var reduced_motion := false
var _lx := 0.0
var _streaks: GPUParticles3D


func shake(amount: float) -> void:
	if reduced_motion:
		return
	trauma = clampf(maxf(trauma, amount), 0.0, 1.0)


## Gentle mode: no shake, no speed streaks, no field-of-view change, no banking.
func set_reduced_motion(on: bool) -> void:
	reduced_motion = on
	_streaks.visible = not on
	if on:
		trauma = 0.0


func _ready() -> void:
	fov = base_fov
	far = 700.0
	_build_stars()
	_build_streaks()


func _process(delta: float) -> void:
	if target == null:
		return
	var follow := 1.0 - exp(-x_lag * delta)
	_lx = lerpf(_lx, target.lx, follow)

	var cam_s := target.s - offset.z
	global_position = PT.point(cam_s, _lx, offset.y)
	var look_at_pt := PT.point(target.s + 20.0, lerpf(_lx, target.lx, 0.5), 0.0)
	look_at(look_at_pt, PT.frame(cam_s).y)
	# Bank by how far the ship has pulled ahead of the camera sideways.
	rotate_object_local(Vector3.BACK, (_lx - target.lx) * (0.0 if reduced_motion else bank_amount))
	var fov_extra := 0.0 if reduced_motion else (target.current_mult - 1.0) * fov_per_speed
	fov = lerpf(fov, base_fov + fov_extra, follow)

	trauma = maxf(trauma - delta * 1.6, 0.0)
	var sh := trauma * trauma
	h_offset = randf_range(-1.0, 1.0) * sh * 0.7
	v_offset = randf_range(-1.0, 1.0) * sh * 0.7


func _build_streaks() -> void:
	var streaks := GPUParticles3D.new()
	streaks.name = "Streaks"
	streaks.amount = 180
	streaks.lifetime = 2.0
	streaks.preprocess = 2.0
	streaks.local_coords = false
	streaks.position = Vector3(0, 0, -70)
	streaks.draw_pass_1 = Fx.streak_mesh(4.0)
	streaks.visibility_aabb = AABB(Vector3(-60, -40, -250), Vector3(120, 80, 500))

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(16, 9, 70)
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.6
	pm.scale_max = 2.0
	pm.color_ramp = Fx.ramp(PackedColorArray([
		Color(0.6, 0.8, 1.0, 0.0),
		Color(0.7, 0.85, 1.0, 0.22),
		Color(1.0, 0.9, 0.8, 0.22),
		Color(1.0, 1.0, 1.0, 0.0),
	]))
	streaks.process_material = pm
	add_child(streaks)
	_streaks = streaks


func _build_stars() -> void:
	var stars := GPUParticles3D.new()
	stars.name = "Stars"
	stars.amount = 1500
	stars.lifetime = 8.0
	stars.preprocess = 8.0
	stars.local_coords = false
	stars.position = Vector3(0, 0, -140)
	stars.draw_pass_1 = Fx.spark_mesh(0.18)
	stars.visibility_aabb = AABB(Vector3(-150, -100, -400), Vector3(300, 200, 800))

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(90, 50, 140)
	pm.gravity = Vector3.ZERO
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.0
	pm.scale_min = 0.3
	pm.scale_max = 1.3
	pm.color_ramp = Fx.ramp(PackedColorArray([
		Color(1, 1, 1, 0),
		Color(0.85, 0.9, 1.0, 1),
		Color(1.0, 0.95, 0.85, 1),
		Color(1, 1, 1, 0),
	]))
	stars.process_material = pm
	add_child(stars)
