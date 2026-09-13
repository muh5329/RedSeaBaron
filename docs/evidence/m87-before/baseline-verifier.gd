extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	game.audio.enabled = true
	await frames(5)
	var wind: AudioStreamPlayer = game.audio.get_node_or_null("WindAmbience")
	check("Exploration has a dedicated wind ambience voice",wind is AudioStreamPlayer)
	check("Active exploration starts its wind loop",wind!=null and wind.playing)
	await finish_report("ambience","87 bounded exploration ambience",started,"--verify-ambience")
