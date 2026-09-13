extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await place(Vector2(0,80))
	var combat: PlayerCombat = game.combat
	combat.equip("WRENCH")
	combat.combo_window = 0
	player.visual.rotation.y = 0
	var enemy := EnemyActor.new()
	enemy.position = player.position+Vector3(0,0,-2)
	enemy.home = enemy.position
	enemy.target = player
	game.add_child(enemy)
	await frames(15)
	enemy.set_simulation(false)
	var swings := combat.swing_count
	var cue_count: int = game.audio.requests
	await press("attack")
	await until(func(): return combat.state=="RECOVERY",60)
	await press("attack")
	check("Late light attack enters bounded input buffer",combat.queued_attack)
	await frames(45)
	check("Buffered follow-up produces one valid combo hit",combat.swing_count==swings+2 and combat.combo==2 and enemy.health.current==35,"swings=%d HP=%.1f"%[combat.swing_count-swings,enemy.health.current])
	check("Combat emits swing and confirmed-hit feedback",game.audio.requests>=cue_count+4)
	player.stamina = 100
	await press("attack")
	await until(func(): return combat.state=="RECOVERY",60)
	await press("heavy_attack")
	swings = combat.swing_count
	game._set_paused(true)
	await frames(10)
	game._set_paused(false)
	await frames(50)
	check("Pause discards buffered attacks",combat.swing_count==swings and not combat.queued_attack and combat.state=="READY")
	player.stamina = 100
	await press("attack")
	await until(func(): return combat.state=="RECOVERY",60)
	await press("attack")
	swings = combat.swing_count
	await press("dodge")
	await frames(50)
	check("Dodge cancels buffered follow-up",combat.swing_count==swings and not combat.queued_attack)
	player.stamina = 100
	await press("attack")
	await until(func(): return combat.state=="RECOVERY",60)
	player.stamina = 0
	player.regen_delay = 3
	await press("attack")
	swings = combat.swing_count
	await frames(60)
	check("Buffered attack cannot bypass stamina cost",combat.swing_count==swings and not combat.queued_attack and player.stamina<1)
	var valid_clips := true
	for clip: AudioStream in GameAudio.CLIPS.values(): valid_clips = valid_clips and clip.get_length()>0.03 and clip.get_length()<1
	check("Original feedback clips load with bounded duration",valid_clips and GameAudio.CLIPS.size()==8)
	game.audio.enabled = false
	for i in range(50): game.audio.cue("hit",player.position)
	check("Audio requests use a fixed voice pool",game.audio.voices.size()==8 and game.audio.get_child_count()==9)
	if not OS.has_feature("web") and DisplayServer.get_name()!="headless":
		game.audio.enabled = true
		game.audio.cue("jump",player.position)
		await frames(2)
		check("Native cue starts an audio playback voice",game.audio.voices.any(func(v): return v.playing))
	game._set_paused(true)
	await frames(3)
	check("Pause silences effects and vehicle engine",not game.audio.engine.playing and game.audio.voices.all(func(v): return not v.playing))
	game._set_paused(false)
	game.audio.enabled = false
	player.stamina = 100
	if is_instance_valid(enemy): enemy.queue_free()
	await finish_report("feedback","13 combat feel and sound hooks",started,"--verify-feedback")
