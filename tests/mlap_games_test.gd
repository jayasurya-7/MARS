extends SceneTree
# The five combined-movement (MLAP) daily-life games: they start as patient-paced MLAP trials, show a
# target, count a completed task as a hit, pause with the app, have no speed control, and save their
# trial like every other game.
var failures = 0
var trial: Node

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count: await process_frame

## Makes the game complete one task the way it would after the patient's movement.
func complete_one(code: String, game: Node) -> void:
	match code:
		"SO": game._on_sorted(null, null)
		"DR":
			game.player_selected_color = game.current_required_color
			game._paint_region(game.current_region)
		"IR": game.get_node("Game").complete_garment()
		"MP":
			game._on_dust_dropped(Vector3.ZERO)
			await frames(2)
			game._on_pile_cleaned(game._piles[0])
		"CK": game._on_ingredient_added(game.ingredients.get_child(0))

func run() -> void:
	trial = root.get_node("Trial")
	var Rules = load("res://core/rules.gd")
	root.get_node("Services").settings.set_value("ui", "tutorial_done", true)
	trial.data_root = "res://test-output/mlap-" + str(Time.get_ticks_usec())
	trial.configure("mlapuser")
	trial.hardware = false
	var launcher = load("res://main.tscn").instantiate()
	root.add_child(launcher)
	await process_frame
	for code in ["SO", "DR", "IR", "MP", "CK"]:
		check(Rules.GAMES.has(code) and Rules.GAMES[code].movement == "MLAP" and Rules.paced(code), code + " is a patient-paced MLAP game")
		launcher.launch(code)
		await frames(20)
		var game = launcher.game_node
		check(game != null and trial.running and trial.game == code and trial.movement == "MLAP", code + " starts as an MLAP trial")
		check(Vector2i(launcher.viewport.get_visible_rect().size) == Rules.game_size(code), code + " runs at its own screen size %s" % str(launcher.viewport.size))
		check(trial.target_open and trial.targets >= 1, code + " shows a target (%d)" % trial.targets)
		var hits = trial.hits
		await complete_one(code, game)
		await create_timer(1.2).timeout
		check(trial.hits == hits + 1, code + " counts a finished task as a hit (%d -> %d)" % [hits, trial.hits])
		check(trial.target_open, code + " has the next target at once")
		# Pause holds the clock.
		launcher.toggle_pause()
		await frames(2)
		var duration = trial.duration
		await frames(10)
		check(game.paused and is_equal_approx(trial.duration, duration), code + " pauses with the app")
		launcher.toggle_pause()
		await frames(2)
		check(not game.paused, code + " resumes")
		# No speed control: Ctrl+G does nothing for patient-paced games.
		var speed = trial.speed
		launcher.glass_controls.change_speed(0.05)
		check(is_equal_approx(trial.speed, speed), code + " has no speed control")
		if code == "CK":
			# On the device the spoon (the handle) is taken by holding the hand on it for 0.3 s.
			game._on_all_ingredients_added()
			var spoon = game.pot.spoon
			spoon.enabled = true   # as the pot does once all vegetables are in
			var hand = game.cursor
			var input = root.get_node("MarsInput")
			input.game = null   # the test places the hand itself
			input.normalized_position = spoon.global_position / game.SIZE
			await create_timer(0.15).timeout
			check(hand.held == null, "CK: the spoon is not taken at once")
			await create_timer(0.5).timeout
			check(hand.held == spoon, "CK: holding the hand on the spoon for 0.3 s takes it (no error)")
			input.game = game
		launcher.finish_game()
		await frames(3)
		check(not trial.running, code + " finishes and saves")
		var sessions = FileAccess.get_file_as_string(trial.user_path().path_join("sessions/sessions.csv"))
		check(sessions.contains(",MLAP,") and sessions.contains("," + code + ","), code + " is in sessions.csv")
		launcher.show_menu()
		await frames(3)
	# Mopping: a different room on every trial.
	var rooms: Array = []
	for i in 4:
		launcher.launch("MP")
		await frames(5)
		rooms.append(launcher.game_node._room)
		launcher.finish_game()
		await frames(3)
		launcher.show_menu()
		await frames(3)
	check(rooms[0] != rooms[1] and rooms[1] != rooms[2] and rooms[2] != rooms[3], "Mopping changes room every trial: " + str(rooms))
	# Ironing: on the device the whole range covers every part of each garment.
	launcher.launch("IR")
	await frames(5)
	var iron = launcher.game_node.get_node("Game")
	for garment in iron.GARMENTS:
		iron.new_garment(garment)
		var inside = true
		for idx in iron.cols * iron.rows:
			if iron.valid[idx] == 1 and not iron.reach_rect.has_point(iron.cell_scr[idx]): inside = false
		check(inside and iron.reach_rect.size.x < 1300.0, garment + ": the reach area covers the whole garment and no more than the board")
	check(iron.IRON_SCALE < 0.6 and iron.IRON_RX < 200.0, "The iron is smaller")
	launcher.finish_game()
	await frames(3)
	print("MLAP games: %d failures" % failures)
	quit(1 if failures else 0)
