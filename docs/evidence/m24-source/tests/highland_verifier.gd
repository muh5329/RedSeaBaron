extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var at := Vector2(-1000,-10000)
	player.position = Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+3,at.y)
	player.velocity = Vector3.ZERO
	await frames(90)
	await place(at)
	check("Highland runway streams above old absolute ceiling",bike.is_on_floor() and bike.position.y>120,"height=%.2f"%bike.position.y)
	await press("interact")
	await press("transform_vehicle")
	await frames(75)
	check("Highland deployment preserves seat and wing clearance",seat.mounted and bike.transformation.mode=="AIRCRAFT")
	Input.action_press("move_forward")
	await frames(110)
	Input.action_press("jump")
	await frames(100)
	check("Aircraft can take off above 120 m terrain",bike.flight.airborne and bike.flight.altitude>7,"world y=%.2f AGL=%.2f"%[bike.position.y,bike.flight.altitude])
	if not bike.flight.airborne or bike.flight.altitude<7:
		release()
		await finish_report("highland","16 highland flight envelope",started,"--verify-highland")
		return
	var origin := bike.position
	var created: int = game.world.streamer.created
	await frames(300)
	check("Highland climb crosses real streamed terrain",bike.flight.airborne and bike.position.distance_to(origin)>100 and game.world.streamer.created>created,"position=%s AGL=%.2f"%[bike.position,bike.flight.altitude])
	await frames(180)
	check("Flight ceiling remains bounded relative to terrain",bike.flight.altitude>80 and bike.flight.altitude<116,"AGL=%.2f"%bike.flight.altitude)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/highland-native-cruise.jpg")
	release()
	Input.action_press("move_back")
	await frames(360)
	check("Low-speed flight loses lift",bike.speed<7 and bike.velocity.y<-1 and bike.flight.airborne,"speed=%.2f vertical=%.2f"%[bike.speed,bike.velocity.y])
	Input.action_press("dodge")
	var landed := await until(func(): return not bike.flight.airborne and bike.is_on_floor(),1500)
	release()
	await press("jump",25)
	check("Highland descent lands on active terrain",landed and absf(bike.position.y-CoastalRegion.height_at(bike.position.x,bike.position.z))<0.6 and bike.flight.landings==1,"height=%.2f ground=%.2f landings=%d"%[bike.position.y,CoastalRegion.height_at(bike.position.x,bike.position.z),bike.flight.landings])
	await press("transform_vehicle")
	await frames(80)
	check("Highland flight folds and allows grounded exit",bike.transformation.mode=="BIKE" and seat.leave())
	bike.recover()
	player.recover()
	await frames(30)
	await finish_report("highland","16 highland flight envelope",started,"--verify-highland")
