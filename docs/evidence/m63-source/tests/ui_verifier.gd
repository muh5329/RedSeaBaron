extends "res://tests/cart_verifier.gd"

func key(code: Key) -> void:
	game.verification_running = false
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await frames(2)
	game.verification_running = true

func capture(name: String) -> void:
	if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/ui-native-%s.jpg"%name)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await frames(60)
	game.combat.equip("RIFLE")
	var ammo: int = game.combat.ammunition
	await key(KEY_M)
	check("Map opens through real key event and pauses gameplay",game.hud.map_panel.visible and game.paused and not game.combat.enabled)
	var map: FieldMap = game.hud.map_drawing
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = get_viewport().get_final_transform()*(map.global_position+map.point(Vector3(39,0,67)))
	Input.parse_input_event(click)
	await frames(3)
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	click.position = get_viewport().get_final_transform()*(map.global_position+map.point(Vector3(39,0,67)))
	Input.parse_input_event(click)
	await frames(3)
	check("Map click selects a usable delivery waypoint",game.hud.waypoint!=null and Vector2(game.hud.waypoint.x-39,game.hud.waypoint.z-67).length()<2)
	check("Map clicking cannot fire rifle",game.combat.ammunition==ammo)
	check("Local map keeps region in panel bounds",Rect2(Vector2.ZERO,Vector2(510,390)).has_point(map.point(Vector3(155,0,155))) and Rect2(Vector2.ZERO,Vector2(510,390)).has_point(map.point(Vector3(-155,0,-155))))
	await capture("local-map")
	map.world_view = true
	map.queue_redraw()
	await frames(5)
	check("World map fits distant coordinates",Rect2(Vector2.ZERO,Vector2(510,390)).has_point(map.point(Vector3(12000,0,-12000))))
	await capture("world-map")
	await key(KEY_M)
	check("Closing map restores active controls",not game.paused and player.input_enabled and game.combat.enabled)
	await press("workers")
	check("Worker order panel is available",game.workers.panel.visible)
	await press("inventory")
	check("Cargo readout replaces worker panel",game.logistics.panel.visible and not game.workers.panel.visible)
	await capture("cargo")
	await press("workers")
	check("Worker panel replaces cargo readout",game.workers.panel.visible and not game.logistics.panel.visible)
	await capture("workers")
	await press("workers")
	for code in [KEY_B,KEY_N]:
		var pulse := InputEventKey.new()
		pulse.physical_keycode = code
		pulse.pressed = true
		Input.parse_input_event(pulse)
		pulse = InputEventKey.new()
		pulse.physical_keycode = code
		pulse.pressed = false
		Input.parse_input_event(pulse)
		await frames(3)
		check("Short key pulse opens "+("cargo" if code==KEY_B else "workers"),game.logistics.panel.visible if code==KEY_B else game.workers.panel.visible and not game.logistics.panel.visible)
	await press("workers")
	await key(KEY_ESCAPE)
	check("Pause menu fits viewport height",game.hud.menu.get_global_rect().end.y<=get_viewport().get_visible_rect().size.y)
	await capture("pause")
	await key(KEY_ESCAPE)
	check("Static render batching is active",game.region.merged_visuals>100,"merged=%d"%game.region.merged_visuals)
	check("Core terrain reduced to 25 bounded tiles",game.region.get_children().filter(func(n): return str(n.name).begins_with("Terrain_")).size()==25)
	# Pin the benchmark view; menu pointer capture must not change this sample.
	game.orbit.yaw = 0
	game.orbit.pitch = -0.27
	game.orbit.distance = 6.2
	game.orbit.snap()
	var calls: Array[float] = []
	var fps: Array[float] = []
	await frames(60)
	for i in range(30):
		await frames(2)
		calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		fps.append(Engine.get_frames_per_second())
	calls.sort()
	fps.sort()
	if DisplayServer.get_name()!="headless":
		check("Village draw calls reduced below prior 679 baseline",calls[15]>0 and calls[15]<400,"median calls=%.0f fps=%.0f"%[calls[15],fps[15]])
	await capture("village")
	if "--diagnose-shadows" in OS.get_cmdline_user_args():
		for light in game.region.get_children():
			if light is DirectionalLight3D: light.shadow_enabled = false
		await frames(4)
		await capture("village-no-shadows")
	await finish_report("ui","11 map and render readability",started,"--verify-ui")
