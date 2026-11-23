class_name GameHud
extends CanvasLayer
## Score, progress bar, and coaching messages. Built in code.

var _score_label: Label
var _bar: ProgressBar
var _msg: Label
var _msg_tween: Tween


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_score_label = _label(root, "", 54, Vector2(80, 340), Vector2(700, 70), HORIZONTAL_ALIGNMENT_LEFT)

	_bar = ProgressBar.new()
	_bar.position = Vector2(80, 420)
	_bar.size = Vector2(560, 28)
	_bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.14)
	bg.set_corner_radius_all(14)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.6, 0.8, 0.68)
	fill.set_corner_radius_all(14)
	_bar.add_theme_stylebox_override("background", bg)
	_bar.add_theme_stylebox_override("fill", fill)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_bar)

	_msg = _label(root, "", 56, Vector2(640, 335), Vector2(760, 110), HORIZONTAL_ALIGNMENT_CENTER)



func _label(parent: Control, text: String, font_size: int, pos: Vector2, sz: Vector2, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = sz
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.18, 0.9))
	l.add_theme_constant_override("outline_size", maxi(6, font_size / 8))
	parent.add_child(l)
	return l


## In MARS HOMER the app's HUD shows score and time: hide the game's own score and bar.
func compact() -> void:
	_score_label.visible = false
	_bar.visible = false


func set_progress(score: int, sorted: int, total: int) -> void:
	_score_label.text = "Score %d     %d / %d" % [score, sorted, total]
	_bar.max_value = total
	create_tween().tween_property(_bar, "value", sorted, 0.4).set_trans(Tween.TRANS_CUBIC)


func say(text: String, color: Color = Color.WHITE, hold: float = 2.4) -> void:
	if _msg_tween:
		_msg_tween.kill()
	_msg.text = text
	_msg.add_theme_color_override("font_color", color.lightened(0.5))
	_msg.pivot_offset = _msg.size * 0.5
	_msg.modulate.a = 1.0
	_msg.scale = Vector2.ONE * 0.85
	_msg_tween = create_tween()
	_msg_tween.tween_property(_msg, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_msg_tween.tween_interval(hold)
	_msg_tween.tween_property(_msg, "modulate:a", 0.0, 0.6)

