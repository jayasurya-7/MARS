class_name MopHud
extends CanvasLayer
## Accessible frosted-glass HUD: large text, high-contrast dark-on-light,
## big progress bars and large buttons. Built in code.

signal pause_toggled(paused: bool)
signal recalibrate_requested
signal auto_range_toggled(on: bool)
signal dust_rate_changed(rate: float)

const GLASS_SHADER := preload("res://games/mopping/shaders/frosted_glass.gdshader")
const TEXT_COLOR := Color(0.06, 0.07, 0.10)
const FONT_BIG := 24
const FONT_MED := 18

var _speed_label: Label
var _speed_slider: HSlider
var _task_label: Label
var _pause_btn: Button
var _banner: Label
var _hint: Label
var _status: Label


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS   # stay interactive while the game is paused

	# Forces a copy of the rendered 3D scene so the glass shader can sample it.
	var bbc := BackBufferCopy.new()
	bbc.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(bbc)

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		root.add_theme_constant_override("margin_" + side, 14)
	add_child(root)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vbox)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 12)
	vbox.add_child(top)

	# --- Task completion panel
	var task_panel := _glass_panel()
	top.add_child(task_panel)
	_task_label = _label("Dust cleaned: 0", FONT_BIG)
	task_panel.get_child(0).add_child(_task_label)

	# --- Dust speed panel
	var speed_panel := _glass_panel()
	top.add_child(speed_panel)
	var speed_box := VBoxContainer.new()
	speed_box.add_theme_constant_override("separation", 4)
	speed_panel.get_child(0).add_child(speed_box)
	_speed_label = _label("Dust speed: Normal", FONT_MED)
	speed_box.add_child(_speed_label)
	_speed_slider = HSlider.new()
	_speed_slider.min_value = 0.0
	_speed_slider.max_value = 4.0
	_speed_slider.step = 0.25
	_speed_slider.value = 1.0
	_speed_slider.custom_minimum_size = Vector2(230, 24)
	_speed_slider.focus_mode = Control.FOCUS_NONE
	_speed_slider.value_changed.connect(func(v: float):
		_update_speed_label(v)
		dust_rate_changed.emit(v))
	speed_box.add_child(_speed_slider)

	_hint = _label("", 28)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_color_override("font_outline_color", Color.WHITE)
	_hint.add_theme_constant_override("outline_size", 10)
	vbox.add_child(_hint)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)

	# --- Buttons panel (bottom-left)
	var bottom := HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom)
	var btn_panel := _glass_panel()
	bottom.add_child(btn_panel)
	var btn_box := HBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 10)
	btn_panel.get_child(0).add_child(btn_box)
	_pause_btn = _button("Pause")
	_pause_btn.toggle_mode = true
	_pause_btn.toggled.connect(_on_pause_toggled)
	btn_box.add_child(_pause_btn)
	var recal := _button("Recalibrate")
	recal.pressed.connect(func(): recalibrate_requested.emit())
	btn_box.add_child(recal)
	var auto_btn := _button("Auto range: off")
	auto_btn.toggle_mode = true
	auto_btn.custom_minimum_size.x = 170
	auto_btn.toggled.connect(func(on: bool):
		auto_btn.text = "Auto range: on" if on else "Auto range: off"
		auto_range_toggled.emit(on))
	btn_box.add_child(auto_btn)

	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(gap)
	var status_panel := _glass_panel()
	status_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom.add_child(status_panel)
	_status = _label("", 16)
	_status.clip_text = true
	_status.custom_minimum_size.x = 260
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_panel.get_child(0).add_child(_status)

	# --- Completion banner
	_banner = _label("Floor complete!", 44)
	_banner.visible = false
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_color_override("font_outline_color", Color.WHITE)
	_banner.add_theme_constant_override("outline_size", 12)
	root.add_child(_banner)

	_build_help()


# ---------------------------------------------------------------- public API
func set_dust(cleaned: int) -> void:
	_task_label.text = "Dust cleaned: %d" % cleaned


func get_dust_rate() -> float:
	return _speed_slider.value


func nudge_dust_rate(step: float) -> void:
	_speed_slider.value = clampf(_speed_slider.value + step, _speed_slider.min_value, _speed_slider.max_value)


func _update_speed_label(v: float) -> void:
	var word := "Off"
	if v > 0.0:
		word = "Very slow" if v < 0.6 else "Slow" if v < 0.9 else "Normal" if v < 1.4 else "Fast" if v < 2.5 else "Very fast"
	_speed_label.text = "Dust speed: %s" % word


func hide_complete() -> void:
	_banner.visible = false


func set_hint(text: String) -> void:
	_hint.text = text


func set_device_status(text: String) -> void:
	_status.text = text


func show_complete(text := "Floor complete!") -> void:
	_banner.text = text
	_banner.visible = true


# ---------------------------------------------------------------- builders
func _on_pause_toggled(on: bool) -> void:
	_pause_btn.text = "Resume" if on else "Pause"
	pause_toggled.emit(on)


## PanelContainer with the frosted-glass shader. Returns the panel; its first
## child is a MarginContainer to put content in.
func _glass_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()          # plain white rect; the shader shapes + tints it
	sb.bg_color = Color.WHITE
	panel.add_theme_stylebox_override("panel", sb)
	var mat := ShaderMaterial.new()
	mat.shader = GLASS_SHADER
	panel.material = mat
	panel.resized.connect(func(): mat.set_shader_parameter("panel_size", panel.size))
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(m)
	return panel


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", TEXT_COLOR)
	return l


func _progress_bar(fill_color := Color(0.0, 0.42, 0.85)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(300, 22)
	bar.show_percentage = false
	bar.max_value = 100.0
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.1, 0.12, 0.45)
	bg.set_corner_radius_all(11)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color                  # strong colour, high contrast on light glass
	fill.set_corner_radius_all(11)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 44)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", TEXT_COLOR)
	b.add_theme_color_override("font_hover_color", TEXT_COLOR)
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	var n := StyleBoxFlat.new()
	n.bg_color = Color(1, 1, 1, 0.85)
	n.set_corner_radius_all(12)
	n.set_border_width_all(2)
	n.border_color = Color(0.1, 0.1, 0.12)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.85, 0.93, 1.0)
	var p := n.duplicate() as StyleBoxFlat
	p.bg_color = Color(0.0, 0.42, 0.85)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("hover_pressed", p)
	b.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", TEXT_COLOR)
	b.add_theme_stylebox_override("focus", h)
	return b


# ---------------------------------------------------------------- how to play
func _build_help() -> void:
	var help := _glass_panel()
	help.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	help.grow_horizontal = Control.GROW_DIRECTION_BOTH
	help.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(help)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	help.get_child(0).add_child(box)
	box.add_child(_label("HOW TO PLAY", 26))
	for line in [
		"1.  Move the mouse (or lean) - the cleaner walks there.",
		"2.  The cat chases the mouse and they make a mess - dust piles!",
		"3.  Sweep the mop over each dust pile to clean it.",
		"4.  Use the Dust speed slider (or + / - keys) to make less or more dust.",
		"5.  Press Recalibrate (or R) to set your centre position.",
	]:
		box.add_child(_label(line, 18))
	var ok := _button("Got it")
	ok.pressed.connect(help.hide)
	box.add_child(ok)
	get_tree().create_timer(20.0).timeout.connect(help.hide)
