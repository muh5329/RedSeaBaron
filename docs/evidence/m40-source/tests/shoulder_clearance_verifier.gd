extends "res://tests/worker_verifier.gd"

func camera_clear() -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.21
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY,game.orbit.camera.global_position)
	query.collision_mask = 1
	return game.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	game.world.enabled = false
	player.position = Vector3(-20,CoastalRegion.height_at(-20,80)+0.1,80)
	player.velocity = Vector3.ZERO
	game.combat.equip("RIFLE")
	game.orbit.yaw = 0
	game.orbit.pitch = 0
	game.orbit.distance = 6.2
	await frames(60)
	var origin: Vector3 = player.global_position+Vector3.UP*1.65
	var wall := BlockoutKit.box(game,origin+Vector3(0.60,0,1),Vector3(0.30,4,18),Color("877258"),true)
	await frames(3)
	check("New side cover is resolved without a smoothing delay",camera_clear())
	await frames(57)
	check("Shoulder camera stays outside an adjacent right wall",camera_clear(),"camera relative=%s"%(game.orbit.camera.global_position-origin))
	check("Shoulder pivot stays on the player's side of cover",game.orbit.global_position.x-origin.x<0.24,"pivot offset=%.3f"%(game.orbit.global_position.x-origin.x))
	wall.queue_free()
	await frames(60)
	check("Open space restores the rifle shoulder view",camera_clear() and game.orbit.global_position.x-origin.x>0.65)
	wall = BlockoutKit.box(game,origin+Vector3(0,0,2),Vector3(6,4,0.3),Color("877258"),true)
	await frames(60)
	check("Rear wall compresses the camera arm",camera_clear() and game.orbit.arm.get_hit_length()<2)
	wall.queue_free()
	await frames(60)
	check("Removing rear cover restores orbit distance",camera_clear() and game.orbit.arm.get_hit_length()>6)
	# Snap is used for recovery/load and must respect lateral cover immediately.
	wall = BlockoutKit.box(game,origin+Vector3(0.60,0,1),Vector3(0.30,4,18),Color("877258"),true)
	await frames(3)
	game.orbit.snap()
	await frames(3)
	check("Camera snap cannot place the pivot inside side cover",game.orbit.global_position.x-origin.x<0.24 and camera_clear())
	wall.queue_free()
	await frames(3)
	game.orbit.yaw = 1.2
	game.orbit.pitch = -0.27
	var right := Vector3.RIGHT.rotated(Vector3.UP,game.orbit.yaw)
	wall = BlockoutKit.box(game,origin+right*0.6,Vector3(0.30,4,18),Color("877258"),true)
	wall.rotation.y = game.orbit.yaw
	await frames(3)
	check("Rotated side cover constrains the shoulder in camera space",camera_clear() and (game.orbit.global_position-origin).dot(right)<0.24)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/shoulder-clearance-native.jpg")
	wall.queue_free()
	await finish_report("shoulder_clearance","38 shoulder camera world clearance",started,"--verify-shoulder_clearance")
