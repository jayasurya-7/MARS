class_name FloorPainter
extends Node
## Owns the SubViewport used as a 2D "cleaned" mask for the floor shader.
## Brush stamps are drawn into the viewport (which is never cleared after the
## first frame), so the mask accumulates. Coverage is read back periodically.

signal coverage_changed(ratio: float)
signal stroke_distance(metres: float)   # distance mopped while in contact, per physics step

## 0..1. A dirty mop paints weakly (alpha of each stamp), so you must rinse it.
@export var brush_strength := 1.0

@export var floor_size := Vector2(6.0, 4.0)          # world metres (X, Z)
@export var floor_center := Vector3.ZERO
@export var mask_resolution := 512
@export var brush_world_radius := 0.38             # bigger brush = easier coverage
@export var contact_height := 0.15                    # mop must be this close to floor to paint
@export var analyze_enabled := true
@export var analyze_interval := 0.5
@export var analysis_resolution := 128
@export var clean_threshold := 128                    # 0..255 on L8 image
@export var max_stroke_jump := 1.0                    # metres; larger = teleport (e.g. calibrate)

var obstacles: Array[Rect2] = []   # furniture footprints (world XZ) excluded from coverage
var viewport: SubViewport
var coverage := 0.0

var _stamp_root: Node2D
var _brush_tex: Texture2D
var _brush_mat: CanvasItemMaterial
var _dirty_mat: CanvasItemMaterial
var _tracked: Area3D
var _last_px := Vector2.ZERO
var _has_last := false
var _stamps: Array = []        # [Sprite2D, frame_created]
var _timer := 0.0
var _walkable := PackedByteArray()


func _ready() -> void:
	_build_viewport()
	_brush_tex = _make_brush_texture()
	_brush_mat = CanvasItemMaterial.new()
	_brush_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_dirty_mat = CanvasItemMaterial.new()
	_dirty_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB


func mask_texture() -> Texture2D:
	return viewport.get_texture()


## The Area3D whose world position drives painting.
func track(area: Area3D) -> void:
	_tracked = area
	_has_last = false


func reset_stroke() -> void:
	_has_last = false


## Wipes the mask back to fully dirty (new level).
func clear() -> void:
	for e in _stamps:
		(e[0] as Sprite2D).queue_free()
	_stamps.clear()
	_has_last = false
	coverage = 0.0
	_timer = -1.0
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER


func _build_viewport() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(mask_resolution, mask_resolution)
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Clear to black once, then accumulate strokes forever.
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	add_child(viewport)
	_stamp_root = Node2D.new()
	viewport.add_child(_stamp_root)


func _make_brush_texture() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t


func world_to_mask_px(p: Vector3) -> Vector2:
	var local := p - floor_center
	var uv := Vector2(local.x / floor_size.x + 0.5, local.z / floor_size.y + 0.5)
	return uv * float(mask_resolution)


func _physics_process(_delta: float) -> void:
	if _tracked == null:
		return
	var pos := _tracked.global_position
	if pos.y - floor_center.y > contact_height:
		_has_last = false
		return
	var px := world_to_mask_px(pos)
	var brush_px := brush_world_radius / floor_size.x * float(mask_resolution)
	if _has_last:
		var jump_m := (px - _last_px).length() / float(mask_resolution) * floor_size.x
		if jump_m > max_stroke_jump:
			_has_last = false
	if not _has_last:
		_stamp(px, brush_px)
	else:
		var dist := _last_px.distance_to(px)
		stroke_distance.emit(dist / float(mask_resolution) * floor_size.x)
		var step := maxf(brush_px * 0.35, 1.0)
		var n := int(ceil(dist / step))
		for i in range(1, n + 1):
			_stamp(_last_px.lerp(px, float(i) / float(n)), brush_px)
	_last_px = px
	_has_last = true


func _stamp(px: Vector2, brush_px: float) -> void:
	_add_stamp(px, brush_px, _brush_mat, brush_strength)


func _add_stamp(px: Vector2, brush_px: float, mat: CanvasItemMaterial, strength: float) -> void:
	var s := Sprite2D.new()
	s.texture = _brush_tex
	s.material = mat
	s.modulate = Color(1, 1, 1, strength)
	s.position = px
	s.scale = Vector2.ONE * (brush_px * 2.0 / float(_brush_tex.get_width()))
	_stamp_root.add_child(s)
	_stamps.append([s, Engine.get_process_frames()])


## Re-dirties a round patch of floor (muddy paws, spills, fallen leaves).
func dirty_spot(world: Vector3, radius_m: float) -> void:
	var r_px := radius_m / floor_size.x * float(mask_resolution)
	_add_stamp(world_to_mask_px(world), r_px, _dirty_mat, 1.0)


## Call after the furniture layout changes.
func invalidate_walkable() -> void:
	_walkable = PackedByteArray()


func _process(delta: float) -> void:
	# Free stamps only after the viewport has rendered them at least once.
	var frame := Engine.get_process_frames()
	while not _stamps.is_empty() and frame > int(_stamps[0][1]) + 2:
		var entry: Array = _stamps.pop_front()
		(entry[0] as Sprite2D).queue_free()

	if not analyze_enabled:
		return
	_timer += delta
	if _timer >= analyze_interval:
		_timer = 0.0
		update_coverage()


## Reads the mask back from the GPU and computes the fraction of cleaned pixels.
func update_coverage() -> float:
	var img := viewport.get_texture().get_image()
	if img == null or img.is_empty():
		return coverage
	img.resize(analysis_resolution, analysis_resolution, Image.INTERPOLATE_NEAREST)
	img.convert(Image.FORMAT_L8)
	var data := img.get_data()
	if _walkable.size() != data.size():
		_build_walkable()
	var cleaned := 0
	var total := 0
	for i in data.size():
		if _walkable[i] == 0:
			continue
		total += 1
		if data[i] >= clean_threshold:
			cleaned += 1
	coverage = float(cleaned) / float(maxi(total, 1))
	coverage_changed.emit(coverage)
	return coverage


## Pixels deep under furniture can never be mopped, so they don't count towards progress.
func _build_walkable() -> void:
	var n := analysis_resolution
	_walkable = PackedByteArray()
	_walkable.resize(n * n)
	var inner: Array[Rect2] = []
	for r in obstacles:
		var g := r.grow(-0.3)       # the brush reaches ~0.3 m into a footprint
		if g.size.x > 0.0 and g.size.y > 0.0:
			inner.append(g)
	for y in n:
		for x in n:
			var w := Vector2(
				((x + 0.5) / n - 0.5) * floor_size.x + floor_center.x,
				((y + 0.5) / n - 0.5) * floor_size.y + floor_center.z)
			var ok := 1
			for g in inner:
				if g.has_point(w):
					ok = 0
					break
			_walkable[y * n + x] = ok
