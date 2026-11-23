class_name LevelManager
extends Node2D
## Game loop: prompt colour -> dwell on palette -> prompt region -> dwell on region -> fill -> next.
## Designed for planar (MLAP) robot input such as MARS: the robot just moves the OS cursor.
## No clicking is needed: HOLDING the cursor still on the glowing target selects/paints it.
##
## In MARS HOMER (game "DR", combined movement, patient-paced): every shape to colour is one target
## (choosing its colour is part of it), coloured = hit. Nothing can be missed. The app runs the 60 s.

signal color_required(color_id: StringName)
signal color_selected(color_id: StringName)
signal region_completed(region: ColorRegion)
signal level_completed

enum State { SELECT_COLOR, PAINT, BUSY, DONE }

## Seconds the cursor must stay on a target. Raise for patients with more tremor.
@export_range(0.3, 5.0, 0.1) var dwell_seconds := 0.3
## Cursor low-pass filter (smooths tremor). Lower = smoother but laggier.
@export_range(2.0, 40.0, 0.5) var cursor_follow_speed := 12.0
## Pause after a region is filled before the next prompt.
@export_range(0.2, 4.0, 0.1) var celebration_seconds := 0.5
## Seconds of celebration after a finished picture before the next one loads automatically.
@export_range(1.0, 15.0, 0.5) var next_picture_delay := 4.5
@export var hide_system_cursor := true
## Show "Bindu", the cheering helper in the bottom-left corner.
@export var show_buddy := true
## Seconds without progress before Bindu gives a gentle, friendly nudge.
@export_range(5.0, 60.0, 1.0) var buddy_idle_seconds := 14.0
## Written instructions appear only after this many seconds without progress.
@export_range(1.0, 30.0, 0.5) var hint_delay_seconds := 6.0
## Slowly drifting clouds / specks in the background. Turn off for patients who find motion distracting.
@export var animated_background := true

const SCREEN := Vector2(1920, 1080)
const CANVAS_POS := Vector2(360, 350)
const PALETTE_X := 1750.0
const SWATCH := 130
const INK := Color("1f2230")

## Set by the app's Pause button and while MARS is held.
var paused := false
var current_required_color: StringName = &""
var player_selected_color: StringName = &""
var state := State.SELECT_COLOR

var _regions: Array[ColorRegion] = []     # draw order (last = on top)
var _steps: Array[ColorRegion] = []       # colouring order
var _step_index := 0
var current_region: ColorRegion
var _buttons: Dictionary = {}              # StringName -> PaletteButton

var _cursor: BrushCursor
var _cursor_pos := Vector2.ZERO
var _dwell_target: Object
var _dwell := 0.0

var _canvas: Node2D
var _hint: Label
var _progress: ProgressBar
var _banner: Label                         # big "Well done!" shown before auto-advancing
var _score_badge: PanelContainer
var _score_label: Label
## Session score: +1 for every coloured part (resets when the game is restarted).
var score := 0
var _confetti: CPUParticles2D
var _circle_tex: Texture2D
var _ring_tex: Texture2D
var _star_tex: Texture2D
var _ref_root: Node2D
var _title: Label
var _picture_index := 0
var _session := 0                          # bumps on every picture change (cancels stale awaits)
var _buddy: Buddy
var _idle := 0.0                           # seconds since the player last made progress
var _next_nudge := 0.0
var _hint_panel: PanelContainer
var _hint_shown := false
var _hint_tween: Tween

const SAVE_PATH := "user://drawing_progress.cfg"


func _ready() -> void:
	if hide_system_cursor:
		pass # The app keeps the mouse visible for its own Pause / Exit buttons.
	_circle_tex = Shapes.circle(128)
	_ring_tex = Shapes.ring(128, 9.0)
	_star_tex = Shapes.star(40)

	_build_background()
	_build_canvas()
	_build_reference()
	_build_palette()
	_build_hud()
	# The app's HUD shows the score and time at the top.
	_title.visible = false
	_progress.visible = false
	if _score_badge:
		_score_badge.visible = false
	if show_buddy:
		_buddy = Buddy.new()
		_buddy.name = "Buddy"
		_buddy.position = Vector2(185, 955)
		add_child(_buddy)
	_build_cursor()

	_cursor_pos = GamePointer.screen(self)
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		_picture_index = int(cfg.get_value("game", "picture", 0))
	_load_picture(_picture_index)


