class_name MemeAudio
extends Node
## Plays short sound clips on game events. Put your own clips in
## assets/audio/memes/<event>/ (.ogg, .wav or .mp3). One is picked at random each time.
## An empty or missing folder just means silence, so the game runs without any clips.
##
## Events: start, grab, drop, soup_1, soup_2, soup_3, oops, end

const ROOT := "res://games/cooking/assets/audio/memes/"
const EVENTS := ["start", "grab", "drop", "soup_1", "soup_2", "soup_3", "oops", "end"]
## Minimum seconds between two clips, so the sounds never pile up.
const GAP_SECONDS := 1.2

@export var volume_db := 0.0
@export var enabled := true

var _clips := {}
var _player: AudioStreamPlayer
var _last_ms := -100000
var _last_clip: AudioStream


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = volume_db
	add_child(_player)
	for event: String in EVENTS:
		_clips[event] = _load_folder(ROOT + event)


func has_clips(event: String) -> bool:
	return not (_clips.get(event, []) as Array).is_empty()


## important clips (results, stars) interrupt whatever is playing.
func play(event: String, important := false) -> void:
	if not enabled:
		return
	var options: Array = _clips.get(event, [])
	if options.is_empty():
		return
	var now := Time.get_ticks_msec()
	if not important and (now - _last_ms < int(GAP_SECONDS * 1000.0) or _player.playing):
		return
	var pick: AudioStream = options.pick_random()
	if options.size() > 1 and pick == _last_clip:
		pick = options.pick_random()
	_last_clip = pick
	_last_ms = now
	_player.stream = pick
	_player.play()


func _load_folder(path: String) -> Array:
	var found := []
	var seen := {}
	if not DirAccess.dir_exists_absolute(path):
		return found   # no clips supplied: silence
	for file in DirAccess.get_files_at(path):
		# Exported games list "x.mp3.import" instead of "x.mp3".
		var name := file.trim_suffix(".import")
		if seen.has(name) or name.get_extension().to_lower() not in ["ogg", "wav", "mp3"]:
			continue
		seen[name] = true
		var stream := load(path + "/" + name) as AudioStream
		if stream != null:
			found.append(stream)
	return found
