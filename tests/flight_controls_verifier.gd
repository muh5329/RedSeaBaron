extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	game.world.enabled = false
	BlockoutKit.box(game,Vector3(0,29.5,300),Vector3(256,1,512),Color("a99977"),true)
	bike.position = Vector3(0,32,300)
	player.position = bike.position+Vector3(1.7,0,0)
	await frames(90)
	check("Aircraft control fixture mounts normally",seat.enter())
	Input.action_press("move_forward")
	await frames(115)
	var from := bike.position
	check("Wings can deploy above the former speed restriction",bike.speed>12 and bike.transformation.request_toggle(),"speed=%.2f"%bike.speed)
	await frames(75)
	check("Deployment completes while driving forward",bike.transformation.mode=="AIRCRAFT" and bike.position.distance_to(from)>12)
	release()
	var nose: Vector3 = bike.visual.to_local(bike.transformation.propeller.global_position)
	check("Propeller is ahead of the front wheel",nose.z<-1.5 and nose.y>1,"nose=%s"%nose)
	var hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(bike.to_global(Vector3(0.8,1.45,-3)),bike.to_global(Vector3(0.8,1.45,-1)),8))
	check("Front propeller sweep has physical collision",hit.get("collider")==bike)
	if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
		var view := Camera3D.new()
		game.add_child(view)
		view.position = bike.position+Vector3(6,3.8,-6)
		view.look_at(bike.position+Vector3.UP*1.2)
		view.current = true
		await frames(2)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/aircraft-nose-m94.jpg")
		view.queue_free()
		game.orbit.camera.current = true
	Input.action_press("move_back")
	await frames(100)
	check("Back control takes off and pulls up",bike.flight.airborne and bike.velocity.y>3 and bike.position.y>35)
	release()
	await frames(55)
	var before_speed := bike.speed
	await press("jump",100)
	check("Space boosts forward speed without commanding climb",bike.speed>before_speed+5 and absf(bike.flight.pitch)<0.02,"speed %.2f -> %.2f pitch %.3f"%[before_speed,bike.speed,bike.flight.pitch])
	from = bike.position
	await press("move_forward",45)
	check("Forward control pitches down and descends",bike.flight.pitch<0 and bike.position.y<from.y-1)
	release()
	await frames(40)
	await press("dodge",20)
	check("Ctrl or dodge no longer commands descent",absf(bike.flight.pitch)<0.02)
	var cruise := bike.speed
	await press("sprint",60)
	check("Shift airbrake reduces speed without a pitch command",bike.speed<cruise-3 and absf(bike.flight.pitch)<0.02)
	game._set_paused(true)
	from = bike.position
	var before_prop: float = bike.transformation.propeller.rotation.z
	await press("jump",20)
	check("Pause freezes boost and propeller motion",bike.position.is_equal_approx(from) and is_equal_approx(before_prop,bike.transformation.propeller.rotation.z))
	game._set_paused(false)
	seat.leave(true)
	bike.transformation.reset()
	bike.position = Vector3(0,32,300)
	bike.rotation = Vector3.ZERO
	bike.velocity = Vector3.ZERO
	player.position = bike.position+Vector3(1.7,0,0)
	await frames(80)
	seat.enter()
	Input.action_press("move_forward")
	await frames(115)
	var wall := BlockoutKit.box(game,bike.position+Vector3(3.2,2,-12),Vector3(2,4,3),Color("725646"),true)
	await frames(2)
	check("Moving deployment starts before an upcoming roadside obstacle",bike.speed>12 and bike.transformation.request_toggle())
	var penetrations := 0
	for i in range(90):
		await frames(1)
		var shapes: Array[CollisionShape3D] = [bike.transformation.wing_collision]
		shapes.append_array(bike.transformation.transition_shapes)
		for shape: CollisionShape3D in shapes:
			if shape.disabled: continue
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = shape.shape
			query.transform = shape.global_transform
			query.collision_mask = 1
			query.exclude = [bike.get_rid()]
			if not game.get_world_3d().direct_space_state.intersect_shape(query).is_empty(): penetrations += 1
	release()
	check("Driving deployment cannot grow wings through roadside cover",penetrations==0 and bike.transformation.mode!="DEPLOYING","penetrating samples=%d mode=%s"%[penetrations,bike.transformation.mode])
	wall.queue_free()
	await finish_report("flight_controls","94 revised aircraft controls",started,"--verify-flight_controls")
