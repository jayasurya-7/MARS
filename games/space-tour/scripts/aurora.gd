class_name Aurora
extends Node3D
## A huge, softly waving curtain of northern lights (vertex-colour fade + scrolling streak texture).

var _mat: StandardMaterial3D
var _t := 0.0


func setup(color: Color, width: float = 170.0, height: float = 60.0) -> void:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.03
	noise.seed = randi()
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.2), Color(1, 1, 1, 1)])
	ramp.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.color_ramp = ramp
	tex.width = 512
	tex.height = 16
	tex.seamless = true

	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.vertex_color_use_as_albedo = true
	_mat.albedo_texture = tex

	var cols := 40
	var rows := [0.0, 0.2, 0.6, 1.0]
	var alphas := [0.0, 0.85, 0.35, 0.0]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in cols:
		for r in rows.size() - 1:
			for corner in [[0, 0], [1, 0], [0, 1], [1, 0], [1, 1], [0, 1]]:
				var ci: int = i + corner[0]
				var ri: int = r + corner[1]
				var x := (float(ci) / cols - 0.5) * width
				var z := sin(ci * 0.35) * 8.0 + sin(ci * 0.13) * 14.0
				st.set_color(Color(color.r, color.g, color.b, alphas[ri]))
				st.set_uv(Vector2(float(ci) / cols * 3.0, rows[ri]))
				st.add_vertex(Vector3(x, rows[ri] * height, z))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_t = randf() * 10.0


func _process(delta: float) -> void:
	_t += delta
	_mat.uv1_offset += Vector3(0.015 * delta, 0, 0)
	_mat.albedo_color = Color(1, 1, 1, 0.28 + 0.1 * sin(_t * 0.6))
