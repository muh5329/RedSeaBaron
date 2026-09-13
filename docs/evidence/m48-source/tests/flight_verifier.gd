extends "res://tests/bike_verifier.gd"

func capture_flight(label: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/flight-native-"+label+".jpg")

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var saved_player := player.position
	var saved_bike := bike.position
	var started := Time.get_ticks_msec()
	await place(Vector2(0,110))
	await press("interact")
	check("Flight begins with exclusive seat ownership",seat.mounted)
	await press("transform_vehicle")
	check("Deployment begins through player input",bike.transformation.mode=="DEPLOYING")
	check("Repeated deployment rejected",not bike.transformation.request_toggle())
	await frames(75)
	check("Wings fully deploy with collision",bike.transformation.mode=="AIRCRAFT" and bike.transformation.progress==1 and not bike.transformation.wing_collision.disabled and bike.transformation.pivots[0].visible)
	await capture_flight("runway-hud-m46")
	await press("jump",20)
	check("Stationary takeoff rejected",not bike.flight.airborne)
	Input.action_press("move_forward")
	await frames(110)
	check("Runway acceleration reaches takeoff speed",bike.speed>=12,"speed=%.2f"%bike.speed)
	await capture_flight("ready-hud-m46")
	Input.action_press("jump")
	await frames(100)
	var height := bike.flight.altitude
	check("Takeoff and climb",bike.flight.airborne and height>5,"AGL=%.2f"%height)
	check("Airborne folding rejected",not bike.transformation.request_toggle() and bike.transformation.mode=="AIRCRAFT")
	check("Airborne dismount rejected",not seat.leave() and seat.mounted)
	check("Flight blocks weapon use",not game.combat.fire() and not game.combat.start_melee())
	await capture_flight("climb-hud-m46")
	release()
	var from := bike.position
	game._set_paused(true)
	await press("jump",20)
	check("Pause freezes aircraft",bike.position.distance_to(from)<0.001)
	game._set_paused(false)
	var heading := bike.rotation.y
	await press("move_right",40)
	check("Aircraft steering changes heading",absf(bike.rotation.y-heading)>0.5)
	from = bike.position
	Input.action_press("dodge")
	Input.action_press("move_back")
	await frames(90)
	check("Descent control lowers altitude",bike.position.y<from.y-1,"y=%.2f to %.2f"%[from.y,bike.position.y])
	await capture_flight("slow-hud-m46")
	var wait_frames := 0
	while bike.flight.airborne and wait_frames<240:
		await frames(1)
		wait_frames += 1
	release()
	check("Controlled landing restores grounded mode",not bike.flight.airborne and bike.is_on_floor() and bike.flight.landings>0,"position=%s"%bike.position)
	bike.speed = 0
	bike.velocity = Vector3.ZERO
	await press("transform_vehicle")
	await frames(80)
	check("Landed aircraft folds into bike",bike.transformation.mode=="BIKE" and bike.transformation.wing_collision.disabled and not bike.transformation.pivots[0].visible)
	check("Transition preserves one actor and vehicle",seat.mounted and bike.visual.rider.visible and not player.visible and game.orbit.follow_target==bike.camera_anchor)
	check("Grounded exit remains usable",seat.leave())
	await place(Vector2(0,110))
	await press("interact")
	var blocker := BlockoutKit.box(game,bike.position+Vector3(3,1.55,0),Vector3(1,3,2),Color("987e60"),true)
	await frames(3)
	check("Deployment into obstacle rejected",not bike.transformation.request_toggle() and bike.transformation.mode=="BIKE")
	blocker.queue_free()
	await frames(3)
	check("Deployment resumes after clearing obstacle",bike.transformation.request_toggle())
	blocker = BlockoutKit.box(game,bike.position+Vector3(3,1.55,0),Vector3(1,3,2),Color("987e60"),true)
	await frames(150)
	check("New obstruction during deployment aborts safely",bike.transformation.mode=="BIKE" and bike.transformation.wing_collision.disabled)
	blocker.queue_free()
	await frames(3)
	bike.transformation.request_toggle()
	await frames(80)
	bike.speed = 10
	check("High-speed folding rejected",not bike.transformation.request_toggle())
	bike.speed = 0
	bike.position.y = 30
	bike.flight.airborne = true
	game.combat.health.take_damage(999,&"hostile")
	await frames(135)
	check("Airborne death recovers actor and resets aircraft",not seat.mounted and player.visible and player.input_enabled and bike.transformation.mode=="BIKE" and not bike.flight.airborne)
	bike.position = saved_bike
	player.position = saved_player
	player.velocity = Vector3.ZERO
	game.orbit.snap()
	release()
	var passed := checks.filter(func(c): return c.passed).size()
	var report := {"milestone":"04 flight","passed":passed,"total":checks.size(),"platform":OS.get_name(),"elapsed_seconds":(Time.get_ticks_msec()-started)/1000.0,"tests":checks}
	print("RSB_FLIGHT_REPORT ",JSON.stringify(report))
	game.hud.verified_label.text = "FLIGHT: %d / %d PASSED" % [passed,checks.size()]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(()=>{let p=document.createElement('pre');p.id='flight-report';p.style='position:fixed;right:16px;top:16px;max-height:65vh;overflow:auto;max-width:460px;padding:16px;background:#152d29;color:#f4e3bb;z-index:10;font:12px monospace';p.textContent=%s;document.body.appendChild(p)})()" % JSON.stringify(JSON.stringify(report,"  ")),true)
	else:
		var file := FileAccess.open("res://docs/evidence/flight-native-report.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
	if "--verify-flight" in OS.get_cmdline_user_args():
		get_tree().quit(0 if passed==checks.size() else 1)
