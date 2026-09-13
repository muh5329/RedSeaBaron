extends "res://tests/worker_verifier.gd"
var cart: CargoCart

func maneuver(throttle: String, turn: String, count: int) -> Dictionary:
	release()
	Input.action_press(throttle)
	if not turn.is_empty(): Input.action_press(turn)
	var origin := bike.position
	var overlaps := 0
	var gap := 0.0
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	# Inset each face to distinguish penetration from ordinary touching.
	shape.size = Vector3(1.61,1.26,1.96)
	query.shape = shape
	query.collision_mask = 8
	query.exclude = [cart.get_rid()]
	for i in range(count):
		await frames(1)
		query.transform = cart.global_transform*Transform3D(Basis.IDENTITY,Vector3(0,0.65,0))
		if not game.get_world_3d().direct_space_state.intersect_shape(query).is_empty(): overlaps += 1
		gap = maxf(gap,bike.position.distance_to(cart.position))
	release()
	return {"travel":origin.distance_to(bike.position),"overlaps":overlaps,"gap":gap}

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	cart = game.cart
	var started := Time.get_ticks_msec()
	await place(Vector2(0,110))
	game.world.enabled = false
	var platform := BlockoutKit.box(game,Vector3(0,29.5,110),Vector3(140,1,180),Color("937957"),true)
	bike.position = Vector3(0,30.2,110)
	bike.velocity = Vector3.ZERO
	cart.position = bike.position+Vector3(0,0.1,3.3)
	cart.rotation = Vector3.ZERO
	cart.velocity = Vector3.ZERO
	player.position = bike.position+Vector3(1.65,0.1,0)
	player.velocity = Vector3.ZERO
	await frames(40)
	cart.inventory.add("ore",40)
	check("Loaded towing fixture mounts and hitches through normal interfaces",seat.enter() and game.hitch.toggle() and bike.cargo_mass==180)
	for spec in [["move_forward","move_left",240,"Forward turn"],["move_back","move_right",240,"Reverse turn"],["move_forward","move_right",240,"Forward recovery"]]:
		var result := await maneuver(spec[0],spec[1],spec[2])
		check(spec[3]+" makes progress",result.travel>3,"travel=%.3f"%result.travel)
		check(spec[3]+" keeps bike and cart solids separated",result.overlaps==0,"penetrating frames=%d"%result.overlaps)
		check(spec[3]+" preserves the drawbar constraint",result.gap<4.6,"max gap=%.3f"%result.gap)
		await press("jump",75)
	var straight := await maneuver("move_forward","",360)
	var relative := bike.global_basis.inverse()*(cart.position-bike.position)
	check("Straight driving recovers from a tight reverse",straight.travel>8,"travel=%.3f"%straight.travel)
	check("Recovered cart trails behind the bike",relative.z>2.8 and absf(relative.x)<0.5 and absf(angle_difference(cart.rotation.y,bike.rotation.y))<0.3,"cart in bike frame=%s"%relative)
	check("Straight recovery keeps both vehicle solids separated",straight.overlaps==0,"penetrating frames=%d"%straight.overlaps)
	await press("jump",75)
	check("Loaded maneuvers conserve all cargo",cart.inventory.count("ore")==40 and bike.cargo_mass==180)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.orbit.set_physics_process(false)
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.global_position = bike.position+bike.global_basis*Vector3(9,6,9)
		camera.look_at((bike.position+cart.position)*0.5+Vector3.UP)
		camera.current = true
		await frames(2)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/towing-native.jpg")
		camera.queue_free()
		game.orbit.camera.current = true
		game.orbit.set_physics_process(true)
	check("Cart can detach after reverse maneuvers",game.hitch.toggle() and cart.tow_vehicle==null)
	platform.queue_free()
	await finish_report("towing","45 loaded towing maneuvers",started,"--verify-towing")
