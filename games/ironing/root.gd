extends Node2D
## MARS HOMER: the app pauses the ironing game through this root; the game itself is the "Game" child.
var paused := false:
	set(value):
		paused = value
		if has_node("Game"):
			$Game.paused = value
