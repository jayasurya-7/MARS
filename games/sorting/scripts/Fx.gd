class_name SortFx
extends RefCounted
## Particle helpers (CPUParticles2D, spawned in code, self-freeing).

static var _soft_tex: GradientTexture2D


static func soft_texture() -> Texture2D:
	if _soft_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		_soft_tex = GradientTexture2D.new()
		_soft_tex.gradient = g
		_soft_tex.fill = GradientTexture2D.FILL_RADIAL
		_soft_tex.fill_from = Vector2(0.5, 0.5)
		_soft_tex.fill_to = Vector2(0.5, 0.0)
		_soft_tex.width = 48
		_soft_tex.height = 48
	return _soft_tex


static func burst(parent: Node, at: Vector2, color: Color, amount: int = 40) -> void:
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var p := CPUParticles2D.new()
	p.top_level = true
	p.z_index = 200
	p.texture = soft_texture()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.95
	p.explosiveness = 0.95
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 520)
	p.initial_velocity_min = 220.0
	p.initial_velocity_max = 540.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.5
	p.color = color.lightened(0.25)
	p.color_ramp = fade
	p.finished.connect(p.queue_free)
	parent.add_child(p)
	p.global_position = at
	p.emitting = true


static func confetti(parent: Node, width: float) -> void:
	var colors := Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
	colors.colors = PackedColorArray([
		Color(0.86, 0.55, 0.47), Color(0.5, 0.65, 0.84), Color(0.5, 0.74, 0.62),
		Color(0.87, 0.73, 0.48), Color(0.64, 0.59, 0.82)])
	var p := CPUParticles2D.new()
	p.top_level = true
	p.z_index = 300
	p.one_shot = true
	p.amount = 260
	p.lifetime = 4.5
	p.explosiveness = 0.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(width * 0.5, 10.0)
	p.direction = Vector2.DOWN
	p.spread = 25.0
	p.gravity = Vector2(0, 320)
	p.initial_velocity_min = 150.0
	p.initial_velocity_max = 380.0
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	p.scale_amount_min = 7.0
	p.scale_amount_max = 14.0
	p.color_initial_ramp = colors
	p.finished.connect(p.queue_free)
	parent.add_child(p)
	p.global_position = Vector2(width * 0.5, -30.0)
	p.emitting = true
