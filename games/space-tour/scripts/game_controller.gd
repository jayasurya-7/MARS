class_name GameController
extends Node3D
## Tour director for Space Tour (left-right movement).
##
## One glowing light (or ring) is the current target; the next few wait ahead on the route so the
## patient can see where the hand has to go. The lights are spaced evenly along the route and the ship's
## forward speed is set so that one spacing takes exactly one reach time (range / speed): the target
## duration of the training, adjustable with the speed panel. Flying past a light in line with it
## catches it; passing it out of line is a miss. Scenery (planets, nebulae, auroras, jellyfish,
## comets, drifting rocks) is spawned ahead and freed once passed.
##
## GameController (Node3D)             <- this script
## ├─ Pool (Node3D) → Asteroid x pool_size, Pickup x pickup_pool_size
## └─ Planet / nebula / Aurora / Jelly nodes (spawned ahead, freed once passed), Comet

signal popup(text: String)
## A target was passed: caught or missed, the light's lateral position 0..1 and its note.
signal resolved(hit: bool)

const AsteroidScript = preload("res://games/space-tour/scripts/asteroid.gd")
const PickupScript = preload("res://games/space-tour/scripts/pickup.gd")
const PlanetScript = preload("res://games/space-tour/scripts/planet.gd")
const AuroraScript = preload("res://games/space-tour/scripts/aurora.gd")
const JellyScript = preload("res://games/space-tour/scripts/jelly.gd")
const CometScript = preload("res://games/space-tour/scripts/comet.gd")
const PT = preload("res://games/space-tour/scripts/path_track.gd")
const Fx = preload("res://games/space-tour/scripts/fx.gd")
const NAMES := [
	"Aurelia", "Kepler-9b", "Nyx", "Orion Veil", "Helios",
	"Cygnus Reach", "Lyra Prime", "Vega Minor", "Tau Ceti", "Andromeda Gate",
]
## Half of the sideways range the targets use, in route units (the ship can reach a little further).
const TARGET_RANGE := 5.0
## How far from a light, sideways, still counts as in line.
const HIT_RADIUS := 1.7
## Distance between consecutive targets along the route.
const SPACING := 36.0
## Smallest sideways change between consecutive targets, as a fraction of the full range.
const MIN_JUMP := 0.3

@export var pool_size := 60
@export var pickup_pool_size := 16
@export var spawn_distance := 200.0
@export var despawn_behind := 30.0

var player: Player
var distance := 0.0
var running := false

var _free: Array[Asteroid] = []
var _active: Array[Asteroid] = []
var _free_orbs: Array[Pickup] = []
var _targets: Array[Dictionary] = []   # {orb, s, u, ring}; the first is the current target
var _scenery: Array[Node3D] = []
var _next_target_s := 70.0
var _last_u := 0.5
var _made := 0
var _next_rock_s := 40.0
var _next_planet_s := 150.0
var _next_nebula_s := 60.0
var _next_aurora_s := 120.0
var _next_jelly_s := 90.0
var _comet_timer := 10.0
var _name_i := 0
var _rng := RandomNumberGenerator.new()


func setup(p: Player) -> void:
	player = p
	_rng.randomize()
	var holder := Node3D.new()
	holder.name = "Pool"
	add_child(holder)
	for i in pool_size:
		var a := AsteroidScript.new() as Asteroid
		holder.add_child(a)
		_free.append(a)
	for i in pickup_pool_size:
		var o := PickupScript.new() as Pickup
		holder.add_child(o)
		_free_orbs.append(o)
	_name_i = _rng.randi() % NAMES.size()
	_fill_targets()


## Sideways position (0..1) of the current target, or 0.5 when none is waiting.
func current_u() -> float:
	return float(_targets[0].u) if not _targets.is_empty() else 0.5


func lateral_of(u: float) -> float:
	return (u - 0.5) * 2.0 * TARGET_RANGE


## Route position of the current target, for the player to know how far away it is.
func current_s() -> float:
	return float(_targets[0].s) if not _targets.is_empty() else player.s


