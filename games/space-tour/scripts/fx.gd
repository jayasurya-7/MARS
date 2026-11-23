extends RefCounted
## Shared visual helpers (soft additive sprites, streaks, colour ramps).

static var _dot: GradientTexture2D


static func _dot_tex() -> GradientTexture2D:
	if _dot == null:
		var g := Gradient.new()
		g.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
		_dot = GradientTexture2D.new()
		_dot.gradient = g
		_dot.fill = GradientTexture2D.FILL_RADIAL
		_dot.fill_from = Vector2(0.5, 0.5)
		_dot.fill_to = Vector2(0.5, 0.0)
		_dot.width = 64
		_dot.height = 64
	return _dot


static func spark_mesh(size: float = 0.25) -> QuadMesh:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = _dot_tex()
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = mat
	return quad


## Thin stretched box used for warp-speed streaks.
static func streak_mesh(length: float = 4.0) -> BoxMesh:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	var box := BoxMesh.new()
	box.size = Vector3(0.035, 0.035, length)
	box.material = mat
	return box


## Camera-facing soft glow sprite.
static func halo(size: float, color: Color) -> MeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_texture = _dot_tex()
	mat.albedo_color = color
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	quad.material = mat
	var mi := MeshInstance3D.new()
	mi.name = "Halo"
	mi.mesh = quad
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func ramp(colors: PackedColorArray) -> GradientTexture1D:
	var g := Gradient.new()
	var offsets := PackedFloat32Array()
	for i in colors.size():
		offsets.append(float(i) / float(colors.size() - 1))
	g.offsets = offsets
	g.colors = colors
	var t := GradientTexture1D.new()
	t.gradient = g
	return t
