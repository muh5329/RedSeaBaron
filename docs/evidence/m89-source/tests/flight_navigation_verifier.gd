extends "res://tests/equipment_map_verifier.gd"

func capture_navigation(label: String) -> void:
	await frames(20)
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args(): return
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/flight-navigation-m66-%s.jpg"%label)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await place(Vector2(0,110))
	check("Flight guidance fixture mounts through the normal seat",seat.enter())
	game.world.enabled = false
	bike.set_physics_process(false)
	bike.position = Vector3(0,45,110)
	bike.rotation = Vector3.ZERO
	bike.visual.transform = Transform3D.IDENTITY
	bike.speed = 22
	bike.velocity = Vector3(0,5,0)
	bike.flight.airborne = true
	bike.flight.altitude = 45-CoastalRegion.height_at(0,110)
	bike.transformation.mode = "AIRCRAFT"
	bike.transformation.progress = 1
	bike.transformation._present()
	var hud: VehicleHUD = game.hud.vehicle_status
	await frames(10)
	check("Unselected flight shows instruments without stale course guidance",hud.instruments.visible and hud.navigation_target==null and hud.condition.text.begins_with("IN FLIGHT"))
	for spec in [[Vector3(0,0,-1000),0],[Vector3(1000,0,0),90],[Vector3(0,0,1000),180],[Vector3(-1000,0,0),270]]:
		var course := hud.course_to(bike.position+spec[0],bike)
		check("Course identifies cardinal bearing %d"%spec[1],absf(course.bearing-spec[1])<0.01 and absf(course.distance-1000)<0.01)
	bike.rotation.y = deg_to_rad(-359)
	var toward_one := bike.position+Vector3(sin(deg_to_rad(1)),0,-cos(deg_to_rad(1)))*1000
	var north := hud.course_to(toward_one,bike)
	check("North wraparound chooses the short right turn",absf(north.turn-2)<0.01 and hud.course_label(toward_one,bike).contains("ON COURSE"),"turn=%.3f label=%s"%[north.turn,hud.course_label(toward_one,bike)])
	bike.rotation.y = deg_to_rad(-1)
	var toward_last := bike.position+Vector3(sin(deg_to_rad(359)),0,-cos(deg_to_rad(359)))*1000
	north = hud.course_to(toward_last,bike)
	check("Reverse north wraparound chooses the short left turn",absf(north.turn+2)<0.01 and hud.course_label(toward_last,bike).contains("ON COURSE"),"turn=%.3f label=%s"%[north.turn,hud.course_label(toward_last,bike)])
	for spec in [[350,10,20,"RIGHT 20°"],[10,350,-20,"LEFT 20°"]]:
		bike.rotation.y = deg_to_rad(-spec[0])
		var angle := deg_to_rad(spec[1])
		var target := bike.position+Vector3(sin(angle),0,-cos(angle))*1000
		var course := hud.course_to(target,bike)
		check("North-crossing cue directs a larger correction: "+spec[3],absf(course.turn-spec[2])<0.01 and hud.course_label(target,bike).contains(spec[3]))
	bike.rotation.y = 0
	await frames(6)
	check("Vertical instrument reads actual climb velocity",hud.instruments.text.contains("HDG 000°") and hud.instruments.text.contains("+5.0 m/s"))
	var instrument := hud.instruments.text
	game.orbit.yaw = PI/2
	game.orbit.snap()
	await frames(8)
	check("Looking sideways cannot alter the aircraft heading instrument",hud.instruments.text==instrument)
	var accepted: bool = game.logistics.contract.accept(game.hitch.backpack)
	await frames(6)
	check("Accepted delivery provides default aircraft course",accepted and hud.navigation_target==game.logistics.contract.destination.global_position and hud.condition.text.begins_with("COURSE"))
	await key(KEY_M)
	check("Map pause hides the flight panel and disables pilot input",game.paused and not game.hud.vehicle_panel.visible and not bike.input_enabled)
	var map: FieldMap = game.hud.map_drawing
	var selected := Vector3(120,CoastalRegion.height_at(120,-40),-40)
	await click_global(map.global_position+map.point(selected))
	await frames(6)
	check("Actual map selection overrides delivery course",hud.navigation_target!=null and hud.navigation_target.distance_to(selected)<0.1)
	await click_button(game.hud.clear_waypoint_button)
	await frames(6)
	check("Clearing selected waypoint resumes the active delivery course",hud.navigation_target==game.logistics.contract.destination.global_position)
	var credits: int = game.logistics.shop.credits
	game.hud.map_drawing.waypoint_selected.emit(bike.position+Vector3(3,-40,4))
	await frames(6)
	check("Nearby target uses horizontal range without claiming delivery completion",hud.condition.text=="TARGET NEARBY · 5 m" and game.logistics.contract.state=="IN_TRANSIT" and game.logistics.shop.credits==credits and game.hitch.backpack.count("package")==1)
	bike.speed = 8
	await frames(6)
	check("Low airspeed warning takes priority over course directions",hud.condition.text.begins_with("LOW AIRSPEED") and hud.warning_active)
	await key(KEY_M)
	game.world.enabled = false
	bike.set_physics_process(false)
	bike.speed = 22
	await frames(6)
	check("Expanded flight panel fits above the bottom controls",game.hud.vehicle_panel.get_global_rect().end.y<=get_viewport().get_visible_rect().size.y-95 and hud.instruments.get_global_rect().size.x>250)
	await capture_navigation("instruments")
	var before := bike.position
	var earlier := hud.condition.text
	bike.set_physics_process(true)
	Input.action_press("move_forward")
	Input.action_press("move_right")
	await frames(120)
	release()
	check("Guidance updates during actual aircraft movement",bike.flight.airborne and bike.position.distance_to(before)>30 and hud.condition.text!=earlier and hud.condition.text.begins_with("COURSE"),"travel=%.2f heading=%.1f"%[bike.position.distance_to(before),wrapf(rad_to_deg(-bike.rotation.y),0,360)])
	await capture_navigation("turning")
	await finish_report("flight_navigation","66 flight course guidance",started,"--verify-flight_navigation")
