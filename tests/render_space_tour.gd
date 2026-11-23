extends SceneTree
# Screenshots of Space Tour in the real (Compatibility) renderer.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var trial = root.get_node("Trial")
	root.get_node("Services").settings.set_value("ui", "tutorial_done", true)
	trial.data_root = "res://test-output/rst-" + str(Time.get_ticks_usec())
	trial.configure("demo")
	var launcher = load("res://main.tscn").instantiate()
	root.add_child(launcher)
	await process_frame
	launcher.launch("ST")
	await process_frame
	var game = launcher.game_node
	var shots = 0
	var frames = 0
	while frames < 600 and shots < 3:
		await process_frame
		frames += 1
		game.test_u = game._controller.current_u() if frames % 3 else 0.5
		if frames in [150, 330, 520]:
			await RenderingServer.frame_post_draw
			root.get_node("Nav").dismiss_tip()
			root.get_texture().get_image().save_png("res://test-output/tour-%d.png" % shots)
			shots += 1
	print("hits ", trial.hits, " misses ", trial.misses, " targets ", trial.targets, " speed ", game._player.forward_speed)
	quit()