# ───────────────────────────── scene construction ─────────────────────────────

func _build_background() -> void:
	var bg := FreshBackground.new()
	bg.name = "Background"
	bg.animated = animated_background
	add_child(bg)


func _rounded_style(color: Color, radius: int, shadow := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	if shadow > 0:
		sb.shadow_size = shadow
		sb.shadow_color = Color(0, 0, 0, 0.22)
		sb.shadow_offset = Vector2(0, 8)
	return sb


func _build_canvas() -> void:
	var paper := Panel.new()
	paper.name = "Paper"
	paper.position = CANVAS_POS - Vector2(20, 20)
	paper.size = LevelData.CANVAS_SIZE + Vector2(40, 40)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_theme_stylebox_override("panel", _rounded_style(Color("fffdf8"), 30, 26))
	add_child(paper)

	_canvas = Node2D.new()
	_canvas.name = "Canvas"
	_canvas.position = CANVAS_POS
	add_child(_canvas)

	# regions are created per picture in _load_picture()


func _build_reference() -> void:
	var frame := Panel.new()
	frame.name = "ReferenceFrame"
	frame.size = Vector2(504, 296)
	frame.position = Vector2(SCREEN.x * 0.5 - 252, 16)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _rounded_style(Color("fffdf8"), 22, 16))
	add_child(frame)

	var vp := SubViewport.new()
	vp.name = "ReferenceViewport"
	vp.size = Vector2i(480, 272)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	_ref_root = Node2D.new()
	_ref_root.scale = Vector2.ONE * 0.4
	vp.add_child(_ref_root)

	var ref := TextureRect.new()
	ref.name = "ReferenceImage"
	ref.texture = vp.get_texture()
	ref.position = Vector2(12, 12)
	ref.size = Vector2(480, 272)
	ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(ref)


func _build_palette() -> void:
	var backing := Panel.new()
	backing.name = "PaletteBacking"
	backing.position = Vector2(PALETTE_X - 100, 60)
	backing.size = Vector2(200, 960)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.add_theme_stylebox_override("panel", _rounded_style(Color(1, 1, 1, 0.65), 44, 14))
	add_child(backing)

	var box := VBoxContainer.new()
	box.name = "Palette"
	box.add_theme_constant_override("separation", 22)
	var n := LevelData.PALETTE.size()
	var h := n * SWATCH + (n - 1) * 22
	box.position = Vector2(PALETTE_X - SWATCH * 0.5, (SCREEN.y - h) * 0.5)
	box.custom_minimum_size = Vector2(SWATCH, h)
	add_child(box)
	for id: StringName in LevelData.PALETTE:
		var b := PaletteButton.new()
		b.name = String(id).capitalize()
		box.add_child(b)
		b.setup(id, LevelData.PALETTE[id], SWATCH, _circle_tex, _ring_tex)
		b.pressed.connect(_on_palette_pressed.bind(b))   # real click also works
		_buttons[id] = b


