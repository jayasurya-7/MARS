extends SceneTree
# Space Tour: an ML game that runs the standard 60 seconds, whose pace follows the speed setting, and
# where each light is a target that is caught when the hand is in line and missed otherwise.
var failures = 0
var trial: Node

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

## Runs the game by hand for `seconds`, steering with `steer` (a Callable giving 0..1 from the game).
func fly(game: Node, seconds: float, steer: Callable, step: float = 0.1) -> void:
	var elapsed = 0.0
	while elapsed < seconds and trial.running:
		game.test_u = steer.call(game)
		game._process(step)
		elapsed += step

func run() -> void:
	trial = root.get_node("Trial")
	root.get_node("Services").settings.set_value("ui", "tutorial_done", true)
	trial.data_root = "res://test-output/st-" + str(Time.get_ticks_usec())
	trial.configure("tourist")
	trial.hardware = false
	var Rules = load("res://core/rules.gd")
	check(Rules.GAMES.has("ST") and Rules.GAMES.ST.movement == "ML" and Rules.GAMES.ST.scene == "space-tour/main.tscn", "Space Tour is registered as a left-right game")
	check(Rules.DURATION == 60.0, "The standard trial is 60 seconds")
	var launcher = load("res://main.tscn").instantiate()
	root.add_child(launcher)
	await process_frame
	launcher.launch("ST")
	await process_frame
	var game = launcher.game_node
	check(game != null and game.get_script().resource_path.ends_with("space_tour.gd") and trial.running and trial.game == "ST" and trial.movement == "ML", "The game starts as an ML trial")
	game.set_process(false)
	await process_frame
	# Pace: one target spacing takes one reach time, so the speed setting changes the forward speed.
	trial.speed = 0.1
	var slow_pace = game.forward_speed()
	trial.speed = 0.2
	var fast_pace = game.forward_speed()
	check(fast_pace > slow_pace * 1.5, "A higher speed setting flies faster: %.1f vs %.1f" % [slow_pace, fast_pace])
	trial.speed = 0.15
	# Flying in line with each light catches it.
	var aligned = func(g): return g._controller.current_u()
	fly(game, 20.0, aligned)
	check(trial.targets >= 3 and trial.hits >= 3 and trial.misses == 0, "Staying in line catches the lights: %d hits, %d misses of %d" % [trial.hits, trial.misses, trial.targets])
	check(trial.target_open, "The next target is there at once")
	# Flying on the wrong side misses them.
	var opposite = func(g): return 1.0 - g._controller.current_u() if absf(g._controller.current_u() - 0.5) > 0.2 else (0.05 if g._controller.current_u() > 0.5 else 0.95)
	var before_misses = trial.misses
	fly(game, 25.0, opposite)
	check(trial.misses > before_misses, "Being out of line misses: %d new misses" % (trial.misses - before_misses))
	# Pause and device hold stop the flight and the clock.
	var duration = trial.duration
	var at = game._player.s
	game.paused = true
	game._process(0.5)
	check(is_equal_approx(trial.duration, duration) and is_equal_approx(game._player.s, at), "Pausing freezes the clock and the flight")
	game.paused = false
	# The trial ends by itself after 60 seconds.
	fly(game, 70.0, aligned, 0.5)
	check(not trial.running and trial.last_result.get("reason") == "COMPLETED" and absf(trial.last_result.seconds - 60.0) < 0.01, "The trial completes after 60 seconds: " + str(trial.last_result))
	check(trial.hits + trial.misses <= trial.targets and trial.targets > 0, "Targets, hits and misses are recorded")
	# The saved trial is an ML trial named for the game.
	var sessions = FileAccess.get_file_as_string(trial.user_path().path_join("sessions/sessions.csv"))
	check(sessions.contains(",ML,") and sessions.contains(",ST,"), "sessions.csv records Space Tour as ML")
	check(FileAccess.file_exists(trial.user_path().path_join("rawdata/" + trial.last_result.raw)) and trial.last_result.raw.contains("-ST-ML"), "The raw file is named for Space Tour / ML")
	print("Space Tour: %d failures" % failures)
	quit(1 if failures else 0)
