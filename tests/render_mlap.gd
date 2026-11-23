extends SceneTree
# Screenshots of the five MLAP games inside the app (for checking and for their game cards).
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var trial = root.get_node("Trial")
	root.get_node("Services").settings.set_value("ui", "tutorial_done", true)
	trial.data_root = "res://test-output/rmlap-" + str(Time.get_ticks_usec())
	trial.configure("demo")
	trial.hardware = false
	var launcher = load("res://main.tscn").instantiate()
	root.add_child(launcher)
	await process_frame
	for code in ["SO", "DR", "IR", "MP", "CK"]:
		launcher.launch(code)
		await create_timer(2.5).timeout
		root.get_node("Nav").dismiss_tip()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://test-output/mlap-%s.png" % code)
		launcher.finish_game()
		await create_timer(0.3).timeout
		launcher.show_menu()
		await create_timer(0.3).timeout
	quit()
