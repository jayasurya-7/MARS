class_name EnvironmentController
extends WorldEnvironment
## Builds the cinematic environment and tweens Galaxy phase -> Empty Space phase by distance.

@export var transition_distance := 2500.0
@export var transition_time := 25.0

@export var palette_time := 18.0

## Selectable palette themes; each cycles slowly through its own colours.
const THEMES := [
	{"name": "Aurora", "palettes": [
		{"top": Color(0.12, 0.04, 0.38), "hor": Color(0.75, 0.25, 0.7), "fog": Color(0.55, 0.35, 0.95), "emi": Color(0.25, 0.1, 0.55)},
		{"top": Color(0.02, 0.12, 0.4), "hor": Color(0.1, 0.55, 0.75), "fog": Color(0.3, 0.7, 0.95), "emi": Color(0.05, 0.25, 0.5)},
		{"top": Color(0.3, 0.05, 0.2), "hor": Color(0.95, 0.4, 0.25), "fog": Color(0.95, 0.5, 0.45), "emi": Color(0.5, 0.15, 0.1)},
	]},
	{"name": "Deep Ocean", "palettes": [
		{"top": Color(0.0, 0.08, 0.25), "hor": Color(0.05, 0.5, 0.6), "fog": Color(0.25, 0.75, 0.85), "emi": Color(0.03, 0.22, 0.35)},
		{"top": Color(0.02, 0.05, 0.35), "hor": Color(0.2, 0.35, 0.8), "fog": Color(0.4, 0.55, 0.95), "emi": Color(0.05, 0.12, 0.4)},
	]},
	{"name": "Golden Dusk", "palettes": [
		{"top": Color(0.25, 0.08, 0.25), "hor": Color(0.95, 0.5, 0.3), "fog": Color(1.0, 0.65, 0.45), "emi": Color(0.5, 0.2, 0.1)},
		{"top": Color(0.3, 0.1, 0.3), "hor": Color(1.0, 0.72, 0.5), "fog": Color(1.0, 0.75, 0.6), "emi": Color(0.45, 0.25, 0.15)},
		{"top": Color(0.1, 0.05, 0.3), "hor": Color(0.7, 0.3, 0.5), "fog": Color(0.75, 0.45, 0.7), "emi": Color(0.3, 0.12, 0.3)},
	]},
]

var theme_index := 0

var player: Player

var _sky_mat: ProceduralSkyMaterial
var _triggered := false
var _cycle: Tween


func _ready() -> void:
	_sky_mat = ProceduralSkyMaterial.new()
	_sky_mat.sky_top_color = Color(0.12, 0.04, 0.38)
	_sky_mat.sky_horizon_color = Color(0.75, 0.25, 0.7)
	_sky_mat.ground_horizon_color = Color(0.75, 0.25, 0.7)
	_sky_mat.ground_bottom_color = Color(0.05, 0.02, 0.2)
	_sky_mat.sky_curve = 0.12
	_sky_mat.ground_curve = 0.12
	_sky_mat.sky_energy_multiplier = 1.3
	_sky_mat.sun_angle_max = 0.0

	var sky := Sky.new()
	sky.sky_material = _sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0

	# Bloom
	env.glow_enabled = true
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_hdr_threshold = 1.0
	env.glow_intensity = 0.45
	env.glow_strength = 1.0
	env.glow_bloom = 0.03
	for lvl in [3, 4, 5, 6]:
		env.set_glow_level(lvl, 1.0)

	# Nebula fog: volumetric on Forward+; the app's Compatibility renderer gets a soft depth haze instead.
	if _volumetric():
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.012
		env.volumetric_fog_albedo = Color(0.55, 0.35, 0.95)
		env.volumetric_fog_emission = Color(0.25, 0.1, 0.55)
		env.volumetric_fog_emission_energy = 0.8
		env.volumetric_fog_length = 100.0
		env.volumetric_fog_anisotropy = 0.4
	else:
		env.fog_enabled = true
		env.fog_light_color = Color(0.3, 0.2, 0.6)
		env.fog_density = 0.0035
		env.fog_sky_affect = 0.0

	env.adjustment_enabled = true
	env.adjustment_saturation = 1.15
	env.adjustment_contrast = 1.05

	environment = env
	_start_cycle()


static func _volumetric() -> bool:
	return RenderingServer.get_current_rendering_method() == "forward_plus"


func theme_name() -> String:
	return THEMES[theme_index]["name"]


func set_theme(index: int) -> void:
	theme_index = index % THEMES.size()
	if _triggered:
		return
	_cycle.kill()
	var first: Dictionary = THEMES[theme_index]["palettes"][0]
	_sky_mat.sky_top_color = first["top"]
	_sky_mat.sky_horizon_color = first["hor"]
	_sky_mat.ground_horizon_color = first["hor"]
	_set_fog(first["fog"], first["emi"])
	_start_cycle()


## Slowly drifts the nebula through the theme's palettes.
func _set_fog(albedo: Color, emission: Color) -> void:
	if _volumetric():
		environment.volumetric_fog_albedo = albedo
		environment.volumetric_fog_emission = emission
	else:
		environment.fog_light_color = emission.lightened(0.15)


func _start_cycle() -> void:
	var pals: Array = THEMES[theme_index]["palettes"]
	_cycle = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in pals.size():
		var p: Dictionary = pals[(i + 1) % pals.size()]
		_cycle.tween_property(_sky_mat, "sky_top_color", p["top"], palette_time)
		_cycle.parallel().tween_property(_sky_mat, "sky_horizon_color", p["hor"], palette_time)
		_cycle.parallel().tween_property(_sky_mat, "ground_horizon_color", p["hor"], palette_time)
		_cycle.parallel().tween_property(environment, "volumetric_fog_albedo" if _volumetric() else "fog_light_color", p["fog"] if _volumetric() else (p["emi"] as Color).lightened(0.15), palette_time)


func _process(_delta: float) -> void:
	if _triggered or player == null:
		return
	if player.s >= transition_distance:
		_triggered = true
		_enter_empty_space()


func _enter_empty_space() -> void:
	_cycle.kill()
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for prop in ["sky_top_color", "sky_horizon_color", "ground_horizon_color", "ground_bottom_color"]:
		t.tween_property(_sky_mat, prop, Color.BLACK, transition_time)
	t.tween_property(environment, "volumetric_fog_density", 0.0, transition_time)
	t.tween_property(environment, "volumetric_fog_emission_energy", 0.0, transition_time)
	t.tween_property(environment, "ambient_light_energy", 0.05, transition_time)
	t.chain().tween_callback(func():
		environment.volumetric_fog_enabled = false
		environment.fog_enabled = false
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color.BLACK
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(0.02, 0.02, 0.04))
