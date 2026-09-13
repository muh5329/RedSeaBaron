extends Node
## Runs in the actual game, on native and Web. Inputs drive PlayerController.
## Teleports establish isolated fixtures only; the integration route uses locomotion.
var game: Node3D
var player: PlayerController
var results: Array[Dictionary] = []
var fps_samples: Array[float] = []
var start_time: int
var saved_state: Dictionary
var captured_motion: Array[String] = []

func _frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame
		if i % 15 == 0 and Engine.get_frames_per_second() > 0:
			fps_samples.append(float(Engine.get_frames_per_second()))

func _release() -> void:
	for action: StringName in InputMap.get_actions():
		Input.action_release(action)

func _place(at: Vector2, yaw: float = 0.0) -> void:
	_release()
	player.global_position = Vector3(at.x, CoastalRegion.height_at(at.x, at.y) + 0.12, at.y)
	player.velocity = Vector3.ZERO
	player.dodge_remaining = 0
	player.stamina = 100
	player.regen_delay = 0
	player.sprint_exhausted = false
	game.orbit.yaw = yaw
	game.orbit.pitch = -0.27
	game.orbit.snap()
	await _frames(15)

func _hold(actions: Array[String], count: int) -> void:
	for action in actions:
		Input.action_press(action)
	var pose := "sprint" if "sprint" in actions else "walk"
	var capture_pose := count==60 and actions[0]=="move_forward" and actions.size()<=2 and pose not in captured_motion and "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
	if capture_pose:
		await _frames(30)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/avatar-m77-%s.jpg"%pose)
		var side_view := Camera3D.new()
		game.add_child(side_view)
		side_view.global_position = player.global_position+Vector3(3.5,1.35,0)
		side_view.look_at(player.global_position+Vector3.UP*0.90)
		side_view.current = true
		# New camera transforms need a physics/render synchronization boundary.
		# Keep the movement fixture at the same total 60 ticks.
		await _frames(2)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/avatar-m77-%s-side.jpg"%pose)
		side_view.queue_free()
		game.orbit.camera.current = true
		captured_motion.append(pose)
		await _frames(count-32)
	else:
		await _frames(count)
	_release()

func _tap_key(key: Key) -> void:
	var press := InputEventKey.new()
	press.physical_keycode = key
	press.keycode = key
	press.pressed = true
	Input.parse_input_event(press)
	await _frames(2)
	var release := InputEventKey.new()
	release.physical_keycode = key
	release.keycode = key
	release.pressed = false
	Input.parse_input_event(release)
	await _frames(2)

func _check(label: String, passed: bool, detail: String) -> void:
	results.append({"test": label, "passed": passed, "detail": detail})
	print("RSB_TEST | ", "PASS" if passed else "FAIL", " | ", label, " | ", detail)
	game.hud.verified_label.text = "TRAVERSAL CHECKS   %d / %d\n%s" % [results.filter(func(r): return r.passed).size(), results.size(), label]
	game.hud.verified_label.visible = true

