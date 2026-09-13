extends "res://tests/worker_verifier.gd"

func begin_drop() -> void:
	release()
	bike.position = Vector3(0,23,110)
	bike.rotation = Vector3.ZERO
	bike.visual.transform = Transform3D.IDENTITY
	bike.velocity = Vector3.ZERO
	bike.speed = 0
	bike.flight.airborne = true
	bike.flight.pitch = 0
	bike.transformation.mode = "AIRCRAFT"
	bike.transformation.progress = 1
	bike.transformation._present()
	bike.set_physics_process(true)
	await frames(4)

func wait_for_contact() -> bool:
	var steps := 0
	while not bike.is_on_floor() and steps<300:
		await frames(1)
		steps += 1
	return bike.is_on_floor()

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
	game.world.enabled = false
	var ledge := BlockoutKit.box(game,Vector3(3.8,19.5,110),Vector3(1.6,1,40),Color("937957"),true)
	var landed := bike.flight.landings
	await begin_drop()
	var touched := await wait_for_contact()
	check("Aircraft contacts a real elevated ledge with only its wing",touched and bike.position.y>15,"body y=%.3f"%bike.position.y)
	check("Wing-only ground contact is not a completed landing",bike.flight.airborne)
	check("Wing-only contact cannot increment the landing count",bike.flight.landings==landed)
	bike.speed = 0
	check("An aircraft supported only by a wing cannot be saved",not game.saves.can_save())
	check("An aircraft supported only by a wing cannot fold",not bike.transformation.request_toggle())
	bike.set_physics_process(false)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.orbit.set_physics_process(false)
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.global_position = bike.position+Vector3(12,5,-10)
		camera.look_at(bike.position+Vector3(1,1,0))
		camera.current = true
		await frames(2)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/touchdown-native.jpg")
		camera.queue_free()
		game.orbit.camera.current = true
		game.orbit.set_physics_process(true)
	ledge.queue_free()
	await frames(3)
	var runway := BlockoutKit.box(game,Vector3(0,19.5,110),Vector3(12,1,40),Color("937957"),true)
	landed = bike.flight.landings
	await begin_drop()
	touched = await wait_for_contact()
	check("Elevated runway supports a proper undercarriage touchdown",touched and not bike.flight.airborne and bike.flight.landings==landed+1,"body y=%.3f"%bike.position.y)
	bike.speed = 0
	check("A proper elevated runway touchdown can be saved",game.saves.can_save())
	check("A proper elevated runway touchdown permits folding",bike.transformation.request_toggle())
	runway.queue_free()
	await finish_report("touchdown","44 undercarriage touchdown support",started,"--verify-touchdown")
