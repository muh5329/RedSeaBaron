extends "res://tests/worker_verifier.gd"

func settle(n: int = 40) -> void:
	await frames(n)
	await get_tree().process_frame
	await get_tree().process_frame

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	if OS.has_feature("web"):
		# Audio needs a gesture after the canvas/input/audio driver has loaded.
		# A click during the export loading screen does not satisfy this gate.
		var activate := Button.new()
		activate.text = "Start wind audio checks"
		activate.position = Vector2(480,380)
		activate.size = Vector2(480,70)
		game.hud.root.add_child(activate)
		await activate.pressed
		activate.queue_free()
		game.combat.cancel()
		game.combat.block_until_released = true
	var started := Time.get_ticks_msec()
	game.world.enabled = false
	game.water.enabled = false
	player.set_physics_process(false)
	player.position = Vector3(0,50,100)
	game.audio.enabled = true
	await settle(60)
	var wind: WindAmbience = game.audio.wind
	check("Exploration has exactly one dedicated wind voice",wind!=null and game.audio.get_child_count()==10 and game.audio.voices.size()==8)
	check("Active exploration starts its wind loop",wind.playing and wind.gain>0 and wind.volume_db< -15,"playing=%s gain=%.5f db=%.2f"%[wind.playing,wind.gain,wind.volume_db])
	check("Wind uses a bounded preloaded circular clip",wind.stream is AudioStreamWAV and is_equal_approx(wind.stream.get_length(),12) and wind.stream.data.size()<600000 and wind.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and wind.stream.loop_end==264600)
	var open_gain := wind.target_gain
	var cover := BlockoutKit.box(game,player.position+Vector3.UP*3.2,Vector3(4,0.3,4),Color("9c825a"),true)
	await settle()
	check("Physical roof attenuates wind without stopping the loop",wind.sheltered and wind.target_gain<open_gain*0.3 and wind.playing,"open=%.5f sheltered=%.5f"%[open_gain,wind.target_gain])
	cover.queue_free()
	await settle()
	check("Leaving shelter restores open-air ambience",not wind.sheltered and is_equal_approx(wind.target_gain,open_gain))
	player.position.y = CoastalRegion.height_at(player.position.x,player.position.z)+0.05
	await settle()
	var ground_gain := wind.target_gain
	player.position.y += 50
	await settle()
	check("High exposed travel raises wind within a restrained ceiling",wind.target_gain>ground_gain*1.5 and wind.target_gain<=db_to_linear(-18)+0.0001,"ground=%.5f high=%.5f"%[ground_gain,wind.target_gain])
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 3
	var effect_index := AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0,capture)
	wind.seek(11.8)
	await settle(120)
	check("Wind crosses the loop boundary without stopping",wind.playing and wind.get_playback_position()<2,"loop time=%.3f"%wind.get_playback_position())
	var mixed := capture.get_buffer(capture.get_frames_available())
	var energy := 0.0
	var peak := 0.0
	for sample in mixed:
		energy += sample.length_squared()*0.5
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))
	var rms := sqrt(energy/maxi(1,mixed.size()))
	check("Loop boundary produces actual bounded mixer audio",mixed.size()>4000 and rms>0.0001 and peak<0.15,"frames=%d rms=%.6f peak=%.6f"%[mixed.size(),rms,peak])
	AudioServer.remove_bus_effect(0,effect_index)
	game._set_paused(true)
	await settle(3)
	check("Pause silences ambience and existing effects",not wind.playing and wind.gain==0 and not game.audio.engine.playing and game.audio.voices.all(func(voice): return not voice.playing))
	game._set_paused(false)
	player.set_physics_process(false)
	await settle(12)
	check("Resume fades the same wind voice back in",wind.playing and wind.gain>0 and wind.gain<wind.target_gain and game.audio.wind==wind)
	var queries := wind.context_queries
	for i in range(20):
		player.position = Vector3(100+i*350,80,-100-i*400)
		await settle(10)
	check("Repeated distant travel keeps voices and context queries bounded",game.audio.get_child_count()==10 and game.audio.voices.size()==8 and wind.context_queries-queries<=22,"voices=%d queries=%d"%[game.audio.get_child_count(),wind.context_queries-queries])
	game.audio.enabled = false
	await settle(3)
	check("Disabling audio stops wind and resets fade state",not wind.playing and wind.gain==0 and wind.target_gain==0)
	await finish_report("ambience","87 bounded exploration ambience",started,"--verify-ambience")