func _build_hud() -> void:
	_title = Label.new()
	_title.position = Vector2(40, 20)
	_title.custom_minimum_size = Vector2(560, 0)
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", INK)
	add_child(_title)

	_progress = ProgressBar.new()
	_progress.position = Vector2(40, 100)
	_progress.size = Vector2(300, 34)
	_progress.show_percentage = false
	_progress.max_value = _steps.size()
	_progress.add_theme_stylebox_override("background", _rounded_style(Color(1, 1, 1, 0.7), 17))
	_progress.add_theme_stylebox_override("fill", _rounded_style(Color("3fb454"), 17))
	add_child(_progress)

	var panel := PanelContainer.new()
	panel.position = Vector2(30, 260)
	panel.custom_minimum_size = Vector2(320, 0)
	panel.add_theme_stylebox_override("panel", _rounded_style(Color(1, 1, 1, 0.9), 26, 12))
	panel.modulate.a = 0.0                  # hidden until the player goes quiet
	add_child(panel)
	_hint_panel = panel
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)
	_hint = Label.new()
	_hint.custom_minimum_size = Vector2(270, 0)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_font_size_override("font_size", 42)
	_hint.add_theme_color_override("font_color", INK)
	margin.add_child(_hint)

	# score badge: big star + number
	_score_badge = PanelContainer.new()
	_score_badge.position = Vector2(40, 152)
	_score_badge.add_theme_stylebox_override("panel", _rounded_style(Color(1, 1, 1, 0.92), 40, 12))
	add_child(_score_badge)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var pad := MarginContainer.new()
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, 22)
	for side in ["top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 6)
	_score_badge.add_child(pad)
	pad.add_child(row)
	var star := TextureRect.new()
	star.texture = Shapes.star(64)
	star.self_modulate = Color("ffc400")
	star.custom_minimum_size = Vector2(56, 56)
	star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(star)
	_score_label = Label.new()
	_score_label.text = "0"
	_score_label.add_theme_font_size_override("font_size", 56)
	_score_label.add_theme_color_override("font_color", INK)
	row.add_child(_score_label)

	_banner = Label.new()
	_banner.text = "Well done!"
	_banner.size = Vector2(LevelData.CANVAS_SIZE.x, 200)
	_banner.position = Vector2(CANVAS_POS.x, CANVAS_POS.y + 240)
	_banner.pivot_offset = _banner.size * 0.5
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 130)
	_banner.add_theme_color_override("font_color", Color.WHITE)
	_banner.add_theme_color_override("font_outline_color", INK)
	_banner.add_theme_constant_override("outline_size", 22)
	_banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.3))
	_banner.add_theme_constant_override("shadow_offset_y", 8)
	_banner.visible = false
	add_child(_banner)

	_confetti = CPUParticles2D.new()
	_confetti.position = Vector2(SCREEN.x * 0.5, -30)
	_confetti.emitting = false
	_confetti.one_shot = true
	_confetti.amount = 140
	_confetti.lifetime = 4.5
	_confetti.explosiveness = 0.15
	_confetti.texture = _star_tex
	_confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_confetti.emission_rect_extents = Vector2(900, 10)
	_confetti.direction = Vector2.DOWN
	_confetti.spread = 25.0
	_confetti.initial_velocity_min = 150.0
	_confetti.initial_velocity_max = 350.0
	_confetti.gravity = Vector2(0, 160)
	_confetti.scale_amount_min = 0.7
	_confetti.scale_amount_max = 1.6
	_confetti.angular_velocity_min = -200.0
	_confetti.angular_velocity_max = 200.0
	var ramp := Gradient.new()
	var cols := PackedColorArray(LevelData.PALETTE.values())
	ramp.colors = cols
	ramp.offsets = PackedFloat32Array(range(cols.size()).map(func(i: int) -> float: return i / float(cols.size() - 1)))
	_confetti.color_initial_ramp = ramp
	add_child(_confetti)


func _build_cursor() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_cursor = BrushCursor.new()
	_cursor.name = "BrushCursor"
	layer.add_child(_cursor)


# ───────────────────────────────── game loop ─────────────────────────────────

func _load_picture(index: int) -> void:
	_session += 1
	_picture_index = posmod(index, LevelData.count())
	var cfg := ConfigFile.new()
	cfg.set_value("game", "picture", _picture_index)
	cfg.save(SAVE_PATH)

	var data := LevelData.build(_picture_index)
	_title.text = "%d / %d  %s" % [_picture_index + 1, LevelData.count(), data.title]

	# canvas regions
	for r in _regions:
		r.queue_free()
	_regions.clear()
	for d: Dictionary in data.regions:
		var r := ColorRegion.new()
		r.name = d.name
		_canvas.add_child(r)
		r.setup(d, LevelData.PALETTE[d.color], _star_tex)
		_regions.append(r)
	_steps = _regions.duplicate()

	# reference picture (fully coloured copy)
	for ch in _ref_root.get_children():
		ch.queue_free()
	var white := Polygon2D.new()
	white.polygon = LevelData.rect(0, 0, 1200, 680)
	_ref_root.add_child(white)
	for d: Dictionary in data.regions:
		var p := Polygon2D.new()
		p.polygon = d.poly
		p.color = LevelData.PALETTE[d.color]
		_ref_root.add_child(p)
		var l := Line2D.new()
		l.points = d.poly
		l.closed = true
		l.width = 7.0
		l.default_color = INK
		l.joint_mode = Line2D.LINE_JOINT_ROUND
		_ref_root.add_child(l)
		for det: PackedVector2Array in d.details:
			var dl := Line2D.new()
			dl.points = det
			dl.width = 5.0
			dl.default_color = INK
			_ref_root.add_child(dl)

	_progress.max_value = _steps.size()
	_start_level()


