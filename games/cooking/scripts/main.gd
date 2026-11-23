extends Node2D
## Game flow: put the vegetables in, stir, repeat until the timer ends.
##
## In MARS HOMER (game "CK", combined movement, patient-paced): every vegetable carried into the pot
## is one target and each soup stirred is one more, done = hit. The app runs the 60 s and shows time
## and score, so the game starts at once and its own timer is not used. On the device the hand is
## the robot (MarsInput reads the app's GamePointer) and the spoon is taken by hovering, like the
## vegetables, because the MARS button is the app's pause / finish.

enum State { WAITING, COLLECTING, STIRRING, SOUP_DONE, FINISHED }

const CHEF_FACES := {
	CustomerFeedback.Mood.HAPPY: ChefBot.Face.HAPPY,
	CustomerFeedback.Mood.DELIGHTED: ChefBot.Face.LOVE,
	CustomerFeedback.Mood.WORRIED: ChefBot.Face.WORRIED,
	CustomerFeedback.Mood.SAD: ChefBot.Face.WORRIED,
	CustomerFeedback.Mood.CONFUSED: ChefBot.Face.DIZZY,
}

const INGREDIENT_SCENE := preload("res://games/cooking/scenes/ingredient.tscn")

@export var round_seconds := 60.0
@export var ingredients_per_round := 3
@export var drop_points := 100
@export var soup_bonus := 200
## Extra points per star the customer gives.
@export var tip_per_star := 50
## How long the customer's reaction stays up before the next order.
@export var feedback_seconds := 4.2
## Score needed for the first, second and third star.
@export var star_scores: Array[int] = [300, 700, 1100]
## Stops a grip still held from the last trial instantly restarting the game.
@export var restart_lockout_seconds := 1.0

var state := State.WAITING
var score := 0.0
var soups := 0
var vegetables := 0
## Stars (1 to 3) the customers gave this trial, one per soup.
var ratings: Array[int] = []

var _soup_number := 0
var _pattern := StirPatterns.Id.CIRCLE
var _reaction := ""
var _tip_points := 0
var _was_gripping := false
var _last_mood := -1
var _restart_ready_at := 0
## Set by the app's Pause button and while MARS is held.
var paused := false
const SIZE := Vector2(1280, 720)

@onready var world: Node2D = $World
@onready var background: Node2D = $World/Background
@onready var slots: Node2D = $World/Slots
@onready var pot: CookingPot = $World/CookingPot
@onready var ingredients: Node2D = $World/Ingredients
@onready var cursor: MarsCursor = $World/Cursor
@onready var round_timer: Timer = $World/RoundTimer
@onready var next_round_timer: Timer = $World/NextRoundTimer
@onready var customer: Customer = $World/Customer
@onready var hud: Hud = $HUD

var memes := MemeAudio.new()
var chef := ChefBot.new()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS   # smooth when the pictures are drawn smaller
	add_child(memes)
	world.add_child(chef)
	var plates := PackedVector2Array()
	for slot: Marker2D in slots.get_children():
		plates.append(slot.global_position)
	background.stove_center = pot.global_position
	background.set_plates(plates)

	pot.ingredient_added.connect(_on_ingredient_added)
	pot.all_ingredients_added.connect(_on_all_ingredients_added)
	pot.stir_points.connect(_on_stir_points)
	pot.stir_completed.connect(_on_stir_completed)
	cursor.grabbed.connect(_on_cursor_grabbed)
	round_timer.timeout.connect(_finish)
	customer.tasted.connect(_on_customer_tasted)
	next_round_timer.wait_time = feedback_seconds
	next_round_timer.timeout.connect(_start_round)
	MarsInput.tracking_changed.connect(_on_tracking_changed)

	_was_gripping = MarsInput.grip
	chef.say("Vanakkam, chef!")
	hud.set_score(0)
	hud.set_time_left(round_seconds)
	hud.set_objective("")
	MarsInput.game = self
	_start_game.call_deferred()


