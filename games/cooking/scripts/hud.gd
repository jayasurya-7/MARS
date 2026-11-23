class_name Hud
extends CanvasLayer
## Display only. The game logic lives in main.gd.

const LOW_TIME_SECONDS := 10
const CREAM := Color("fff1ce")
const OUTLINE := Color("3a2414")

var _objective := ""
var _speech := ""
var _speech_until := 0
var _objective_style: StyleBox
var _speech_style: StyleBoxFlat

@onready var accuracy_gauge: HudArt = %Art
@onready var score_label: Label = %ScoreLabel
@onready var time_label: Label = %TimeLabel
@onready var accuracy_label: Label = %AccuracyLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var center_panel: PanelContainer = %CenterPanel
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var tracking_banner: PanelContainer = %TrackingBanner


func _ready() -> void:
	# A chunky face on Windows; other systems quietly fall back to the default font.
	var heading: Font = preload("res://core/ui_theme.gd").DISPLAY
	var headings: Array[Label] = [
		%PlaqueTitle, time_label, score_label, accuracy_label, title_label, objective_label,
	]
	for label in headings:
		label.add_theme_font_override("font", heading)
		_ink(label, CREAM, 7)
	_ink(%PlaqueTitle, Color("ffcf5a"), 9)
	_ink(%PlaqueSteps, Color("a6f5b4"), 5)
	_ink(%AccuracyCaption, Color("f3dcab"), 4)
	_ink(body_label, CREAM, 5)
	tracking_banner.visible = false
	# Kept clean: no accuracy readout and no step instructions on screen.
	for node: CanvasItem in [%AccuracyCaption, accuracy_label, %PlaqueSteps, time_label, score_label]:
		node.visible = false
	_objective_style = objective_label.get_theme_stylebox("normal")
	_speech_style = StyleBoxFlat.new()
	_speech_style.bg_color = Color("fff1ce")
	_speech_style.set_corner_radius_all(22)
	_speech_style.border_color = Color("d9a441")
	_speech_style.set_border_width_all(4)
	_speech_style.content_margin_left = 26.0
	_speech_style.content_margin_right = 26.0
	_speech_style.content_margin_top = 5.0
	_speech_style.content_margin_bottom = 5.0
	set_accuracy(0.0)
	set_stars(0)
	_refresh_ribbon()


func _ink(label: Label, color: Color, outline: int) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", outline)


func set_score(value: int) -> void:
	score_label.text = "$%d" % value


func set_stars(count: int) -> void:
	accuracy_gauge.stars = clampi(count, 0, 3)


func set_time_left(seconds: float) -> void:
	var whole := ceili(seconds)
	time_label.text = "%d:%02d" % [whole / 60, whole % 60]
	var color := Color("ff8a80") if whole <= LOW_TIME_SECONDS else CREAM
	time_label.add_theme_color_override("font_color", color)


## value is 0..1.
func set_accuracy(value: float) -> void:
	accuracy_gauge.value = value * 100.0
	accuracy_label.text = "%d%%" % roundi(value * 100.0)


func _process(_delta: float) -> void:
	if _speech != "" and Time.get_ticks_msec() >= _speech_until:
		_speech = ""
		_refresh_ribbon()


## Instruction text is no longer shown; only the customer speaks in the ribbon.
func set_objective(_text: String) -> void:
	pass


## The customer speaks in the ribbon under the sign for a few seconds. An empty text clears it.
func say(text: String, seconds: float) -> void:
	_speech = text
	_speech_until = Time.get_ticks_msec() + int(seconds * 1000.0)
	_refresh_ribbon()


## Pins the order ticket: the path to follow, drawn small, and its name.
func set_order(points: PackedVector2Array, pattern_name: String) -> void:
	# The ticket draws a path of radius about 125; the stir path may be bigger, so scale it down.
	var extent := 1.0
	for point in points:
		extent = maxf(extent, absf(point.x))
	var scaled := PackedVector2Array()
	for point in points:
		scaled.append(point * (125.0 / extent))
	accuracy_gauge.set_order(scaled, pattern_name)


func _refresh_ribbon() -> void:
	var speaking := _speech != ""
	var text := _speech if speaking else _objective
	objective_label.text = text
	objective_label.visible = text != ""
	objective_label.add_theme_stylebox_override("normal", _speech_style if speaking else _objective_style)
	objective_label.add_theme_color_override("font_color", Color("3a2414") if speaking else CREAM)
	objective_label.add_theme_constant_override("outline_size", 0 if speaking else 7)


func show_message(title: String, body: String) -> void:
	title_label.text = title
	body_label.text = body
	center_panel.visible = true


func hide_message() -> void:
	center_panel.visible = false


func set_tracking_lost(lost: bool) -> void:
	tracking_banner.visible = lost
