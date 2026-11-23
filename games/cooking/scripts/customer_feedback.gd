class_name CustomerFeedback
extends RefCounted
## What the customer thinks of a soup, worked out from StirTracker.round_stats().
## Pure functions, so the rules can be tested without drawing anything.

enum Mood { NEUTRAL, HAPPY, DELIGHTED, WORRIED, SAD, CONFUSED }

## Accuracy needed for each rating.
const THREE_STAR_ACCURACY := 0.85
const TWO_STAR_ACCURACY := 0.6
## Share of the stir that went the wrong way before the customer complains about it.
const WRONG_WAY_LIMIT := 0.12

const TIPS_BY_PATTERN := {
	StirPatterns.Id.CIRCLE: "Aim for an even, round circle.",
	StirPatterns.Id.WIDE_OVAL: "Reach out wide to each side.",
	StirPatterns.Id.TALL_OVAL: "Reach well forward, then back.",
	StirPatterns.Id.FIGURE_EIGHT: "Swing smoothly through the middle.",
	StirPatterns.Id.SQUARE: "Turn crisply at each corner.",
	StirPatterns.Id.DIAMOND: "Reach right out to each point.",
}


static func stars_for(stats: Dictionary) -> int:
	var accuracy: float = stats.get("accuracy", 0.0)
	var wrong: float = stats.get("wrong_way", 0.0)
	if accuracy >= THREE_STAR_ACCURACY and wrong < WRONG_WAY_LIMIT:
		return 3
	if accuracy >= TWO_STAR_ACCURACY:
		return 2
	return 1


static func mood_for_stars(stars: int, stats: Dictionary) -> int:
	if stars >= 3:
		return Mood.DELIGHTED
	if stars == 2:
		return Mood.HAPPY
	return Mood.SAD if float(stats.get("accuracy", 0.0)) < 0.3 else Mood.WORRIED


## One specific, kind piece of advice, chosen from the biggest problem.
static func tip_for(stats: Dictionary, pattern_id: int) -> String:
	var wrong: float = stats.get("wrong_way", 0.0)
	var off: float = stats.get("off_path", 0.0)
	var idle: float = stats.get("idle_seconds", 0.0)
	var accuracy: float = stats.get("accuracy", 0.0)
	if wrong > WRONG_WAY_LIMIT * 2.0:
		return "Follow the arrows - the soup swirls one way."
	if off > 0.35:
		return "Try to stay on the rainbow line."
	if idle > 3.0:
		return "Keep the spoon moving, no need to stop."
	if accuracy < THREE_STAR_ACCURACY:
		return TIPS_BY_PATTERN.get(pattern_id, TIPS_BY_PATTERN[StirPatterns.Id.CIRCLE])
	return "Smooth and steady. Perfect!"


static func reaction(stars: int, stats: Dictionary, pattern_id: int) -> String:
	var opener := "Hmm, not quite."
	if stars >= 3:
		opener = "Delicious!"
	elif stars == 2:
		opener = "Mmm, nice soup!"
	return "%s %s" % [opener, tip_for(stats, pattern_id)]


static func order_line(pattern_id: int) -> String:
	return "Soup stirred in a %s, please!" % StirPatterns.display_name(pattern_id)


## How the customer looks while the patient is stirring.
static func live_mood(live_accuracy: float, feedback: int) -> int:
	if feedback == StirTracker.Feedback.WRONG_WAY:
		return Mood.CONFUSED
	if feedback == StirTracker.Feedback.OFF_PATH or live_accuracy < 0.5:
		return Mood.WORRIED
	if live_accuracy >= 0.8:
		return Mood.HAPPY
	return Mood.NEUTRAL