func _start_level() -> void:
	_step_index = 0
	_dwell_target = null
	_dwell = 0.0
	player_selected_color = &""
	_cursor.clear_brush()
	_progress.value = 0
	_banner.visible = false
	_confetti.emitting = false
	for b: PaletteButton in _buttons.values():
		b.stop_pulse()
		b.set_selected(false)
	_on_progress()
	if _buddy:
		_buddy.set_color(Color("8fd0ff"))
		_buddy.say("Let's colour the %s!" % LevelData.build(_picture_index).title.to_lower(), 3.0)
		_buddy.wave(1.0)
	_next_step()


func _next_step() -> void:
	if _step_index >= _steps.size():
		_finish_level()
		return
	current_region = _steps[_step_index]
	current_required_color = current_region.color_id
	color_required.emit(current_required_color)

	if player_selected_color == current_required_color:
		_begin_paint()          # already holding the right colour: skip the palette
		return

	state = State.SELECT_COLOR
	for id: StringName in _buttons:
		var b: PaletteButton = _buttons[id]
		b.set_selected(false)
		b.set_dimmed(id != current_required_color)
		if id == current_required_color:
			b.pulse()
		else:
			b.stop_pulse()
	_hint.text = "Reach the glowing %s colour and hold still." % String(current_required_color).to_upper()


func _begin_paint() -> void:
	state = State.PAINT
	current_region.highlight(true)
	_hint.text = "Now hold the brush over the glowing %s shape." % current_region.region_name.to_upper()


func _select_color(b: PaletteButton) -> void:
	player_selected_color = b.color_id
	b.stop_pulse()
	for other: PaletteButton in _buttons.values():
		other.set_dimmed(false)
		other.set_selected(other == b)
	_cursor.set_brush(b.color)
	color_selected.emit(b.color_id)
	_on_progress()
	if _buddy:
		_buddy.set_color(b.color)
		_buddy.hop(30.0)
		if randf() < 0.35:
			_buddy.say_random(&"pick", 1.6)
	_begin_paint()


## Player did something: restart the quiet-timer and tuck the instructions away.
func _on_progress() -> void:
	_idle = 0.0
	_next_nudge = buddy_idle_seconds
	_show_hint(false)


func _show_hint(on: bool) -> void:
	if on == _hint_shown:
		return
	_hint_shown = on
	if _hint_tween:
		_hint_tween.kill()
	_hint_tween = create_tween()
	_hint_tween.tween_property(_hint_panel, "modulate:a", 1.0 if on else 0.0, 0.6 if on else 0.3)


func _paint_region(r: ColorRegion) -> void:
	state = State.BUSY
	r.fill_with(LevelData.PALETTE[player_selected_color])
	Trial.resolve(true)
	region_completed.emit(r)
	_on_progress()
	_step_index += 1
	_add_score(r.to_global(r._centroid()))
	if _buddy and _step_index < _steps.size():
		_buddy.cheer()
	create_tween().tween_property(_progress, "value", float(_step_index), 0.4)
	_hint.text = "Lovely!"
	var session := _session
	await get_tree().create_timer(celebration_seconds).timeout
	if session == _session:
		_next_step()


