extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var trial = root.get_node("Trial")
	root.get_node("Services").settings.set_value("ui", "tutorial_done", true)
	trial.data_root = "res://test-output/rmop-" + str(Time.get_ticks_usec())
	trial.configure("demo")
	trial.hardware = false
	var launcher = load("res://main.tscn").instantiate()
	root.add_child(launcher)
	await process_frame
	launcher.launch("MP")
	await create_timer(3.0).timeout
	root.get_node("Nav").dismiss_tip()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/mop-app.png")
	quit()
