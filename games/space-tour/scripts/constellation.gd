class_name Constellation
extends Node3D
## A glowing star-picture that fades in ahead of the camera as a milestone reward.

const Fx = preload("res://games/space-tour/scripts/fx.gd")

# name -> [points (-1..1), edges as index pairs]
static var SHAPES := {
	"the Swan": [
		[Vector2(-1, -0.2), Vector2(-0.6, 0.1), Vector2(-0.2, 0.3), Vector2(0.2, 0.2),
		 Vector2(0.5, 0.6), Vector2(0.8, 0.9), Vector2(0.1, -0.4), Vector2(-0.4, -0.5)],
		[[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [2, 6], [6, 7]]],
	"the Crown": [
		[Vector2(-1, -0.5), Vector2(-0.8, 0.4), Vector2(-0.4, -0.1), Vector2(0, 0.6),
		 Vector2(0.4, -0.1), Vector2(0.8, 0.4), Vector2(1, -0.5)],
		[[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 0]]],
	"the Lyre": [
		[Vector2(-0.6, -0.8), Vector2(-0.8, 0.2), Vector2(-0.4, 0.8), Vector2(0.4, 0.8),
		 Vector2(0.8, 0.2), Vector2(0.6, -0.8), Vector2(0, -0.3)],
		[[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [0, 6], [5, 6]]],
	"the Arrow": [
		[Vector2(-1, 0), Vector2(1, 0), Vector2(0.45, 0.5), Vector2(0.45, -0.5)],
		[[0, 1], [1, 2], [1, 3]]],
}

var shape_name := ""
var fade := 0.0:
	set(v):
		fade = v
		_apply()

var _halo_mats: Array[StandardMaterial3D] = []
var _halo_alpha: Array[float] = []
var _line_mat: StandardMaterial3D
var _color := Color.WHITE


## Builds shape number `index` (wraps around) and plays its fade in / hold / fade out.
func show_shape(index: int) -> String:
	var names := SHAPES.keys()
	shape_name = names[index % names.size()]
	_color = Color.from_hsv(randf_range(0.5, 0.95), 0.35, 1.0)
	var pts: Array = SHAPES[shape_name][0]
	var edges: Array = SHAPES[shape_name][1]
	var scl := Vector2(18.0, 8.0)

	_line_mat = StandardMaterial3D.new()
	_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _line_mat)
	for e in edges:
		var a: Vector2 = pts[e[0]] * scl
		var b: Vector2 = pts[e[1]] * scl
		im.surface_add_vertex(Vector3(a.x, a.y, 0))
		im.surface_add_vertex(Vector3(b.x, b.y, 0))
	im.surface_end()
	var lines := MeshInstance3D.new()
	lines.mesh = im
	add_child(lines)

	for p in pts:
		var q: Vector2 = p * scl
		for layer in [[2.4, 0.5], [0.8, 0.95]]:
			var h := Fx.halo(layer[0], Color(_color.r, _color.g, _color.b, layer[1]))
			h.position = Vector3(q.x, q.y, 0)
			add_child(h)
			_halo_mats.append((h.mesh as QuadMesh).material as StandardMaterial3D)
			_halo_alpha.append(layer[1])

	fade = 0.0
	var tw := create_tween()
	tw.tween_property(self, "fade", 1.0, 1.8)
	tw.tween_interval(4.0)
	tw.tween_property(self, "fade", 0.0, 2.2)
	tw.tween_callback(queue_free)
	return shape_name


func _apply() -> void:
	if _line_mat == null:
		return
	_line_mat.albedo_color = Color(_color.r, _color.g, _color.b, 0.6 * fade)
	for i in _halo_mats.size():
		_halo_mats[i].albedo_color = Color(_color.r, _color.g, _color.b, _halo_alpha[i] * fade)
