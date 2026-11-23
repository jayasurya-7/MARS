extends SceneTree
func _initialize()->void: call_deferred("run")
func run()->void:
	var trial=root.get_node("Trial")
	trial.data_root="res://test-output/voice-ui-"+str(Time.get_ticks_usec())
	trial.configure("voice-demo")
	var launcher=load("res://main.tscn").instantiate()
	root.add_child(launcher)
	await process_frame
	launcher.show_menu()
	root.get_node("Nav").dismiss_tip()
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/voice-home.png")
	launcher.show_choose()
	root.get_node("Nav").dismiss_tip()
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://test-output/voice-choose.png")
	quit()
