extends SceneTree
var failures=0
var heard:Array=[]
func check(ok:bool,message:String)->void:
	if not ok:
		failures+=1
		push_error(message)
func _initialize()->void: call_deferred("run")
func run()->void:
	var voice=root.get_node("Voice")
	var trial=root.get_node("Trial")
	voice.set_process(false)
	voice.spoken.connect(func(key): heard.append(key))
	for language in ["en","ta"]:
		for key in ["SS","PP","DC","TW","TT","CB","MC","FR","BS","FW","ST","idle_ML","idle_AP","idle_MLAP","good_0","good_1","good_2","preview","finished","setup_connect","setup_calibrate","setup_angles","setup_activate","setup_activating","setup_attach","setup_attached","setup_plane","setup_ready","detach_remove","detach_lower","detach_done","error_generic","error_limit","error_link","assess_start","assess_ml","assess_ap","assess_mlap","assess_weight","assess_review","assess_weight_review","assess_saved","login","plan_setup","welcome","choose_move","choose_game","assess_needed","plane","summary"]:
			var clip=load("res://assets/voice/%s/%s.mp3" % [language,key]) as AudioStreamMP3
			check(clip!=null and clip.get_length()>0.5,"Playable bundled clip "+language+"/"+key)
	# Scene prompts: said once, repeated only after the interval, and a new prompt replaces the old.
	voice.enabled=true
	voice.language="en"
	voice.forget()
	heard.clear()
	check(voice.say("setup_attach",10.0),"A screen prompt is spoken")
	check(not voice.say("setup_attach",10.0),"The same prompt is not repeated straight away")
	voice.scene_time-=11.0
	check(voice.say("setup_attach",10.0),"A waiting patient is reminded after the interval")
	check(voice.say("setup_attached") and heard[-1]=="setup_attached","A new step replaces the old prompt")
	check(not voice.say("setup_attached"),"A once-only prompt is not repeated")
	voice.forget()
	check(voice.say("setup_attached"),"Leaving the screen lets its prompt be spoken again")
	check(not voice.say("no_such_key"),"An unknown prompt is ignored")
	voice.enabled=false
	check(not voice.say("welcome"),"Muted voice stays silent")
	voice.enabled=true
	voice.stop_speech()
	heard.clear()
	var game=load("res://core/legacy_game.gd").new()
	trial.running=true
	trial.game="DC"
	trial.movement="MLAP"
	trial.rom=Vector2(.3,.3)
	trial.player_position=Vector2.ZERO
	trial.target_position=Vector2.ONE
	trial.target_open=true
	trial.hits=0
	trial.duration=0
	voice.enabled=true
	voice.language="ta"
	voice.begin_trial(game)
	trial.duration=.3
	voice._process(.3)
	check(heard==["DC"],"One game-specific Tamil introduction")
	check(voice.player.stream.resource_path.contains("/ta/"),"Selected Tamil recording is used")
	check(not voice.speak("good_0"),"Speech cannot overlap")
	voice.stop_speech()
	voice.quiet_seconds=20
	game.hold=.5
	trial.duration+=10
	voice._process(10)
	check(heard.size()==1,"No movement reminder during a deliberate hold")
	game.hold=0
	trial.duration+=9
	voice._process(9)
	check(heard[-1]=="idle_MLAP","Idle patient receives movement-specific reminder")
	voice.stop_speech()
	trial.duration+=9
	voice._process(9)
	check(heard.size()==2,"Reminder cooldown prevents nagging")
	voice.quiet_seconds=20
	trial.player_position=Vector2(.1,0)
	trial.duration+=1
	voice._process(1)
	check(voice.idle_seconds==0,"Movement resets inactivity")
	trial.hits=1
	trial.duration+=1
	voice._process(1)
	check(heard[-1]=="good_0","Success receives encouragement")
	trial.paused=true
	voice._process(.1)
	check(not voice.player.playing,"Pause stops speech")
	trial.paused=false
	voice.enabled=false
	voice.quiet_seconds=50
	trial.duration+=20
	voice._process(20)
	check(heard.size()==3,"Voice off stays silent")
	voice.end_trial()
	trial.running=false
	game.free()
	root.get_node("Music").enabled=false
	root.get_node("Music").player.stop()
	await create_timer(0.3).timeout
	print("Voice guidance: %d failures" % failures)
	quit(1 if failures else 0)