func advance(delta: float) -> void:
	if player == null:
		return
	distance = player.s
	if not running:
		return
	_fill_targets()
	_resolve_passed()
	_pulse(delta)
	_spawn_scenery(delta)
	_cleanup()


# --- the targets -------------------------------------------------------------

func _fill_targets() -> void:
	var horizon := player.s + spawn_distance
	while _next_target_s < horizon and not _free_orbs.is_empty():
		var u := _next_u()
		var ring := _made % 3 == 2
		var o: Pickup = _free_orbs.pop_back()
		var os := _next_target_s
		o.note = _made % 7
		o.activate(PT.point(os, lateral_of(u), 0.0), Color.from_hsv(fposmod(0.55 + _made * 0.11, 1.0), 0.55 if ring else 0.7, 1.0), ring, PT.frame(os))
		_targets.append({"orb": o, "s": os, "u": u, "ring": ring})
		_last_u = u
		_made += 1
		_next_target_s += SPACING


## Alternates sides with a real sideways reach between neighbours, inside the usable range.
func _next_u() -> float:
	if _made == 0:
		return _rng.randf_range(0.2, 0.8)
	var side := -1.0 if _last_u > 0.5 else 1.0
	if _rng.randf() < 0.25:
		side = -side   # now and then the same side again, so it is not predictable
	var u := _last_u + side * _rng.randf_range(MIN_JUMP, 0.65)
	if u < 0.08 or u > 0.92:
		u = _last_u - side * _rng.randf_range(MIN_JUMP, 0.6)
	return clampf(u, 0.08, 0.92)


## A target is decided the moment the ship reaches it.
func _resolve_passed() -> void:
	while not _targets.is_empty() and player.s >= float(_targets[0].s):
		var t: Dictionary = _targets.pop_front()
		var hit := absf(player.lx - lateral_of(float(t.u))) <= HIT_RADIUS
		var orb: Pickup = t.orb
		if hit:
			player.collect(orb)
		else:
			orb.deactivate()
		_free_orbs.append(orb)
		resolved.emit(hit)
		_fill_targets()


var _pulse_t := 0.0

## The waiting targets stay at their size; the current one breathes bigger.
func _pulse(delta: float) -> void:
	_pulse_t += delta
	for i in _targets.size():
		(_targets[i].orb as Pickup).highlight(0.45 + 0.12 * sin(_pulse_t * 4.0) if i == 0 else 0.0)


# --- scenery ------------------------------------------------------------------

func _spawn_scenery(delta: float) -> void:
	var horizon := player.s + spawn_distance
	while _next_rock_s < horizon:
		_spawn_rocks(_next_rock_s)
		_next_rock_s += _rng.randf_range(30.0, 50.0)
	while _next_jelly_s < horizon:
		_spawn_jellies(_next_jelly_s)
		_next_jelly_s += _rng.randf_range(320.0, 460.0)
	var far := player.s + 380.0
	while _next_planet_s < far:
		_spawn_planet(_next_planet_s)
		_next_planet_s += _rng.randf_range(450.0, 700.0)
	while _next_nebula_s < far:
		_spawn_nebula(_next_nebula_s)
		_next_nebula_s += _rng.randf_range(320.0, 460.0)
	while _next_aurora_s < far:
		_spawn_aurora(_next_aurora_s)
		_next_aurora_s += _rng.randf_range(480.0, 700.0)
	_comet_timer -= delta
	if _comet_timer <= 0.0:
		_spawn_comet()
		_comet_timer = _rng.randf_range(50.0, 90.0)


func _cleanup() -> void:
	var ps := player.s
	for i in range(_active.size() - 1, -1, -1):
		var a := _active[i]
		if float(a.get_meta("s")) < ps - despawn_behind:
			a.deactivate()
			_active.remove_at(i)
			_free.append(a)
	for i in range(_scenery.size() - 1, -1, -1):
		var n := _scenery[i]
		var ns: float = n.get_meta("s")
		if n.has_meta("name") and not n.has_meta("announced") and ns - 130.0 < ps:
			n.set_meta("announced", true)
			popup.emit("Approaching %s" % n.get_meta("name"))
		if ns < ps - 250.0:
			n.queue_free()
			_scenery.remove_at(i)


