extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	game._set_paused(true)
	await frames(5)
	var settings: Node = game.hud.root.find_child("AudioSettings",true,false)
	check("Pause menu exposes sound controls",settings!=null)
	await finish_report("audio_settings","88 player audio preferences",started,"--verify-audio_settings")
