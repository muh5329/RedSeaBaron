extends SceneTree
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func _initialize() -> void: probe.call_deferred()
func probe() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.verification_session = true
	game._begin()
	game.world.enabled = false
	game.bike.position = Vector3(0,CoastalRegion.height_at(0,80)+2,80)
	game.player.position = Vector3(12,CoastalRegion.height_at(12,80)+2,80)
	await frames(100)
	game.bike.set_physics_process(false)
	var nav: NavigationController = game.workers.navigation
	var point: Vector3 = game.bike.position
	var cell := nav.coordinate(point)
	nav.refresh_near(point)
	var nav_blocked := nav.grid.is_point_solid(cell)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = nav.query.shape
	query.transform.origin = Vector3(0,CoastalRegion.height_at(0,80)+1.4,80)
	query.collision_mask = 8
	var hits := game.get_world_3d().direct_space_state.intersect_shape(query)
	var physical := hits.any(func(hit): return hit.collider==game.bike)
	var enemy := EnemyActor.new()
	enemy.target = game.player
	enemy.position = Vector3(-4,CoastalRegion.height_at(-4,80)+0.2,80)
	enemy.home = enemy.position
	game.add_child(enemy)
	enemy.brain.enabled = false
	enemy.desired_velocity = Vector3.RIGHT*3
	var overlap_samples := 0
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	query.shape = capsule
	for i in range(170):
		await frames(1)
		query.transform.origin = enemy.position+Vector3.UP*0.9
		if game.get_world_3d().direct_space_state.intersect_shape(query).any(func(hit): return hit.collider==game.bike): overlap_samples += 1
	var tests := [
		{"test":"Physical motorcycle occupies the navigation sample","passed":physical},
		{"test":"Navigation marks the occupied bike cell blocked","passed":nav_blocked},
		{"test":"Hostile body cannot walk through motorcycle","passed":overlap_samples==0,"overlap_samples":overlap_samples,"end_x":enemy.position.x}
	]
	var report := {"passed":tests.filter(func(t): return t.passed).size(),"total":tests.size(),"tests":tests}
	var out := FileAccess.open("res://docs/evidence/m97-body-baseline-report.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(report,"  "));out.close()
	print("RSB_BODY_BASELINE ",JSON.stringify(report))
	game.audio.enabled = false
	await process_frame
	await process_frame
	quit()
