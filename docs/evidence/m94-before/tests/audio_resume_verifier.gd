extends "res://tests/equipment_map_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var prefs: AudioPreferences = game.audio_preferences
	var original_path := prefs.path
	var original_level := prefs.level
	var original_mute := prefs.muted
	prefs.path = "user://web-audio-preferences-probe.cfg"
	check("Audio preferences survive a fresh browser page",OS.is_userfs_persistent() and FileAccess.file_exists(prefs.path))
	var loaded := prefs.load_settings()
	check("Restart restores level and mute to the actual master bus",loaded and is_equal_approx(prefs.level,0.35) and prefs.muted and AudioServer.is_bus_mute(0) and absf(AudioServer.get_bus_volume_db(0)-linear_to_db(0.35))<0.01)
	check("Restarted controls reflect restored sound preferences",game.hud.audio_settings.readout.text=="35%" and game.hud.audio_settings.mute_button.button_pressed)
	DirAccess.remove_absolute(prefs.path)
	prefs.path = original_path
	prefs.level = original_level
	prefs.muted = original_mute
	prefs.apply()
	await finish_report("audio_resume","88 browser audio preference persistence",started,"--verify-audio_resume")
