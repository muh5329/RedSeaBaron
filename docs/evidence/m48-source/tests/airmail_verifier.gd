extends "res://tests/integration_verifier.gd"

func scenario() -> Dictionary:
	return {"id":"airmail","route":"longfield","payment":180,"minimum_distance":900,"flight_frames":5400,"approach":[Vector2(924,1055),Vector2(924,1116)],"milestone":"22 town-to-Longfield flight delivery integration"}

func fly_toward(goal: Vector2) -> bool:
	var count := 0
	var limit: int = scenario().flight_frames
	while Vector2(bike.position.x,bike.position.z).distance_to(goal)>300 and count<limit:
		var offset := goal-Vector2(bike.position.x,bike.position.z)
		var heading := wrapf(atan2(-offset.x,-offset.y)-bike.rotation.y,-PI,PI)
		for action in ["move_left","move_right","jump","dodge"]: Input.action_release(action)
		if absf(heading)>0.025: Input.action_press("move_left" if heading>0 else "move_right")
		if bike.flight.altitude<40: Input.action_press("jump")
		elif bike.flight.altitude>55: Input.action_press("dodge")
		Input.action_press("move_forward")
		await frames(1)
		count += 1
	release()
	return count<limit and bike.flight.airborne

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var logi: LogisticsWorld = game.logistics
	var config := scenario()
	# Only initial fixture; no pose changes after accepting the parcel.
	await place(Vector2(12,6))
	bike.rotation.y = PI
	game.cart.rotation.y = PI
	game.cart.position = bike.position+bike.global_basis.z*3.3+Vector3.UP*0.15
	player.position = logi.dispatch.position+Vector3(0,0.1,2.5)
	await frames(20)
	for i in range(logi.routes.size()):
		if logi.route_id==config.route: break
		await press("delivery_route")
	await press("use_resource")
	check("Airmail contract loads selected parcel into workshop cart",logi.route_id==config.route and logi.contract.reward==config.payment and game.cart.inventory.count("package")==1)
	game.orbit.yaw = 0
	check("Player walks back to the loaded motorcycle",await walk_near(bike))
	await press("interact")
	await press("hitch_cart")
	check("Attached delivery cart blocks wing deployment",bike.cart_attached and not bike.transformation.request_toggle())
	Input.action_press("sprint")
	await press("load_cargo")
	Input.action_release("sprint")
	await press("hitch_cart")
	check("Flight preparation unloads parcel and parks the empty cart",game.hitch.backpack.count("package")==1 and game.cart.inventory.count("package")==0 and not bike.cart_attached)
	var cart_at: Vector3 = game.cart.position
	var distance_start := bike.travelled
	var arrived := await drive_to(Vector2(12,43))
	arrived = await drive_to(Vector2(0,105)) and arrived
	arrived = await drive_to(Vector2(25,135)) and arrived
	check("Delivery bike drives from town to a clear takeoff area",arrived)
	await press("transform_vehicle")
	await frames(80)
	Input.action_press("move_forward")
	await frames(120)
	Input.action_press("jump")
	await frames(130)
	check("Aircraft takes off with the parcel in player inventory",bike.flight.airborne and bike.flight.altitude>10 and game.hitch.backpack.count("package")==1)
	var goal := logi.selected_route().point
	var crossed := await fly_toward(goal)
	check("Airmail physically crosses the streamed world",crossed and bike.travelled-distance_start>config.minimum_distance and not game.world.core_active and game.world.streamer.chunks.size()<=25,"travelled=%.1f position=%s"%[bike.travelled-distance_start,bike.position])
	Input.action_press("move_back")
	Input.action_press("dodge")
	var landed := await until(func(): return not bike.flight.airborne and bike.is_on_floor(),1200)
	release()
	await press("jump",80)
	check("Parcel flight lands on real destination-region terrain",landed and game.world.streamer.collision_ready(bike.position) and game.hitch.backpack.count("package")==1)
	await press("transform_vehicle")
	await frames(80)
	check("Landing restores bike mode for final delivery approach",bike.transformation.mode=="BIKE" and seat.mounted)
	arrived = true
	for point: Vector2 in config.approach:
		arrived = await drive_to(point,2400) and arrived
	arrived = await drive_to(goal) and arrived
	check("Ground approach reaches the visible "+logi.selected_route().title+" desk",arrived and logi.contract.destination.is_visible_in_tree(),"position=%s"%bike.position)
	var crowns := logi.shop.credits
	await press("use_resource")
	check("Integrated flight delivery removes parcel and pays once",logi.contract.state=="COMPLETED" and logi.shop.credits==crowns+config.payment and game.hitch.backpack.count("package")==0)
	await press("use_resource")
	check("Repeat input cannot repay and distant parked cart stays intact",logi.shop.credits==crowns+config.payment and game.cart.position.distance_to(cart_at)<0.2 and game.cart.inventory.mass()==0)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/"+config.id+"-native-complete-m47.jpg")
	await finish_report(config.id,config.milestone,started,"--verify-"+config.id)
