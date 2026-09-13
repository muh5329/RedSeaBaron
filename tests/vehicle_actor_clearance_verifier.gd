extends "res://tests/worker_verifier.gd"

func overlaps_actor(actor: CharacterBody3D, vehicle: CharacterBody3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var body_shape: CollisionShape3D = actor.get_child(0)
	query.shape = body_shape.shape
	query.transform = body_shape.global_transform
	query.collision_mask = vehicle.collision_layer
	return game.get_world_3d().direct_space_state.intersect_shape(query).any(func(hit): return hit.collider==vehicle)

func parked(at: Vector3) -> void:
	release()
	bike.transformation.reset()
	bike.flight.reset()
	bike.position = at
	bike.rotation = Vector3.ZERO
	bike.velocity = Vector3.ZERO
	bike.speed = 0
	bike.input_enabled = false
	await frames(70)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	game.world.enabled = false
	BlockoutKit.box(game,Vector3(0,29.5,300),Vector3(80,1,100),Color("aa9870"),true)
	await parked(Vector3(0,32,300))
	var enemy := EnemyActor.new()
	enemy.target = player
	enemy.position = Vector3(3,30.08,300)
	enemy.home = enemy.position
	game.add_child(enemy)
	enemy.brain.enabled = false
	enemy.set_physics_process(false)
	await frames(3)
	check("Stationary hostile blocks wing deployment",not bike.transformation.request_toggle(),"mode=%s"%bike.transformation.mode)
	bike.transformation.reset()
	enemy.position = Vector3(20,30.08,300)
	var friendly: WorkerActor = game.workers.workers[0]
	friendly.position = Vector3(3,30.08,300)
	friendly.set_physics_process(false)
	await frames(3)
	check("Stationary worker blocks wing deployment",not bike.transformation.request_toggle(),"mode=%s"%bike.transformation.mode)
	bike.transformation.reset()
	friendly.position = Vector3(20,30.08,310)
	enemy.position = Vector3(0.8,30.08,298.1)
	await frames(3)
	check("Hostile standing in front propeller sweep blocks deployment",not bike.transformation.request_toggle(),"mode=%s"%bike.transformation.mode)
	bike.transformation.reset()
	enemy.position = Vector3(0,30.08,294)
	bike.input_enabled = true
	var overlaps := 0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = enemy.get_child(0).shape
	query.collision_mask = 8
	Input.action_press("move_forward")
	for i in range(140):
		await frames(1)
		query.transform = enemy.get_child(0).global_transform
		if game.get_world_3d().direct_space_state.intersect_shape(query).any(func(hit): return hit.collider==bike): overlaps += 1
	release()
	check("Driving motorcycle stops before a stationary hostile body",overlaps==0 and bike.position.z>295,"overlap frames=%d bike z=%.3f"%[overlaps,bike.position.z])
	var before := bike.position
	enemy.position.x = 20
	await frames(3)
	await press("move_forward",90)
	check("Moving the hostile away releases the motorcycle",bike.position.distance_to(before)>4)
	await parked(Vector3(0,32,300))
	friendly.position = Vector3(0,30.08,294)
	await frames(3)
	bike.input_enabled = true
	Input.action_press("move_forward")
	overlaps = 0
	for i in range(140):
		await frames(1)
		if overlaps_actor(friendly,bike): overlaps += 1
	release()
	check("Driving motorcycle also stops before a stationary worker",overlaps==0 and bike.position.z>295,"overlap frames=%d z=%.3f"%[overlaps,bike.position.z])
	friendly.position.x = 20
	await parked(Vector3(0,32,300))
	check("Clear space still permits wing deployment",bike.transformation.request_toggle())
	await frames(20)
	friendly.position = Vector3(3,30.08,300)
	overlaps = 0
	for i in range(80):
		await frames(1)
		if overlaps_actor(friendly,bike): overlaps += 1
	check("Worker entering the unfolding span causes a safe abort",overlaps==0 and bike.transformation.mode=="BIKE","overlap frames=%d mode=%s"%[overlaps,bike.transformation.mode])
	friendly.position.x = 20
	await frames(3)
	bike.transformation.request_toggle()
	await frames(75)
	check("Removing the worker permits complete aircraft deployment",bike.transformation.mode=="AIRCRAFT")
	enemy.position = Vector3(2.8,30.08,297.2)
	await frames(3)
	var old_yaw := bike.rotation.y
	check("Aircraft yaw cannot sweep a deployed wing through a hostile",not bike.try_turn(PI/4) and is_equal_approx(bike.rotation.y,old_yaw) and not overlaps_actor(enemy,bike))
	enemy.health.take_damage(1000,&"player")
	await frames(3)
	check("Defeated hostile no longer blocks aircraft yaw",enemy.collision_layer==0 and bike.try_turn(PI/4))
	await parked(Vector3(0,32,300))
	var cart: CargoCart = game.cart
	cart.position = bike.position+Vector3(0,0.2,3.3)
	cart.rotation = Vector3.ZERO
	cart.velocity = Vector3.ZERO
	player.position = bike.position+Vector3(1.65,0.2,0)
	player.velocity = Vector3.ZERO
	await frames(60)
	cart.inventory.add("ore",40)
	check("NPC-aware vehicles still mount and hitch a full cargo load",seat.enter() and game.hitch.toggle() and bike.cart_attached and cart.inventory.count("ore")==40)
	friendly.position = Vector3(0.95,30.08,292)
	await frames(3)
	Input.action_press("move_forward")
	overlaps = 0
	var largest_gap := 0.0
	for i in range(225):
		await frames(1)
		if overlaps_actor(friendly,cart): overlaps += 1
		largest_gap = maxf(largest_gap,Vector2(bike.position.x-cart.position.x,bike.position.z-cart.position.z).length())
	release()
	check("Loaded towing cannot drag cart geometry through a worker",overlaps==0 and largest_gap<4.6 and cart.inventory.count("ore")==40,"overlap frames=%d max gap=%.3f cart=%s"%[overlaps,largest_gap,cart.position])
	if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.position = cart.position+Vector3(7,4,-5)
		camera.look_at(cart.position+Vector3.UP)
		camera.current = true
		await frames(2)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/vehicle-npc-clearance-m100.jpg")
		camera.queue_free()
		game.orbit.camera.current = true
	friendly.position.x = 20
	await frames(3)
	before = cart.position
	await press("move_forward",120)
	check("Clearing the worker restores towing with all goods preserved",cart.position.distance_to(before)>4 and cart.inventory.count("ore")==40 and seat.mounted)
	await finish_report("vehicle_actor_clearance","100 vehicle motion against NPC bodies",started,"--verify-vehicle_actor_clearance")
