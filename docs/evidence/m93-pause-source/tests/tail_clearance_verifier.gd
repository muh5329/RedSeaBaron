extends "res://tests/wing_pose_verifier.gd"
const TAIL_POINTS := {"fin":Vector3(0,2.48,2.4),"stabilizer":Vector3(1.0,1.2,2.4),"propeller":Vector3(0.88,1.16,2.9),"shaft":Vector3(0,1.08,1.8)}

func tail_hits(point: Vector3, mask: int) -> bool:
	var sphere := SphereShape3D.new()
	sphere.radius = 0.015
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform.origin = bike.transformation.tail.to_global(point)
	query.collision_mask = mask
	return not game.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await place(Vector2(0,110))
	check("Tail fixture mounts on grounded motorcycle",seat.enter() and bike.is_on_floor())
	bike.transformation.request_toggle()
	await frames(75)
	for part: String in TAIL_POINTS:
		check("Deployed aircraft collision covers its "+part,tail_hits(TAIL_POINTS[part],8))
	var grounded := bike.position
	for action in ["move_right","jump"]:
		await attitude(action,40 if action=="move_right" else 80)
		var covered := true
		for part: String in TAIL_POINTS: covered = covered and tail_hits(TAIL_POINTS[part],8)
		check("Rear collision follows actual flight attitude: "+action,covered)
	bike.flight.reset()
	bike.transformation.reset()
	bike.position = grounded
	bike.rotation = Vector3.ZERO
	bike.velocity = Vector3.ZERO
	bike.speed = 0
	await frames(60)
	var cover := BlockoutKit.box(game,bike.position+Vector3(0,1.5,3.0),Vector3(3,3,0.3),Color("87634b"),true)
	await frames(3)
	check("Tail obstruction prevents deployment despite clear wings",not bike.transformation.request_toggle() and bike.transformation.mode=="BIKE")
	bike.transformation.reset()
	cover.queue_free()
	await frames(3)
	check("Clearing rear space permits deployment",bike.transformation.request_toggle())
	await frames(32)
	var partial_covered := true
	for part: String in TAIL_POINTS: partial_covered = partial_covered and tail_hits(TAIL_POINTS[part],8)
	check("Visible rear assembly retains collision during its transition",bike.transformation.progress>0.3 and bike.transformation.progress<0.7 and partial_covered,"progress=%.3f"%bike.transformation.progress)
	await frames(60)
	cover = BlockoutKit.box(game,bike.position+Vector3(0,1.5,3.15),Vector3(3,3,0.25),Color("87634b"),true)
	await frames(3)
	var from := bike.position
	var overlap := 0
	Input.action_press("move_back")
	for i in range(60):
		await frames(1)
		for part: String in TAIL_POINTS:
			if tail_hits(TAIL_POINTS[part],1): overlap += 1
	release()
	check("Reverse driving stops the rear assembly before a wall",bike.position.z-from.z<0.3 and overlap==0,"reverse=%.3f overlapping samples=%d"%[bike.position.z-from.z,overlap])
	cover.queue_free()
	await frames(3)
	game.world.enabled = false
	bike.set_physics_process(false)
	bike.position = Vector3(0,50,110)
	bike.rotation = Vector3.ZERO
	bike.visual.transform = Transform3D.IDENTITY
	bike.transformation.mode = "AIRCRAFT"
	bike.transformation.progress = 1
	bike.transformation._present()
	bike.transformation.sync_wing_pose(Transform3D.IDENTITY)
	var proposed := Transform3D(Basis(Vector3.BACK,0.3),Vector3.ZERO)
	cover = BlockoutKit.box(game,bike.global_transform*proposed*TAIL_POINTS.fin,Vector3.ONE*0.2,Color("87634b"),true)
	await frames(3)
	check("Rear attitude fixture starts clear of cover",not tail_hits(TAIL_POINTS.fin,1))
	bike.visual.transform = proposed
	bike.transformation.sync_wing_pose(Transform3D.IDENTITY)
	await frames(3)
	check("Visual banking cannot rotate the fin into cover",absf(bike.visual.rotation.z)<0.001 and not tail_hits(TAIL_POINTS.fin,1))
	cover.queue_free()
	await frames(3)
	bike.visual.transform = proposed
	bike.transformation.sync_wing_pose(Transform3D.IDENTITY)
	await frames(3)
	check("Cleared fin can bank with matching collision",absf(bike.visual.rotation.z-0.3)<0.001 and tail_hits(TAIL_POINTS.fin,8),"roll=%.4f covered=%s physics=%s"%[bike.visual.rotation.z,tail_hits(TAIL_POINTS.fin,8),bike.is_physics_processing()])
	bike.transformation.reset()
	await frames(5)
	var shapes: Array[CollisionShape3D] = [bike.transformation.wing_collision]
	shapes.append_array(bike.transformation.transition_shapes)
	shapes.append_array(bike.transformation.rear_collision.shapes)
	check("Reset disables every aircraft collider",shapes.size()==7 and shapes.all(func(shape): return shape.disabled) and bike.rider_collision.active and not bike.rider_collision.collision.disabled,"aircraft_shapes=%d rider_active=%s"%[shapes.size(),bike.rider_collision.active])
	await finish_report("tail_clearance","60 aircraft rear assembly collision",started,"--verify-tail_clearance")