func _process(delta: float) -> void:
	var frozen := paused or Trial.held() or not Trial.running
	world.process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	var goal := _target_point() / SIZE
	Trial.advance(delta, paused, MarsInput.normalized_position, goal)
	if Trial.running and not Trial.target_open and not paused and state in [State.COLLECTING, State.STIRRING]:
		Trial.appear(goal)
	if frozen:
		return
	customer.look_toward(cursor.global_position)
	var pressed := MarsInput.grip and not _was_gripping
	_was_gripping = MarsInput.grip
	_guide_chef()

	match state:
		State.WAITING:
			if pressed:
				_start_game()
		State.FINISHED:
			if pressed and Time.get_ticks_msec() >= _restart_ready_at:
				_start_game()
		_:
			hud.set_time_left(round_timer.time_left)
			hud.set_accuracy(pot.tracker.live_accuracy)
			if state == State.STIRRING:
				hud.set_objective(pot.coaching_text())
				var stirring := pot.spoon.holder != null
				var mood := CustomerFeedback.live_mood(pot.tracker.live_accuracy,
						pot.tracker.feedback) if stirring else CustomerFeedback.Mood.NEUTRAL
				customer.set_mood(mood)
				if mood != _last_mood and mood in [CustomerFeedback.Mood.WORRIED,
						CustomerFeedback.Mood.SAD, CustomerFeedback.Mood.CONFUSED]:
					memes.play("oops")
					chef.wobble()
					chef.say("Other way!" if mood == CustomerFeedback.Mood.CONFUSED else "Aiyo!")
				_last_mood = mood
			elif state == State.COLLECTING:
				customer.set_mood(CustomerFeedback.Mood.NEUTRAL)


## The next thing to reach: the pot with a vegetable in hand, else the nearest vegetable; the spoon,
## then the pot while stirring.
func _target_point() -> Vector2:
	match state:
		State.COLLECTING:
			if cursor.held is Ingredient:
				return pot.global_position
			var best := pot.global_position
			var best_d := INF
			for item: Ingredient in ingredients.get_children():
				if item.state == Ingredient.State.ON_PLATE and not item.is_queued_for_deletion():
					var d := item.global_position.distance_to(cursor.global_position)
					if d < best_d:
						best_d = d
						best = item.global_position
			return best
		State.STIRRING:
			return pot.global_position if pot.spoon.holder != null else pot.spoon.global_position
	return pot.global_position


## Moves the chef bot beside the action and points it at the next thing to do.
func _guide_chef() -> void:
	var mood := customer.mood if state == State.STIRRING else CustomerFeedback.Mood.NEUTRAL
	chef.face = CHEF_FACES.get(mood, ChefBot.Face.CALM)
	match state:
		State.COLLECTING:
			if cursor.held is Ingredient:
				chef.point_at(pot.global_position)
				return
			var next: Ingredient = null
			for item: Ingredient in ingredients.get_children():
				if item.state == Ingredient.State.ON_PLATE and not item.is_queued_for_deletion() and (
						next == null or item.global_position.distance_to(cursor.global_position)
						< next.global_position.distance_to(cursor.global_position)):
					next = item
			if next == null:
				chef.stop_pointing()
			else:
				chef.go_near(next.global_position.x)
				chef.point_at(next.global_position)
		State.STIRRING:
			if pot.spoon.holder == null:
				chef.go_near(pot.spoon.global_position.x)
				chef.point_at(pot.spoon.global_position)
			else:
				chef.stop_pointing()
		State.SOUP_DONE:
			chef.face = ChefBot.Face.HAPPY
			chef.point_at(customer.global_position + Vector2(0, 60))
		_:
			chef.stop_pointing()


func _start_game() -> void:
	memes.play("start", true)
	score = 0.0
	soups = 0
	vegetables = 0
	ratings.clear()
	_soup_number = 0
	pot.tracker.reset_session()
	hud.set_score(0)
	hud.set_stars(0)
	hud.set_accuracy(0.0)
	hud.hide_message()
	# The app's trial clock replaces the game's round timer.
	_start_round()


func _start_round() -> void:
	state = State.COLLECTING
	_clear_ingredients()
	_pattern = StirPatterns.SEQUENCE[_soup_number % StirPatterns.SEQUENCE.size()]
	_soup_number += 1
	pot.open_for_ingredients(ingredients_per_round, _pattern)
	_spawn_ingredients()
	customer.new_customer()
	hud.set_order(pot.tracker.preview_points(), StirPatterns.display_name(_pattern))
	hud.set_objective("Grab a vegetable and carry it to the pot")
	hud.say(CustomerFeedback.order_line(_pattern), 3.2)
	chef.say(["New order!", "Let's cook!", "Vaa, let's cook!"].pick_random())
	chef.hop()


