class_name PaletteButton
extends TextureButton
## Large round colour swatch. Colour lives in self_modulate so modulate.a can dim it.

var color_id: StringName
var color: Color

var _halo: TextureRect
var _tween: Tween
var _fade: Tween

func setup(id: StringName, col: Color, px: int, circle_tex: Texture2D, ring_tex: Texture2D) -> void:
	color_id = id
	color = col
	custom_minimum_size = Vector2(px, px)
	size = Vector2(px, px)
	pivot_offset = size * 0.5
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	texture_normal = circle_tex
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE
	self_modulate = col
	focus_mode = Control.FOCUS_NONE

	_halo = TextureRect.new()
	_halo.texture = ring_tex
	_halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_halo.position = Vector2(-20, -20)
	_halo.size = size + Vector2(40, 40)
	_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_halo.visible = false
	add_child(_halo)

func contains_point(p: Vector2) -> bool:
	var center := global_position + size * 0.5
	return p.distance_to(center) <= size.x * 0.5 + 16.0   # generous grace margin

func pulse() -> void:
	stop_pulse()
	_halo.visible = true
	_halo.self_modulate = Color("ffc400")
	_tween = create_tween().set_loops()
	_tween.tween_method(_apply_pulse, 0.0, 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_apply_pulse, 1.0, 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply_pulse(v: float) -> void:
	scale = Vector2.ONE * lerpf(1.0, 1.16, v)
	_halo.modulate.a = lerpf(0.45, 1.0, v)

func stop_pulse() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	scale = Vector2.ONE
	_halo.visible = false

func set_dimmed(dim: bool) -> void:
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "modulate:a", 0.35 if dim else 1.0, 0.3)

func set_selected(on: bool) -> void:
	_halo.visible = on
	if on:
		_halo.self_modulate = Color("2fa84f")
		_halo.modulate.a = 1.0