func _finish_level() -> void:
	state = State.DONE
	for b: PaletteButton in _buttons.values():
		b.set_dimmed(false)
		b.set_selected(false)
	_confetti.restart()
	_confetti.emitting = true
	_banner.visible = true
	_banner.scale = Vector2.ONE * 0.3
	_banner.modulate.a = 0.0
	var t := create_tween().set_parallel()
	t.tween_property(_banner, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(_banner, "modulate:a", 1.0, 0.3)
	if _buddy:
		_buddy.celebrate()
	level_completed.emit()

	# Move on to the next picture automatically.
	var session := _session
	await get_tree().create_timer(next_picture_delay).timeout
	if session == _session:
		_load_picture(_picture_index + 1)


## +1 for each coloured part: floating "+1" from the shape to the badge, badge pops.
func _add_score(from_global: Vector2) -> void:
	score += 1
	var plus := Label.new()
	plus.text = "+1"
	plus.add_theme_font_size_override("font_size", 64)
	plus.add_theme_color_override("font_color", Color("ffc400"))
	plus.add_theme_color_override("font_outline_color", INK)
	plus.add_theme_constant_override("outline_size", 14)
	plus.position = from_global - Vector2(40, 45)
	plus.z_index = 50
	add_child(plus)
	var target := _score_badge.position + Vector2(70, 10)
	var t := create_tween()
	t.tween_property(plus, "position:y", plus.position.y - 60, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(plus, "position", target, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(plus, "scale", Vector2.ONE * 0.6, 0.55)
	t.tween_callback(func() -> void:
		plus.queue_free()
		_score_label.text = str(score)
		_score_badge.pivot_offset = _score_badge.size * 0.5
		var pop := create_tween()
		pop.tween_property(_score_badge, "scale", Vector2.ONE * 1.18, 0.1)
		pop.tween_property(_score_badge, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK))


func _on_palette_pressed(b: PaletteButton) -> void:
	if state == State.SELECT_COLOR and b.color_id == current_required_color:
		_select_color(b)


# ───────────────────────────── input & dwell logic ─────────────────────────────

func _top_region_at(p: Vector2) -> ColorRegion:
	for i in range(_regions.size() - 1, -1, -1):
		if _regions[i].contains_point(p):
			return _regions[i]
	return null


func _candidate_at(p: Vector2) -> Object:
	match state:
		State.SELECT_COLOR:
			var b: PaletteButton = _buttons[current_required_color]
			return b if b.contains_point(p) else null
		State.PAINT:
			return current_region if _top_region_at(p) == current_region else null
	return null


func _process(delta: float) -> void:
	if not (paused or Trial.held() or not Trial.running):
		_play(delta)
	var target := _target_point()
	Trial.advance(delta, paused, GamePointer.normalized(self), target / SCREEN)
	if Trial.running and not Trial.target_open and not paused and (state == State.SELECT_COLOR or state == State.PAINT):
		Trial.appear(target / SCREEN)


## The glowing colour to pick, else the glowing shape to paint.
func _target_point() -> Vector2:
	if state == State.SELECT_COLOR and _buttons.has(current_required_color):
		var b: PaletteButton = _buttons[current_required_color]
		return b.global_position + b.size * 0.5
	if current_region:
		return current_region.to_global(current_region._centroid())
	return SCREEN / 2.0


func _play(delta: float) -> void:
	var raw := GamePointer.screen(self)
	_cursor_pos = _cursor_pos.lerp(raw, 1.0 - exp(-cursor_follow_speed * delta))
	_cursor.position = _cursor_pos

	if _buddy:
		_buddy.cursor_pos = _cursor_pos
	if state == State.SELECT_COLOR or state == State.PAINT:
		_idle += delta
		if not _hint_shown and _idle >= hint_delay_seconds:
			_show_hint(true)
		if _buddy and _idle >= _next_nudge:
			_next_nudge += buddy_idle_seconds
			var b: PaletteButton = _buttons[current_required_color]
			var target := b.global_position + b.size * 0.5 if state == State.SELECT_COLOR \
				else current_region.to_global(current_region._centroid())
			_buddy.encourage(target)

	var cand := _candidate_at(_cursor_pos)
	if cand != null and cand == _dwell_target:
		_dwell += delta
	elif cand != null:
		_dwell_target = cand
		_dwell = 0.0
	else:
		# Forgiving: slipping off briefly (tremor) only drains progress slowly.
		_dwell = maxf(0.0, _dwell - delta * 1.0)
		if _dwell == 0.0:
			_dwell_target = null

	_cursor.set_progress(clampf(_dwell / dwell_seconds, 0.0, 1.0) if _dwell_target else 0.0)
	if _dwell_target and _dwell >= dwell_seconds:
		var t := _dwell_target
		_dwell_target = null
		_dwell = 0.0
		_cursor.set_progress(0.0)
		_activate(t)


func _activate(target: Object) -> void:
	if target is PaletteButton:
		_select_color(target)
	elif target is ColorRegion:
		_paint_region(target)


func _unhandled_input(event: InputEvent) -> void:
	if paused:
		return
	# Optional instant-paint by click (therapist / non-robot testing).
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if state == State.PAINT and _top_region_at(_cursor_pos) == current_region:
			_paint_region(current_region)
	elif event.is_action_pressed("ui_right"):   # therapist: next / previous picture
		_load_picture(_picture_index + 1)
	elif event.is_action_pressed("ui_left"):
		_load_picture(_picture_index - 1)