func run(target: Node3D) -> void:
	game = target
	player = game.player
	start_time = Time.get_ticks_msec()
	saved_state = {"position": player.global_position, "spawn": player.spawn_position, "stamina": player.stamina, "yaw": game.orbit.yaw, "pitch": game.orbit.pitch, "distance": player.movement_distance, "jumps": player.jumps, "rolls": player.rolls, "sites": []}
	for site: SurveySite in game.sites:
		saved_state.sites.append(site.discovered)
	game.hud.notify("Traversal checks running. Please leave the controls idle.")
	game.orbit.input_enabled = false
	await _place(Vector2(0, 32))
	_check("Terrain grounding", player.is_on_floor(), "on_floor=%s; y=%.3f" % [player.is_on_floor(), player.position.y])
	var start := player.position
	await _hold(["move_forward"], 60)
	var walk_distance := Vector2(player.position.x - start.x, player.position.z - start.z).length()
	_check("Walk and forward direction", walk_distance > 3.9 and walk_distance < 5.1 and player.position.z < start.z, "distance=%.2f m in 60 ticks" % walk_distance)
	await _place(Vector2(0, 32))
	start = player.position
	await _hold(["move_forward", "sprint"], 60)
	var sprint_distance := Vector2(player.position.x - start.x, player.position.z - start.z).length()
	_check("Sprint and stamina drain", sprint_distance > walk_distance * 1.5 and player.stamina < 90, "distance=%.2f m; stamina=%.1f" % [sprint_distance, player.stamina])
	if "--capture-motion-only" in OS.get_cmdline_user_args():
		print("RSB_CAPTURE_ONLY | Motion photos complete; full traversal not run.")
		get_tree().quit()
		return
	await _frames(100)
	_check("Stamina recovery", player.stamina > 99, "stamina=%.1f" % player.stamina)
	await _place(Vector2(0, 32))
	start = player.position
	await _hold(["move_forward", "move_right"], 60)
	var diagonal := Vector2(player.position.x - start.x, player.position.z - start.z).length()
	_check("Normalized diagonal movement", absf(diagonal - walk_distance) < 0.35, "straight=%.2f; diagonal=%.2f" % [walk_distance, diagonal])
	await _place(Vector2(0, 32), PI / 2)
	start = player.position
	await _hold(["move_forward"], 60)
	_check("Camera-relative movement", player.position.x < start.x - 3.9 and absf(player.position.z - start.z) < 0.3, "delta=%s" % (player.position - start))
	await _place(Vector2(0, 32))
	var floor_y := player.position.y
	var max_y := floor_y
	var previous_jumps := player.jumps
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	for i in range(60):
		await _frames(1)
		max_y = maxf(max_y, player.position.y)
	_check("Jump apex and landing", max_y > floor_y + 1.1 and player.is_on_floor() and player.jumps == previous_jumps + 1, "apex=%.2f m; grounded=%s" % [max_y - floor_y, player.is_on_floor()])
	await _place(Vector2(0, 32))
	start = player.position
	var previous_rolls := player.rolls
	await _hold(["move_forward", "dodge"], 30)
	_check("Dodge displacement and one-shot input", player.position.distance_to(start) > 4.7 and player.rolls == previous_rolls + 1 and player.stamina < 80, "distance=%.2f; rolls=%d; stamina=%.1f" % [player.position.distance_to(start), player.rolls - previous_rolls, player.stamina])
	await _place(Vector2(0, 32))
	player.stamina = 5
	player.regen_delay = 2
	previous_rolls = player.rolls
	previous_jumps = player.jumps
	await _hold(["dodge", "jump"], 20)
	_check("Insufficient stamina rejects actions", player.rolls == previous_rolls and player.jumps == previous_jumps, "No roll or jump at 5 stamina")
	await _place(Vector2(0, 32))
	player.stamina = 1
	await _hold(["move_forward", "sprint"], 35)
	_check("Sprint exhaustion falls back to walk", player.sprint_exhausted and Vector2(player.velocity.x, player.velocity.z).length() < 5.0, "speed=%.2f; exhausted=%s" % [player.velocity.length(), player.sprint_exhausted])
	await _place(Vector2(33, 20))
	await _hold(["move_right", "sprint"], 60)
	_check("Wall blocks sprint", player.position.x < 35.8 and player.position.x > 35.2, "wall x=36; player x=%.3f" % player.position.x)
	await _place(Vector2(33, 20))
	await _hold(["move_right", "dodge"], 32)
	_check("Wall blocks dodge tunnelling", player.position.x < 35.8 and player.is_on_floor(), "x=%.3f; grounded=%s" % [player.position.x, player.is_on_floor()])
	await _place(Vector2(33, 20), PI / 2)
	await _frames(15)
	var blocked_length: float = game.orbit.arm.get_hit_length()
	_check("Camera retracts before obstacle", blocked_length > 0.5 and blocked_length < 3.1, "arm=%.2f / %.2f m" % [blocked_length, game.orbit.distance])
	await _place(Vector2(0, 32))
	await _frames(15)
	_check("Camera returns to full clearance", game.orbit.arm.get_hit_length() > 5.8, "arm=%.2f m" % game.orbit.arm.get_hit_length())
	start = player.position
	game._set_paused(true)
	previous_jumps = player.jumps
	await _hold(["move_forward", "sprint", "jump", "dodge", "interact"], 30)
	_check("Pause gates movement and actions", player.position.distance_to(start) < 0.01 and player.jumps == previous_jumps, "delta=%.4f" % player.position.distance_to(start))
	game._set_paused(false)
	game.orbit.input_enabled = false
	await _place(Vector2(0, 32))
	game.hud.map_panel.visible = false
	# Map uses the same production pause function; verify its actual event handler.
	game.verification_running = false
	await _tap_key(KEY_M)
	var map_open: bool = game.hud.map_panel.visible and game.paused
	await _hold(["move_forward"], 15)
	await _tap_key(KEY_M)
	game.verification_running = true
	game.orbit.input_enabled = false
	_check("Map toggles and releases controls", map_open and not game.paused and not game.hud.map_panel.visible and player.input_enabled, "map opened/closed via real InputEventKey dispatch")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _place(Vector2(0, 32))
	player.position.y = -12
	await _frames(15)
	_check("Out-of-bounds recovery", player.position.y > 0 and player.position.distance_to(player.spawn_position) < 1.0, "position=%s" % player.position)
	# Full route: no teleporting between survey stations.
	await _place(Vector2(0, 12))
	for site: SurveySite in game.sites:
		site.discovered = false
	game.hud.update_route()
	var nodes: Array[Vector2] = [Vector2(0, -0.5), Vector2(-2, -34), Vector2(-47, -55.5), Vector2(-2, -34), Vector2(0, -67), Vector2(47, -89.5)]
	var route_ok := true
	var stations_reached: int = 0
	var max_ground_error: float = 0.0
	for node_index in range(nodes.size()):
		var waypoint := nodes[node_index]
		var reached := false
		for tick in range(1500):
			var difference := waypoint - Vector2(player.position.x, player.position.z)
			if difference.length() < 0.7:
				reached = true
				break
			var unit := difference.normalized()
			Input.action_press("move_right", maxf(0, unit.x))
			Input.action_press("move_left", maxf(0, -unit.x))
			Input.action_press("move_back", maxf(0, unit.y))
			Input.action_press("move_forward", maxf(0, -unit.y))
			if player.stamina > 25:
				Input.action_press("sprint")
			else:
				Input.action_release("sprint")
			await _frames(1)
			if player.is_on_floor():
				max_ground_error = maxf(max_ground_error, absf(player.position.y - CoastalRegion.height_at(player.position.x, player.position.z)))
		_release()
		await _frames(15)
		if not reached:
			route_ok = false
			_check("Route waypoint %d" % node_index, false, "stalled at %s, target=%s" % [player.position, waypoint])
			break
		if node_index in [0, 2, 5]:
			await _hold(["interact"], 2)
			await _frames(8)
			stations_reached += 1
		game.hud.notify("Verifier route: waypoint %d / %d" % [node_index + 1, nodes.size()])
	_check("Integrated survey route", route_ok and game.hud.route_complete and game.hud.visited_count == 3, "stops=%d; stamps=%d; grounded surface deviation=%.3f" % [stations_reached, game.hud.visited_count, max_ground_error])
	var count_before: int = game.hud.visited_count
	await _hold(["interact"], 2)
	_check("Repeated interaction is idempotent", game.hud.visited_count == count_before, "stamps=%d" % game.hud.visited_count)
	# Out-of-range calls cannot stamp a landmark.
	var remote: SurveySite = game.sites[0]
	var remote_was_discovered := remote.discovered
	remote.discovered = false
	var denied := not remote.interact(player)
	_check("Remote interaction rejected", denied and not remote.discovered, "distance=%.1f m" % player.position.distance_to(remote.position))
	remote.discovered = remote_was_discovered
	# Adversarial jump/dodge spam: one dodge, no jump or negative stamina.
	await _place(Vector2(0, 32))
	previous_rolls = player.rolls
	previous_jumps = player.jumps
	await _hold(["dodge", "jump"], 2)
	for i in range(5):
		await _hold(["dodge", "jump"], 2)
		await _frames(1)
	_check("Action spam preserves state", player.rolls == previous_rolls + 1 and player.jumps == previous_jumps and player.stamina >= 0, "rolls=%d; jumps=%d; stamina=%.1f" % [player.rolls - previous_rolls, player.jumps - previous_jumps, player.stamina])
	_release()
	await _frames(40)
	await _finish()

