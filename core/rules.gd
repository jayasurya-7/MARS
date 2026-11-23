extends RefCounted
## Source: Assets/scripts/others.cs: MarsGameDefs; AppData.cs adaptation.
const MIN_SPEED = 0.025
const MAX_SPEED = 0.25
const DURATION = 60.0
const GAMES = {
	"SS": {"title":"Space Shooter", "movement":"ML", "span":8.19},
	"PP": {"title":"Ping Pong", "movement":"AP", "span":14.0},
	"DC": {"title":"Diamond Catcher", "movement":"MLAP", "span":11.5},
	"TW": {"title":"Table Wiping", "movement":"MLAP", "span":13.1},
	"CB": {"title":"Character Flight", "movement":"AP", "span":14.82},
	"TT": {"title":"Reef Runner", "movement":"AP", "span":14.82},
	"MC": {"title":"Match Catch", "movement":"ML", "span":7.5},
	"FR": {"title":"Fish Rescue", "movement":"MLAP", "scene":"fish-rescue/main.tscn", "span":11.5},
	"BS": {"title":"Bubble Sparkle", "movement":"MLAP", "scene":"bubble-sparkle/main.tscn", "span":11.5},
	"FW": {"title":"Fireworks", "movement":"ML", "scene":"fire-works/main.tscn", "span":15.0},
	"ST": {"title":"Space Tour", "movement":"ML", "scene":"space-tour/main.tscn", "span":10.0},
	# Combined-movement daily-life games. Patient-paced (no speed control); "size" is the screen they were drawn for.
	"CK": {"title":"Vegetable Soup", "movement":"MLAP", "scene":"cooking/scenes/main.tscn", "span":11.5, "size":Vector2i(1280,720), "paced":true},
	"DR": {"title":"Colour the Picture", "movement":"MLAP", "scene":"drawing/scenes/main.tscn", "span":11.5, "size":Vector2i(1920,1080), "paced":true},
	"IR": {"title":"Ironing", "movement":"MLAP", "scene":"ironing/main.tscn", "span":11.5, "size":Vector2i(1920,1080), "paced":true},
	"MP": {"title":"Mopping", "movement":"MLAP", "scene":"mopping/scenes/main.tscn", "span":11.5, "size":Vector2i(1920,1080), "paced":true},
	"SO": {"title":"Tidy-up Sorting", "movement":"MLAP", "scene":"sorting/scenes/Main.tscn", "span":11.5, "size":Vector2i(1920,1080), "paced":true}
}

## Patient-paced games: every target waits for the patient, so there is no reach speed to set.
static func paced(game: String) -> bool:
	return game in ["TW", "FW", "BS"] or bool(GAMES.get(game, {}).get("paced", false))

## The screen size a game was made for (the app scales it to the window).
## How many times sharper than its native size a game is drawn: small-canvas games (Vegetable Soup is
## 1280x720) are rendered at about Full HD, so their pictures are not stretched and blurred.
static func render_scale(game) -> float:
	var native = game_size(game)
	return maxf(1.0, 1920.0 / float(native.x)) if GAMES.get(game, {}).has("size") else 1.0

static func game_size(game: String) -> Vector2i:
	return GAMES.get(game, {}).get("size", Vector2i(1600, 900))

static func screen_limits(game: String) -> Rect2:
	var values = {"CB":Rect2(-6.82,-3,14.82,9),"SS":Rect2(-7.5,-3.85,15,7.7),"PP":Rect2(-7,-6,14,12),"DC":Rect2(-7.5,-4,15,8),"TW":Rect2(-8.5,-5,17,9.2),"TT":Rect2(-6.82,-3,14.82,9),"MC":Rect2(-7.5,-5,15,8.85),"ST":Rect2(-5,-3,10,6)}
	return values.get(game,Rect2(-7.5,-4,15,8))

static func reach_duration(movement: String, speed: float, rom: Vector2) -> float:
	var distance = rom.x if movement == "ML" else rom.y if movement == "AP" else (rom.x + rom.y) / 2.0
	return distance / clampf(speed, MIN_SPEED, MAX_SPEED)

static func adapt(speed: float, success: float) -> float:
	var normalized = (speed - MIN_SPEED) / (MAX_SPEED - MIN_SPEED)
	var factor = lerpf(0.975, 0.995, normalized) if success < 80 else lerpf(1.025, 1.005, normalized) if success > 90 else 1.0
	return clampf(speed * factor, MIN_SPEED, MAX_SPEED)