## Harmless drifting rocks around the route (scenery only).
func _spawn_rocks(s: float) -> void:
	for i in _rng.randi_range(1, 2):
		if _free.is_empty():
			return
		# Keep the flight lane clear so the lights are the only things in it.
		var lx := _rng.randf_range(14.0, 40.0) * (1.0 if _rng.randf() < 0.5 else -1.0)
		var ly := _rng.randf_range(-16.0, 16.0)
		var a: Asteroid = _free.pop_back()
		a.activate(PT.point(s + _rng.randf_range(-5.0, 5.0), lx, ly), _rng.randf_range(0.8, 2.4))
		a.set_meta("s", s)
		_active.append(a)


func _spawn_planet(s: float) -> void:
	var side := 1.0 if _rng.randf() < 0.5 else -1.0
	var r := _rng.randf_range(14.0, 34.0)
	var p := PlanetScript.new() as Planet
	add_child(p)
	p.setup(r, Color.from_hsv(_rng.randf(), 0.55, 0.9), _rng.randf() < 0.4)
	p.global_position = PT.point(s, side * (r + _rng.randf_range(45.0, 90.0)), _rng.randf_range(-35.0, 35.0))
	p.set_meta("s", s)
	p.set_meta("name", NAMES[_name_i % NAMES.size()])
	_name_i += 1
	_scenery.append(p)


func _spawn_nebula(s: float) -> void:
	var side := 1.0 if _rng.randf() < 0.5 else -1.0
	var h := Fx.halo(_rng.randf_range(120.0, 220.0), Color.from_hsv(_rng.randf(), 0.6, 1.0, 0.09))
	add_child(h)
	h.global_position = PT.point(s, side * _rng.randf_range(60.0, 160.0), _rng.randf_range(-60.0, 60.0))
	h.set_meta("s", s)
	_scenery.append(h)


func _spawn_aurora(s: float) -> void:
	var side := 1.0 if _rng.randf() < 0.5 else -1.0
	var a := AuroraScript.new() as Aurora
	add_child(a)
	var hue: float = [0.38, 0.48, 0.78][_rng.randi() % 3]
	a.setup(Color.from_hsv(hue, 0.7, 1.0))
	var pos := PT.point(s, side * _rng.randf_range(70.0, 120.0), _rng.randf_range(20.0, 50.0))
	a.global_position = pos
	a.look_at(PT.point(s, 0.0, 0.0), Vector3.UP)   # curtain faces the route
	a.set_meta("s", s)
	_scenery.append(a)


func _spawn_jellies(s: float) -> void:
	var side := 1.0 if _rng.randf() < 0.5 else -1.0
	var hue := _rng.randf_range(0.45, 0.95)
	for i in 2:
		var j := JellyScript.new() as Jelly
		add_child(j)
		j.setup(Color.from_hsv(fposmod(hue + i * 0.04, 1.0), 0.45, 1.0), _rng.randf_range(1.5, 3.2))
		var js := s + i * _rng.randf_range(8.0, 16.0)
		j.global_position = PT.point(js, side * _rng.randf_range(20.0, 40.0), _rng.randf_range(-12.0, 14.0))
		j.set_meta("s", js)
		_scenery.append(j)


func _spawn_comet() -> void:
	var side := 1.0 if _rng.randf() < 0.5 else -1.0
	var s := player.s + 110.0
	var b := PT.frame(s)
	var c := CometScript.new() as Comet
	add_child(c)
	c.global_position = PT.point(s, side * _rng.randf_range(35.0, 60.0), _rng.randf_range(14.0, 30.0))
	c.velocity = -b.z * 12.0 + b.x * (-side * 9.0) - b.y * 1.5
