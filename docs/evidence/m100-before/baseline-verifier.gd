extends "res://tests/worker_verifier.gd"

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
	await finish_report("vehicle_actor_clearance","100 vehicle motion against NPC bodies",started,"--verify-vehicle_actor_clearance")
