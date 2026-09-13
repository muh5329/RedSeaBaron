extends "res://tests/equipment_map_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await place()
	game.combat.equip("RIFLE")
	var ammunition: int = game.combat.ammunition
	game._set_paused(true)
	await frames(10)
	var prefs: AudioPreferences = game.audio_preferences
	var panel: AudioSettingsPanel = game.hud.audio_settings
	var original_path := prefs.path
	var original_level := prefs.level
	var original_mute := prefs.muted
	prefs.path = "user://verify_audio_settings.cfg"
	prefs.set_level(1)
	prefs.set_muted(false)
	check("Pause menu exposes sound controls",panel.is_visible_in_tree() and panel.volume.max_value==100 and panel.readout.text=="100%")
	await click_button(panel.mute_button)
	await frames(25)
	check("Real mute button silences the master bus",prefs.muted and AudioServer.is_bus_mute(0) and panel.mute_button.text=="Muted")
	await click_global(panel.volume.get_global_rect().position+Vector2(panel.volume.size.x*0.45,panel.volume.size.y*0.5))
	await frames(25)
	check("Real slider changes level while retaining deliberate mute",prefs.level>0.25 and prefs.level<0.65 and AudioServer.is_bus_mute(0) and absf(AudioServer.get_bus_volume_db(0)-linear_to_db(prefs.level))<0.01,"volume=%.2f"%prefs.level)
	var prior_level := prefs.level
	panel.volume.grab_focus()
	await key(KEY_RIGHT)
	await frames(25)
	check("Keyboard adjustment changes volume in one five-percent step",is_equal_approx(prefs.level,prior_level+0.05))
	await click_button(panel.mute_button)
	await frames(25)
	check("Unmute restores selected volume without restarting gameplay",not prefs.muted and not AudioServer.is_bus_mute(0) and game.paused and game.combat.ammunition==ammunition and not player.input_enabled)
	panel.volume.value = 0
	await frames(25)
	check("Zero volume is digitally muted with a matching readout",prefs.level==0 and AudioServer.is_bus_mute(0) and panel.readout.text=="0%")
	panel.volume.value = 35
	await frames(25)
	check("Debounced controls persist final level with no temporary file",FileAccess.file_exists(prefs.path) and not FileAccess.file_exists(prefs.path+".tmp") and panel.save_timer.is_stopped())
	var restored := AudioPreferences.new()
	restored.path = prefs.path
	check("Fresh preferences reload the saved level and unmuted state",restored.load_settings() and is_equal_approx(restored.level,0.35) and not restored.muted and not AudioServer.is_bus_mute(0))
	var invalid := ConfigFile.new()
	invalid.set_value("audio","volume","loud")
	invalid.set_value("audio","muted",false)
	invalid.save(prefs.path)
	var before_bad := restored.level
	check("Wrong-type preference file is rejected without changing audio",not restored.load_settings() and restored.level==before_bad and absf(AudioServer.get_bus_volume_db(0)-linear_to_db(before_bad))<0.01)
	invalid.set_value("audio","volume",5.0)
	invalid.save(prefs.path)
	check("Out-of-range persisted volume is rejected",not restored.load_settings() and restored.level==before_bad)
	restored.set_level(NAN)
	check("Non-finite adjustment cannot corrupt the mixer",restored.level==before_bad and is_finite(AudioServer.get_bus_volume_db(0)))
	game.hud.verified_label.visible = false
	game.hud.debug_label.visible = false
	await frames(2)
	await capture("audio-settings-m88")
	check("Audio controls fit the visible pause panel",game.hud.menu.get_global_rect().encloses(panel.get_global_rect()) and panel.volume.size.x>=140,"menu=%s controls=%s slider=%s"%[game.hud.menu.get_global_rect(),panel.get_global_rect(),panel.volume.size])
	if OS.has_feature("web"):
		var cross_page := AudioPreferences.new()
		cross_page.path = "user://web-audio-preferences-probe.cfg"
		cross_page.level = 0.35
		cross_page.muted = true
		check("Browser writes a separate restart preference probe",cross_page.store())
		await frames(240)
	panel.save_timer.stop()
	DirAccess.remove_absolute(prefs.path)
	prefs.path = original_path
	prefs.level = original_level
	prefs.muted = original_mute
	prefs.apply()
	await finish_report("audio_settings","88 player audio preferences",started,"--verify-audio_settings")
