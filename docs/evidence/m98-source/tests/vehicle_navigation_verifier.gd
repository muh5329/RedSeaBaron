extends "res://tests/worker_verifier.gd"
var opponent: EnemyActor

func overlaps(body: Node3D, radius: float) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform.origin = body.position+Vector3.UP*0.9
	query.collision_mask = 8
	return not body.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func ground(at: Vector2) -> Vector3:
	return Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+0.1,at.y)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	worker = game.workers.workers[0]
	var nav: NavigationController = game.workers.navigation
	var started := Time.get_ticks_msec()
	game.world.enabled = false
	bike.position = ground(Vector2(0,80))+Vector3.UP
	player.position = ground(Vector2(8,80))
	game.combat.health.invulnerable = true
	await frames(100)
	bike.set_physics_process(false)
	check("Bike cell is blocked by actual vehicle occupancy",nav.grid.is_point_solid(nav.coordinate(bike.position)))
	var cold := NavigationController.new()
	game.add_child(cold)
	var initial_cell := cold.coordinate(bike.position)
	var initial_index := initial_cell.y*cold.side_cells+initial_cell.x
	await until(func(): return cold.cursor>initial_index,120)
	bike.position = ground(Vector2(-80,80))
	await frames(40)
	check("Moving during grid initialization clears the previously sampled cell",cold.ready_for_paths and not cold.grid.is_point_solid(initial_cell) and cold.grid.is_point_solid(cold.coordinate(bike.position)))
	bike.position = ground(Vector2(0,80))
	cold.queue_free()
	await frames(20)
	opponent = EnemyActor.new()
	opponent.target = player
	opponent.position = ground(Vector2(-4,80))
	opponent.home = opponent.position
	game.add_child(opponent)
	opponent.brain.enabled = false
	opponent.desired_velocity = Vector3.RIGHT*3
	var overlaps_seen := 0
	for i in range(150):
		await frames(1)
		if overlaps(opponent,0.4): overlaps_seen += 1
	check("Hostile locomotion stops before the motorcycle",overlaps_seen==0 and opponent.position.x< -0.7,"overlaps=%d x=%.3f"%[overlaps_seen,opponent.position.x])
	opponent.position = ground(Vector2(-8,80))
	opponent.home = opponent.position
	opponent.brain.navigation = nav
	opponent.brain.last_seen = player.position
	opponent.brain.memory_seconds = 8
	opponent.brain.machine.change(&"Pursue")
	opponent.brain.enabled = true
	var ticks := 0
	var detour := 0.0
	overlaps_seen = 0
	while opponent.position.x<3 and ticks<600:
		await frames(1)
		ticks += 1
		detour = maxf(detour,absf(opponent.position.z-80))
		if overlaps(opponent,0.4): overlaps_seen += 1
	check("Hostile pursuit routes around physical bike cover",opponent.position.x>=3 and detour>2 and opponent.brain.route_requests>0 and overlaps_seen==0,"x=%.2f detour=%.2f requests=%d overlaps=%d"%[opponent.position.x,detour,opponent.brain.route_requests,overlaps_seen])
	if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
		var view := Camera3D.new()
		game.add_child(view)
		view.position = bike.position+Vector3(8,5,8)
		view.look_at(bike.position+Vector3.UP)
		view.current = true
		await frames(2)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/vehicle-navigation-m97.jpg")
		view.queue_free()
		game.orbit.camera.current = true
	opponent.set_simulation(false)
	opponent.set_physics_process(false)
	var old := nav.coordinate(bike.position)
	bike.position = ground(Vector2(40,80))
	bike.set_physics_process(true)
	await frames(60)
	check("Moving a vehicle clears its old navigation footprint",not nav.grid.is_point_solid(old) and nav.grid.is_point_solid(nav.coordinate(bike.position)))
	var wing_cell := nav.coordinate(ground(Vector2(44,80)))
	var was_open := not nav.grid.is_point_solid(wing_cell)
	bike.transformation.request_toggle()
	await frames(90)
	check("Deploying wings expands navigation occupancy",was_open and bike.transformation.mode=="AIRCRAFT" and nav.grid.is_point_solid(wing_cell))
	bike.transformation.request_toggle()
	await frames(90)
	check("Folding wings clears the retired wing footprint",bike.transformation.mode=="BIKE" and not nav.grid.is_point_solid(wing_cell))
	game._set_paused(true)
	var samples := nav.dynamic_samples
	bike.position = ground(Vector2(44,80))
	await frames(30)
	check("Pause freezes dynamic navigation resampling",nav.dynamic_samples==samples)
	game._set_paused(false)
	game.world.enabled = false
	await frames(30)
	check("Resume reconciles vehicle occupancy changed while paused",nav.dynamic_samples>samples and nav.grid.is_point_solid(wing_cell))
	var obstacle := StaticBody3D.new()
	obstacle.collision_layer = 8
	obstacle.add_to_group("navigation_obstacles")
	obstacle.position = ground(Vector2(0,104))
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1,1.5,2)
	collider.shape = box
	collider.position.y = 0.75
	obstacle.add_child(collider)
	game.add_child(obstacle)
	await frames(20)
	var removed_cell := nav.coordinate(obstacle.position)
	var present := nav.grid.is_point_solid(removed_cell)
	obstacle.queue_free()
	await frames(20)
	check("Removed obstacle leaves no stale blocked cell",present and not nav.grid.is_point_solid(removed_cell))
	bike.position = ground(Vector2(0,80))
	await frames(60)
	bike.set_physics_process(false)
	var source := ResourceSource.new()
	source.item_id = "wood"
	source.position = ground(Vector2(7,80))
	game.add_child(source)
	source.stock.remove("wood",55)
	var destination := Storage.new()
	destination.position = ground(Vector2(-7,80))
	game.add_child(destination)
	var previous_home: Storage = worker.home
	worker.home = destination
	worker.position = ground(Vector2(-7,80))
	worker.velocity = Vector3.ZERO
	var job := JobDefinition.new()
	job.source = source
	job.destination = destination
	job.item_id = "wood"
	job.work_seconds = 0.4
	await frames(20)
	nav.refresh_near(source.position)
	nav.refresh_near(destination.position)
	check("Worker accepts a resource job across parked vehicle cover",worker.assign(job))
	overlaps_seen = 0
	ticks = 0
	while worker.machine.current!=&"Idle" and ticks<1500:
		await frames(1)
		ticks += 1
		if overlaps(worker,0.35): overlaps_seen += 1
	check("Worker physically detours and delivers without duplication",worker.machine.current==&"Idle" and destination.inventory.count("wood")==5 and source.stock.count("wood")==0 and worker.inventory.count("wood")==0 and overlaps_seen==0,"state=%s delivered=%d overlaps=%d"%[worker.machine.current,destination.inventory.count("wood"),overlaps_seen])
	worker.home = previous_home
	player.position = ground(Vector2(1.7,80))
	player.velocity = Vector3.ZERO
	await frames(20)
	var mounted := seat.enter()
	game.combat.health.restore()
	opponent.position = ground(Vector2(-8,80))
	opponent.home = opponent.position
	opponent.velocity = Vector3.ZERO
	opponent.brain.last_seen = bike.position
	opponent.brain.memory_seconds = 8
	opponent.brain.machine.change(&"Idle")
	opponent.brain.machine.change(&"Pursue")
	opponent.set_simulation(true)
	opponent.set_physics_process(true)
	var reached := await until(func(): return game.combat.health.current<100,600)
	check("Hostile pursuit can reach and strike an exposed mounted rider",mounted and reached and seat.mounted,"health=%.0f enemy=%s distance=%.2f state=%s"%[game.combat.health.current,opponent.position,opponent.position.distance_to(player.position),opponent.brain.machine.current])
	opponent.set_simulation(false)
	seat.leave(true)
	await frames(120)
	samples = nav.dynamic_samples
	await frames(30)
	check("Stationary vehicles do not repeatedly resample navigation",nav.dynamic_samples==samples,"additional samples=%d"%(nav.dynamic_samples-samples))
	check("Dynamic navigation remains bounded to local footprints",nav.maximum_dynamic_batch<=324,"maximum batch=%d largest update=%.3f ms"%[nav.maximum_dynamic_batch,nav.largest_dynamic_ms])
	await finish_report("vehicle_navigation","97 physical NPC vehicle navigation",started,"--verify-vehicle_navigation")
