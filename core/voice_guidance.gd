extends Node
## Bundled speech only: no runtime network or operating-system voice dependency.
signal spoken(key:String)
var player:AudioStreamPlayer
var language="en"
var enabled=true
var game_node:Node
var anchor=Vector2.ZERO
var idle_seconds=0.0
var quiet_seconds=20.0
var last_duration=0.0
var last_hits=0
var praise_index=0
var pending_intro=false
var active=false

func _ready()->void:
	language=str(Services.settings.get_value("voice","language","en"))
	if language not in ["en","ta"]: language="en"
	enabled=bool(Services.settings.get_value("voice","enabled",true))
	player=AudioStreamPlayer.new()
	player.volume_db=-3
	add_child(player)
	Trial.ended.connect(end_trial)

func set_language(value:String)->void:
	if value not in ["en","ta"]: return
	stop_speech()
	language=value
	Services.settings.set_value("voice","language",value)
	Services.save()

func set_enabled(value:bool)->void:
	enabled=value
	if not enabled: stop_speech()
	Services.settings.set_value("voice","enabled",value)
	Services.save()

func stop_speech()->void:
	player.stop()

var scene_key=""
var scene_time=-100.0

## A short prompt for a screen or a step of one (setup, assessment, errors, menus). It interrupts whatever
## is being said, because the screen has just changed. The same prompt is not repeated until
## `repeat_after` seconds have passed (0 = once per visit), so a patient who is slow is reminded
## now and then without being nagged.
func say(key:String,repeat_after:float=0.0)->bool:
	if not enabled or key=="": return false
	var now=Time.get_ticks_msec()/1000.0
	if key==scene_key and (repeat_after<=0.0 or now-scene_time<repeat_after): return false
	player.stop()
	if not play_clip(key): return false
	scene_key=key
	scene_time=now
	return true

## Leaving a screen: its prompt may be spoken again next time.
func forget()->void:
	scene_key=""

func speak(key:String)->bool:
	if not enabled or player.playing: return false
	return play_clip(key)

func play_clip(key:String)->bool:
	var path="res://assets/voice/%s/%s.mp3" % [language,key]
	if not ResourceLoader.exists(path): return false
	var clip=load(path) as AudioStreamMP3
	if clip==null: return false
	clip.loop=false
	player.stream=clip
	player.play()
	quiet_seconds=0
	spoken.emit(key)
	return true

func begin_trial(node:Node)->void:
	stop_speech()
	game_node=node
	active=true
	pending_intro=true
	anchor=Trial.player_position
	idle_seconds=0
	quiet_seconds=20
	last_duration=Trial.duration
	last_hits=Trial.hits

func end_trial()->void:
	active=false
	pending_intro=false
	game_node=null
	stop_speech()
	if Trial.last_result.get("reason","")=="COMPLETED": speak("finished")

func intentional_hold()->bool:
	if not is_instance_valid(game_node): return true
	match Trial.game:
		"DC": return float(game_node.hold)>0
		"FR": return float(game_node.dwell)>0 or game_node.fish_state!="waiting"
		"FW": return float(game_node.charge)>0 or float(game_node.fuse_time)>0 or float(game_node.cooldown)>0
		"SS": return absf(Trial.player_position.x-Trial.target_position.x)<0.05
		"PP": return absf(Trial.player_position.y-Trial.target_position.y)<0.10
	return false

func _process(_delta:float)->void:
	if not active or not Trial.running: return
	if not is_instance_valid(game_node):
		active=false
		stop_speech()
		return
	var step=maxf(0,Trial.duration-last_duration)
	last_duration=Trial.duration
	if Trial.paused or Trial.held():
		stop_speech()
		idle_seconds=0
		anchor=Trial.player_position
		return
	if not enabled: return
	if pending_intro:
		if Trial.duration<0.25: return
		pending_intro=not speak(Trial.game)
		anchor=Trial.player_position
		return
	if not player.playing: quiet_seconds+=step
	var physical_delta=(Trial.player_position-anchor)*Trial.rom
	if physical_delta.length()>=0.002:
		anchor=Trial.player_position
		idle_seconds=0
	elif Trial.target_open and not intentional_hold(): idle_seconds+=step
	else: idle_seconds=0
	if Trial.hits>last_hits:
		last_hits=Trial.hits
		idle_seconds=0
		if quiet_seconds>=10 and speak("good_%d" % (praise_index%3)): praise_index+=1
	if idle_seconds>=8 and quiet_seconds>=14:
		if speak("idle_"+Trial.movement): idle_seconds=0

