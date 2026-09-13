extends "res://tests/wing_pose_verifier.gd"

func wing_overlaps() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = bike.transformation.wing_collision.shape
	query.transform = bike.transformation.wing_collision.global_transform
	query.collision_mask = 1
	query.exclude = [bike.get_rid()]
	return not game.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func reset_pose(airborne: bool = true) -> void:
	release()
	bike.position = Vector3(0,50,110)
	bike.rotation = Vector3.ZERO
	bike.visual.transform = Transform3D.IDENTITY
	bike.velocity = Vector3.ZERO
	bike.speed = 22
	bike.flight.airborne = airborne
	bike.flight.pitch = 0
	bike.transformation.mode = "AIRCRAFT"
	bike.transformation.progress = 1
	bike.transformation._present()
	bike.transformation.sync_wing_pose(Transform3D.IDENTITY)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await place(Vector2(0,110))
	seat.enter()
	game.world.enabled = false
	bike.set_physics_process(false)
	for action in ["move_right","move_left"]:
		reset_pose()
		var post_z := 0.70 if action=="move_right" else -0.60
		var solid := BlockoutKit.box(game,bike.position+Vector3(4.3,1.55,post_z),Vector3(0.035,0.4,0.035),Color("87634b"),true)
		await frames(3)
		check("Wing begins clear of narrow post: "+action,not wing_overlaps())
		Input.action_press(action)
		bike.flight.compute_velocity(1.0/60.0)
		check("Steering cannot rotate the wing into post: "+action,not wing_overlaps() and absf(bike.rotation.y)<0.001,"yaw=%.5f overlaps=%s"%[bike.rotation.y,wing_overlaps()])
		solid.queue_free()
		await frames(3)
		bike.flight.compute_velocity(1.0/60.0)
		check("Removing post immediately permits the same turn: "+action,absf(bike.rotation.y)>0.01 and not wing_overlaps())
	reset_pose(false)
	var ground_post := BlockoutKit.box(game,bike.position+Vector3(4.3,1.55,0.70),Vector3(0.035,0.4,0.035),Color("87634b"),true)
	await frames(3)
	Input.action_press("move_right")
	bike._physics_process(1.0/60.0)
	check("Ground aircraft steering also rejects blocked yaw",absf(bike.rotation.y)<0.001,"yaw=%.5f"%bike.rotation.y)
	ground_post.queue_free()
	await frames(3)
	bike._physics_process(1.0/60.0)
	check("Clear ground steering remains responsive",absf(bike.rotation.y)>0.01)
	reset_pose(false)
	bike.transformation.reset()
	var chassis_post := BlockoutKit.box(game,bike.position+Vector3(0.397,0.62,-1.20),Vector3(0.03,0.4,0.03),Color("87634b"),true)
	await frames(3)
	Input.action_press("move_right")
	bike._physics_process(1.0/60.0)
	check("Folded bike chassis also rejects obstructed steering",absf(bike.rotation.y)<0.001,"yaw=%.5f"%bike.rotation.y)
	chassis_post.queue_free()
	await frames(3)
	bike._physics_process(1.0/60.0)
	check("Folded bike turns as soon as cover is removed",absf(bike.rotation.y)>0.01)
	release()
	reset_pose(false)
	bike.transformation.reset()
	var cart: CargoCart = game.cart
	cart.set_physics_process(false)
	cart.position = Vector3(10,50,110)
	cart.rotation = Vector3.ZERO
	cart.velocity = Vector3.ZERO
	cart.enabled = true
	bike.position = cart.position+Vector3(-1,0,-3.3)
	cart.tow_vehicle = bike
	var cart_post := BlockoutKit.box(game,cart.position+Vector3(0.70,0.65,-1.035),Vector3(0.035,0.4,0.035),Color("87634b"),true)
	await frames(3)
	check("Cart starts clear of corner post",VehicleClearance.turn_clear(cart,cart.rotation.y,1))
	cart._physics_process(1.0/60.0)
	check("Trailer yaw cannot rotate its corner into world cover",absf(cart.rotation.y)<0.001,"yaw=%.5f"%cart.rotation.y)
	cart_post.queue_free()
	await frames(3)
	cart._physics_process(1.0/60.0)
	check("Removing cover permits the trailer to align",absf(cart.rotation.y)>0.01)
	release()
	cart.tow_vehicle = null
	cart.position = Vector3(40,50,110)
	var ramp := BlockoutKit.box(game,Vector3(0,9,80),Vector3(24,1,24),Color("a89974"),true)
	ramp.rotation = Vector3(deg_to_rad(15),0,deg_to_rad(12))
	for action in ["move_right","move_left"]:
		release()
		bike.flight.reset()
		bike.transformation.reset()
		bike.position = Vector3(0,14,80)
		bike.rotation = Vector3.ZERO
		bike.velocity = Vector3.ZERO
		bike.speed = 0
		bike.set_physics_process(true)
		await frames(100)
		Input.action_press("move_forward")
		Input.action_press(action)
		await frames(45)
		check("Open compound slope allows normal steering: "+action,bike.is_on_floor() and absf(bike.rotation.y)>0.2,"yaw=%.5f floor=%s"%[bike.rotation.y,bike.is_on_floor()])
		bike.set_physics_process(false)
	release()
	bike.flight.reset()
	bike.transformation.reset()
	bike.position = Vector3(0,14,80)
	bike.rotation = Vector3.ZERO
	bike.velocity = Vector3.ZERO
	bike.speed = 0
	cart.position = Vector3(0,14,83.3)
	cart.rotation = Vector3.ZERO
	cart.velocity = Vector3.ZERO
	cart.inventory.add("ore",10)
	bike.set_physics_process(true)
	cart.set_physics_process(true)
	await frames(100)
	var attached: bool = game.hitch.toggle()
	Input.action_press("move_forward")
	Input.action_press("move_right")
	await frames(120)
	check("Loaded trailer follows a real turn on compound ground",attached and bike.is_on_floor() and cart.is_on_floor() and bike.rotation.y < -0.3 and cart.rotation.y < -0.1 and cart.position.distance_to(bike.position)<4.6 and cart.inventory.count("ore")==10,"bike yaw=%.3f cart yaw=%.3f hitch=%.3f"%[bike.rotation.y,cart.rotation.y,cart.position.distance_to(bike.position)])
	ramp.queue_free()
	release()
	await finish_report("steering_clearance","57 vehicle steering clearance",started,"--verify-steering_clearance")