## Slots are shuffled so each round asks for reaches in different directions.
func _spawn_ingredients() -> void:
	var points := slots.get_children()
	points.shuffle()
	var kinds: Array = Ingredient.Kind.values()
	kinds.shuffle()
	var used := PackedVector2Array()
	for i in mini(ingredients_per_round, points.size()):
		var item: Ingredient = INGREDIENT_SCENE.instantiate()
		item.kind = kinds[i % kinds.size()]
		ingredients.add_child(item)
		item.place_at(points[i].global_position)
		used.append(points[i].global_position)
	background.set_active_slots(used)


func _clear_ingredients() -> void:
	for item in ingredients.get_children():
		item.queue_free()


func _finish() -> void:
	memes.play("end", true)
	chef.cheer(true)
	chef.say("Great shift, chef!")
	state = State.FINISHED
	background.set_active_slots(PackedVector2Array())
	_restart_ready_at = Time.get_ticks_msec() + int(restart_lockout_seconds * 1000.0)
	next_round_timer.stop()
	pot.close() # Closed first, so a vegetable let go at the buzzer doesn't score.
	cursor.force_release()
	_clear_ingredients()
	hud.set_time_left(0.0)
	hud.set_objective("")
	hud.say("", 0.0)
	customer.set_mood(CustomerFeedback.Mood.NEUTRAL)
	var rating_text := "No customers served"
	if not ratings.is_empty():
		var total := 0
		for stars in ratings:
			total += stars
		rating_text = "Customers: %.1f of 3 stars" % (float(total) / ratings.size())
	hud.show_message("Time's up!", "Money earned: $%d\nVegetables: %d    Soups: %d\n%s\n\nPress the grip to play again" % [
		int(score), vegetables, soups, rating_text,
	])


func _add_score(points: float) -> void:
	score += points
	hud.set_score(int(score))
	var earned := 0
	for threshold in star_scores:
		if score >= threshold:
			earned += 1
	hud.set_stars(earned)


func _on_ingredient_added(item: Ingredient) -> void:
	Trial.resolve(true)
	memes.play("drop")
	vegetables += 1
	_add_score(drop_points)
	_float_text("+$%d" % drop_points, item.global_position)
	chef.cheer()
	chef.say(["Yum!", "Semma!", "Super!", "Nice one!"].pick_random())


func _on_all_ingredients_added() -> void:
	state = State.STIRRING
	# Every crate is empty now, so dim them all and let the pot take the attention.
	background.set_active_slots(PackedVector2Array([Vector2(-999, -999)]))
	chef.say("Stir time!")
	chef.hop()


func _on_stir_points(points: float) -> void:
	_add_score(points)


func _on_stir_completed() -> void:
	Trial.resolve(true)
	state = State.SOUP_DONE
	soups += 1
	_add_score(soup_bonus)
	_float_text("Soup's ready! +$%d" % soup_bonus, pot.global_position)
	hud.set_objective("")
	var stats := pot.tracker.round_stats()
	var stars := CustomerFeedback.stars_for(stats)
	ratings.append(stars)
	_reaction = CustomerFeedback.reaction(stars, stats, _pattern)
	_tip_points = stars * tip_per_star
	customer.taste(CustomerFeedback.mood_for_stars(stars, stats))
	memes.play("soup_%d" % clampi(stars, 1, 3), true)
	chef.cheer(stars >= 3)
	chef.say(["Good try! Next one!", "Tasty! Well done!", "Semma! 3 stars!"][clampi(stars, 1, 3) - 1])
	cursor.force_release()
	next_round_timer.start()


func _on_customer_tasted(_mood: int) -> void:
	if state != State.SOUP_DONE:
		return
	hud.say(_reaction, feedback_seconds - 0.4)
	_add_score(_tip_points)
	_float_text("Tip +$%d" % _tip_points, customer.global_position + Vector2(0, 150))


func _on_cursor_grabbed(item: Grabbable) -> void:
	if item is Ingredient:
		memes.play("grab")
		chef.hop()
		if not chef.is_speaking():
			chef.say("Got it!")
	if item == pot.spoon:
		pot.tracker.begin_stroke()


func _on_tracking_changed(ok: bool) -> void:
	# The app holds the trial while MARS is not ready; World is frozen in _process.
	hud.set_tracking_lost(false)


func _float_text(text: String, at: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color("fff3b0"))
	label.add_theme_color_override("font_outline_color", Color("3a2a12"))
	label.add_theme_constant_override("outline_size", 10)
	label.z_index = 30
	world.add_child(label)
	label.position = at - label.get_combined_minimum_size() * 0.5
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 80.0, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)