func _finish() -> void:
	var passed := results.filter(func(r): return r.passed).size()
	fps_samples.sort()
	var median_fps := fps_samples[fps_samples.size() / 2] if not fps_samples.is_empty() else 0.0
	var report := {
		"milestone": "01 - traversal foundations", "engine": Engine.get_version_info().string,
		"platform": OS.get_name(), "passed": passed, "total": results.size(),
		"elapsed_seconds": (Time.get_ticks_msec() - start_time) / 1000.0,
		"median_fps": median_fps,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"tests": results
	}
	var json := JSON.stringify(report, "  ")
	print("RSB_REPORT ", JSON.stringify(report))
	if OS.has_feature("web"):
		# User-visible verifier report, available to browser DOM inspection.
		var script := "(() => {let p=document.getElementById('verification-report');if(!p){p=document.createElement('pre');p.id='verification-report';p.style='position:fixed;right:18px;top:18px;max-height:65vh;overflow:auto;max-width:460px;background:#152d29;color:#f4e3bb;padding:18px;font:12px monospace;z-index:10';document.body.appendChild(p);}p.textContent=%s;})()" % JSON.stringify(json)
		JavaScriptBridge.eval(script, true)
	else:
		var file := FileAccess.open("res://docs/evidence/native-report.json", FileAccess.WRITE)
		if file:
			file.store_string(json)
	_release()
	player.global_position = saved_state.position
	player.spawn_position = saved_state.spawn
	player.velocity = Vector3.ZERO
	player.stamina = saved_state.stamina
	player.dodge_remaining = 0
	player.movement_distance = saved_state.distance
	player.jumps = saved_state.jumps
	player.rolls = saved_state.rolls
	game.orbit.yaw = saved_state.yaw
	game.orbit.pitch = saved_state.pitch
	game.orbit.snap()
	for i in range(game.sites.size()):
		var site: SurveySite = game.sites[i]
		site.discovered = saved_state.sites[i]
		site.marker.material_override = BlockoutKit.material(Color("80b5a0") if site.discovered else Color("e9bd71"))
	game.hud.update_route()
	game.hud.verified_label.text = "TRAVERSAL CHECKS: %d / %d PASSED" % [passed, results.size()]
	game.hud.notify("Verification complete. Your exploration state has been restored.")
	game.orbit.input_enabled = true
	if "--verify" in OS.get_cmdline_user_args() and not OS.has_feature("web"):
		get_tree().quit(0 if passed == results.size() else 1)
