extends Node3D
## Space Tour (left-right movement), part of the Trial framework.
##
## The patient's hand steers a shooting star sideways along a winding tour route (ML: the robot's
## left-right position, or the mouse / arrow keys in simulation). One glowing light after another
## waits ahead, one reach apart. The forward speed is set so one spacing takes the current reach time
## (range / speed), so the speed panel (Ctrl+G) changes the pace live and the training adapts the speed
## from trial to trial like every other game. The trial lasts the standard 60 seconds.
##
## Every light is a target: passing it in line catches it (a hit, a bell note, the light joins the
## ship); passing it out of line is a miss. The next target is there at once.
const UITheme = preload("res://core/ui_theme.gd")
const Sfx = preload("res://core/sfx.gd")
const Cycle = preload("res://core/visual_cycle.gd")
const PlayerScript = preload("res://games/space-tour/scripts/player.gd")
const CameraScript = preload("res://games/space-tour/scripts/chase_camera.gd")
const ControllerScript = preload("res://games/space-tour/scripts/game_controller.gd")
const EnvScript = preload("res://games/space-tour/scripts/environment_controller.gd")
const AudioScript = preload("res://games/space-tour/scripts/synth_audio.gd")
const ConstellationScript = preload("res://games/space-tour/scripts/constellation.gd")
const SCREEN_WIDTH = 1600.0
## Mouse margin so the ends of the range are easy to reach in simulation.
const MARGIN = 0.06
const MIN_FORWARD = 2.0
const CHEERS = ["Caught!", "Nice!", "Great!", "Lovely!", "Well done!"]

var paused = false
## Tests (and nothing else) can steer without a mouse: 0..1, or -1 for normal input.
var test_u = -1.0
var _player: Player
var _cam: ChaseCamera
var _controller: GameController
var _world: EnvironmentController
var _audio: SynthAudio
var _popup: Label
var _popup_tween: Tween
var _miss_sound: AudioStreamPlayer
var _mouse_u = 0.5
var _streak = 0

func _enter_tree() -> void:
	# The 3D world belongs to this game only, and edges are smoothed.
	var viewport = get_viewport()
	if viewport is SubViewport:
		viewport.own_world_3d = true
		viewport.msaa_3d = Viewport.MSAA_2X

func _ready() -> void:
	_world = EnvScript.new() as EnvironmentController
	_world.name = "WorldEnvironment"
	add_child(_world)
	# A different palette every trial, like the other games' changing scenery.
	_world.set_theme(Cycle.look())
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-35, -40, 0)
	sun.light_color = Color(0.65, 0.75, 1.0)
	sun.light_energy = 0.9
	add_child(sun)
	_audio = AudioScript.new() as SynthAudio
	_audio.name = "SynthAudio"
	add_child(_audio)
	_player = PlayerScript.new() as Player
	_player.name = "Player"
	add_child(_player)
	_world.player = _player
	_cam = CameraScript.new() as ChaseCamera
	_cam.name = "ChaseCamera"
	_cam.target = _player
	add_child(_cam)
	_cam.current = true
	_controller = ControllerScript.new() as GameController
	_controller.name = "GameController"
	add_child(_controller)
	_controller.setup(_player)
	_controller.popup.connect(show_popup.bind(false))
	_controller.resolved.connect(on_resolved)
	_miss_sound = AudioStreamPlayer.new()
	_miss_sound.volume_db = -14.0
	add_child(_miss_sound)
	build_popup()
	_player.forward_speed = forward_speed()
	_player.active = true
	_controller.running = true

## Route units per second: one target spacing takes one reach time.
func forward_speed() -> float:
	return maxf(MIN_FORWARD, GameController.SPACING / maxf(0.5, Trial.reach_time()))

## Where the hand is, 0 (left) .. 1 (right).
func steer() -> float:
	if test_u >= 0.0: return test_u
	if Trial.hardware: return clampf(Trial.input_position(Vector2(0.5, 0.5)).x, 0.0, 1.0)
	var axis = Input.get_axis("ui_left", "ui_right")
	if axis != 0.0: _mouse_u = clampf(_mouse_u + axis * 0.9 * get_process_delta_time(), 0.0, 1.0)
	return _mouse_u

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not Trial.hardware:
		_mouse_u = clampf((get_viewport().get_mouse_position().x / SCREEN_WIDTH - MARGIN) / (1.0 - 2.0 * MARGIN), 0.0, 1.0)

func _process(delta: float) -> void:
	if _player == null: return
	var u = steer()
	_player.target_lx = _controller.lateral_of(u)
	_player.forward_speed = forward_speed()
	var playing = Trial.running and not paused and not Trial.held()
	if playing:
		_player.step(delta)
		_controller.advance(delta)
	# Positions for the raw data and the target the patient is reaching for.
	var player_u = clampf(_player.lx / (2.0 * GameController.TARGET_RANGE) + 0.5, 0.0, 1.0)
	Trial.advance(delta, paused, Vector2(player_u, 0.5), Vector2(_controller.current_u(), 0.5))
	if Trial.running and not Trial.target_open and not paused:
		Trial.appear(Vector2(_controller.current_u(), 0.5))

func on_resolved(hit: bool) -> void:
	Trial.resolve(hit)
	if hit:
		_streak += 1
		_audio.play_note(clampi(_streak - 1, 0, 6))
		_cam.shake(0.2)
		show_popup(CHEERS[(Trial.hits + Trial.trial_session) % CHEERS.size()], true)
		if _player.star_count % 10 == 0:
			_audio.play_chime()
			_player.celebrate()
			var c = ConstellationScript.new() as Constellation
			_cam.add_child(c)
			c.position = Vector3(0, 7, -45)
			show_popup("A new constellation: %s" % c.show_shape(_player.star_count / 10 - 1), false)
	else:
		_streak = 0
		_miss_sound.stream = Sfx.miss("ST")
		_miss_sound.play()
		show_popup("Missed", true, true)

# --- feedback text -----------------------------------------------------------

func build_popup() -> void:
	var layer = CanvasLayer.new()
	layer.name = "Feedback"
	add_child(layer)
	_popup = Label.new()
	_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_popup.offset_top = 190
	_popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup.add_theme_font_override("font", UITheme.DISPLAY)
	_popup.add_theme_font_size_override("font_size", 56)
	_popup.add_theme_constant_override("outline_size", 12)
	_popup.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.1, 0.9))
	_popup.modulate.a = 0.0
	layer.add_child(_popup)

## Big friendly feedback in Titan One (the catches and misses), smaller place names otherwise.
func show_popup(text: String, feedback: bool = false, miss: bool = false) -> void:
	_popup.text = text
	_popup.add_theme_font_size_override("font_size", 56 if feedback else 34)
	_popup.add_theme_color_override("font_color", Color("ffb4a2") if miss else (Color("fff2a8") if feedback else Color("a8ecff")))
	_popup.modulate.a = 1.0
	if _popup_tween: _popup_tween.kill()
	_popup_tween = create_tween()
	_popup_tween.tween_property(_popup, "modulate:a", 0.0, 0.7).set_delay(0.9 if feedback else 1.8)
