extends SceneTree
# After a saved MLAP range the app goes straight on to the arm-weight assessment (no separate button),
# and an arm weight older than the latest MLAP range no longer counts.
var failures = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var trial = root.get_node("Trial")
	var records = root.get_node("Records")
	root.get_node("Services").settings.set_value("ui", "tutorial_done", true)
	trial.data_root = "res://test-output/weight-" + str(Time.get_ticks_usec())
	trial.configure("weightuser")
	trial.hardware = false
	var launcher = load("res://main.tscn").instantiate()
	root.add_child(launcher)
	await process_frame
	launcher.open_assessment("MLAP")
	await process_frame
	var first = launcher.assessment
	first.saved = true
	first.finished.emit()
	await process_frame
	check(launcher.assessment != first and launcher.assessment.kind == "WEIGHT", "A saved MLAP range opens the arm-weight assessment")
	# Not saved (Back): no weight assessment, back to choosing.
	launcher.open_assessment("MLAP")
	await process_frame
	var back = launcher.assessment
	back.finished.emit()
	await process_frame
	check(launcher.assessment == back, "Going back from MLAP does not start arm weight")
	# The choose screen has no separate arm-weight button.
	var src = FileAccess.get_file_as_string("res://core/choose_move.gd")
	check(not src.contains("weight_button"), "No separate arm-weight button")
	# Stale weight: older than the MLAP range is dropped.
	var dir = trial.user_path()
	DirAccess.make_dir_recursive_absolute(dir.path_join("rom"))
	DirAccess.make_dir_recursive_absolute(dir.path_join("armweight"))
	var rom = FileAccess.open(dir.path_join("rom/MLAP-rom.csv"), FileAccess.WRITE)
	rom.store_string("DateTime,TrainingPlaneAngle\n2026-11-12 10:00:00,%s\n" % str(trial.plane))
	rom.close()
	var w = FileAccess.open(dir.path_join("armweight/armweight.csv"), FileAccess.WRITE)
	w.store_string("DateTime,TrainingPlaneAngle\n2026-11-12 09:00:00,%s\n" % str(trial.plane))
	w.close()
	records.load_assessments()
	check(records.corners.has("MLAP") and records.weight.is_empty(), "An arm weight older than the MLAP range must be done again")
	w = FileAccess.open(dir.path_join("armweight/armweight.csv"), FileAccess.WRITE)
	w.store_string("DateTime,TrainingPlaneAngle\n2026-11-12 10:05:00,%s\n" % str(trial.plane))
	w.close()
	records.load_assessments()
	check(not records.weight.is_empty(), "An arm weight after the MLAP range counts")
	print("Weight follows MLAP: %d failures" % failures)
	quit(1 if failures else 0)
