extends Node
## Autoload "MarsInput" for Vegetable Soup: the only place in that game that knows where input comes from.
##
## In MARS HOMER it reads the app: the hand is GamePointer (the robot inside the patient's assessed range,
## or the mouse in simulation), the training side comes from the patient's plan, and tracking is lost
## while the app holds the trial. The grip is the mouse button / Space in simulation only, because the
## MARS button is the app's pause / finish; on the device everything is picked up by hovering.

signal tracking_changed(ok: bool)

enum Source { SIMULATION, DEVICE }
enum Side { RIGHT, LEFT }

var source := Source.SIMULATION
## The arm being trained. Sets which way "lateral to anterior" runs on screen.
var training_side := Side.RIGHT
## (0,0) is the top-left of the patient's assessed range, (1,1) the bottom-right.
var normalized_position := Vector2(0.5, 0.5)
var grip := false
var tracking_ok := true
## The running Vegetable Soup game registers itself here; nothing is read without it.
var game: Node


func _ready() -> void:
	# Must keep running while the game is held, or tracking could never recover.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if not is_instance_valid(game) or not game.is_inside_tree():
		return
	source = Source.DEVICE if Trial.hardware else Source.SIMULATION
	training_side = Side.LEFT if str(Records.profile.get("TrainingSide", "RIGHT")).to_upper() == "LEFT" else Side.RIGHT
	normalized_position = GamePointer.normalized(game)
	grip = GamePointer.grip() or (not Trial.hardware and Input.is_physical_key_pressed(KEY_SPACE))
	_set_tracking(not Trial.held())


func _set_tracking(ok: bool) -> void:
	if ok != tracking_ok:
		tracking_ok = ok
		tracking_changed.emit(ok)
