extends "res://tests/worker_verifier.gd"
const TIP := Vector3(4.2,1.55,0.05)

func at_tip(side: float, mask: int) -> Array[Dictionary]:
	var shape := SphereShape3D.new()
	shape.radius = 0.035
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = mask
	query.transform = Transform3D(Basis.IDENTITY,bike.visual.to_global(Vector3(TIP.x*side,TIP.y,TIP.z)))
	return game.get_world_3d().direct_space_state.intersect_shape(query)

func wings_supported() -> bool:
	for side in [-1.0,1.0]:
		if not at_tip(side,8).any(func(hit): return hit.collider==bike): return false
	return true

func attitude(action: String, duration: int) -> void:
	release()
	bike.position = Vector3(0,50,110)
	bike.rotation = Vector3.ZERO
	bike.velocity = Vector3.ZERO
	bike.speed = 22
	bike.flight.airborne = true
	await press(action,duration)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await place(Vector2(0,110))
	seat.enter()
	bike.transformation.request_toggle()
	await frames(75)
	Input.action_press("move_forward")
	await frames(110)
	Input.action_release("move_forward")
	await press("move_back",100)
	check("Wing pose test reaches flight through normal controls",bike.flight.airborne and bike.transformation.mode=="AIRCRAFT")
	for action in ["move_right","move_left","move_back","move_forward"]:
		await attitude(action,80 if action in ["move_back","move_forward"] else 40)
		check("Visible wingtips have collision while "+action,wings_supported(),"visual rotation=%s"%bike.visual.rotation)
	release()
	bike.flight.reset()
	bike.speed = 0
	bike.position = Vector3(0,CoastalRegion.height_at(0,110)+0.2,110)
	bike.velocity = Vector3.ZERO
	await frames(60)
	check("Grounded deployed wings retain matching collision",bike.is_on_floor() and wings_supported())
	# Exercise attitude rejection against a real solid at the raised wingtip.
	game.world.enabled = false
	bike.set_physics_process(false)
	bike.position = Vector3(0,50,110)
	bike.rotation = Vector3.ZERO
	bike.visual.transform = Transform3D.IDENTITY
	if bike.transformation.has_method("sync_wing_pose"):
		bike.transformation.call("sync_wing_pose",Transform3D.IDENTITY)
	var previous := bike.visual.transform
	var proposed := Transform3D(Basis(Vector3.BACK,0.30),Vector3.ZERO)
	var solid := BlockoutKit.box(game,bike.global_transform*proposed*TIP,Vector3.ONE*0.35,Color("87634b"),true)
	await frames(3)
	bike.visual.transform = proposed
	if bike.transformation.has_method("sync_wing_pose"):
		bike.transformation.call("sync_wing_pose",previous)
	await frames(3)
	check("A proposed attitude cannot put a visible wing inside cover",at_tip(1,1).is_empty())
	solid.queue_free()
	await frames(3)
	previous = bike.visual.transform
	bike.visual.transform = proposed
	if bike.transformation.has_method("sync_wing_pose"):
		bike.transformation.call("sync_wing_pose",previous)
	await frames(3)
	check("Clearing cover permits the attitude with matching collision",absf(bike.visual.rotation.z-0.30)<0.001 and wings_supported(),"roll=%.4f supported=%s process=%s"%[bike.visual.rotation.z,wings_supported(),bike.is_physics_processing()])
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.orbit.yaw = 0.5
		game.orbit.pitch = -0.30
		game.orbit.snap()
		await frames(3)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/wing-pose-native.jpg")
	await finish_report("wing_pose","43 deployed wing attitude collision",started,"--verify-wing_pose")
