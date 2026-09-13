extends "res://tests/wing_pose_verifier.gd"

func wing_point_hits(mask: int, corners: bool = false) -> int:
	var hits := 0
	var sphere := SphereShape3D.new()
	sphere.radius = 0.015
	for pivot in bike.transformation.pivots:
		var wing: MeshInstance3D = pivot.get_child(0)
		var points := [Vector3(1.85 if pivot.position.x>0 else -1.85,0,0)]
		if corners:
			points.clear()
			for y in [-0.045,0.045]:
				for z in [-0.55,0.55]: points.append(Vector3(1.95 if pivot.position.x>0 else -1.95,y,z))
		for point: Vector3 in points:
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = sphere
			query.transform.origin = wing.to_global(point)
			query.collision_mask = mask
			if not game.get_world_3d().direct_space_state.intersect_shape(query).is_empty(): hits += 1
	return hits

func ceiling() -> Node3D:
	return BlockoutKit.box(game,bike.position+Vector3(1.8,2.8,0.05),Vector3(0.55,0.15,1.5),Color("987957"),true)

func observe_transition() -> Dictionary:
	var result := {"sampled":0,"missing":0,"overlap":0}
	for i in range(80):
		await frames(1)
		if bike.transformation.progress>0.3 and bike.transformation.progress<0.7:
			result.sampled += 1
			if wing_point_hits(8)!=2: result.missing += 1
		if wing_point_hits(1,true)>0: result.overlap += 1
	return result

func capture_transition(name: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args(): return
	game.orbit.yaw = 0.8
	game.orbit.pitch = -0.22
	game.orbit.distance = 7
	game.orbit.snap()
	await frames(20)
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/wing-transition-m59-%s.jpg"%name)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	game.world.enabled = false
	BlockoutKit.box(game,Vector3(0,19.5,110),Vector3(24,1,24),Color("aa9c80"),true)
	bike.position = Vector3(0,23,110)
	player.position = Vector3(1.7,23,110)
	await frames(100)
	check("Transition fixture is mounted on solid ground",seat.enter() and bike.is_on_floor())
	var cover := ceiling()
	await frames(3)
	check("Full horizontal wing pose is clear below the higher obstruction",bike.transformation.clearance() and bike.transformation.request_toggle())
	var unfolding := await observe_transition()
	check("Collision follows both visible wings while unfolding",unfolding.sampled>0 and unfolding.missing==0,"samples=%d missing=%d"%[unfolding.sampled,unfolding.missing])
	check("Unfolding never moves visible wingtips through cover",unfolding.overlap==0,"overlapping frames=%d"%unfolding.overlap)
	check("Blocked unfolding waits before completing aircraft mode",bike.transformation.mode=="DEPLOYING" and bike.transformation.progress>0 and bike.transformation.progress<1,"mode=%s progress=%.3f"%[bike.transformation.mode,bike.transformation.progress])
	check("A blocked transformation cannot be saved",not game.saves.can_save())
	await capture_transition("unfolding")
	game._set_paused(true)
	var paused_progress := bike.transformation.progress
	await frames(30)
	check("Pause freezes blocked wing motion",bike.transformation.progress==paused_progress)
	game._set_paused(false)
	var blocked_position := bike.position
	Input.action_press("move_back")
	await frames(90)
	release()
	await frames(60)
	check("Reverse driving escapes blocked wings on solid ground",bike.position.distance_to(blocked_position)>1.5 and bike.is_on_floor() and not bike.flight.airborne,"moved=%.2f"%bike.position.distance_to(blocked_position))
	cover.queue_free()
	await frames(3)
	check("Escaping cover completes unfolding with matching collision",bike.transformation.mode=="AIRCRAFT" and wings_supported())
	cover = ceiling()
	await frames(3)
	check("Grounded aircraft can begin folding under the same high obstruction",bike.transformation.request_toggle())
	var folding := await observe_transition()
	check("Folding never moves visible wingtips through cover",folding.overlap==0 and folding.sampled>0 and folding.missing==0,"overlapping=%d missing=%d"%[folding.overlap,folding.missing])
	check("Blocked folding waits instead of clipping to bike mode",bike.transformation.mode=="FOLDING" and bike.transformation.progress>0 and bike.transformation.progress<1)
	await capture_transition("folding")
	cover.queue_free()
	await frames(90)
	var shapes: Array[CollisionShape3D] = [bike.transformation.wing_collision]
	shapes.append_array(bike.transformation.transition_shapes)
	shapes.append_array(bike.transformation.rear_collision.shapes)
	check("Clearing cover finishes folding and restores a savable motorcycle",bike.transformation.mode=="BIKE" and not shapes.is_empty() and shapes.all(func(shape): return shape.disabled) and bike.rider_collision.active and not bike.rider_collision.collision.disabled and game.saves.can_save(),"mode=%s aircraft_shapes=%d rider_active=%s savable=%s"%[bike.transformation.mode,shapes.size(),bike.rider_collision.active,game.saves.can_save()])
	await finish_report("wing_transition","59 partial wing motion clearance",started,"--verify-wing_transition")
