extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await frames(60)
	game.world.enabled = false
	var index: int = game.region.get_child_count()
	game.region._building(Vector2(0,80),Vector3(12,5,10),Color("deca9f"),"ROOF SURFACE")
	var building: Node3D = game.region.get_child(index)
	building.position = Vector3(0,200,80)
	var center := building.position
	await frames(3)
	var space := game.get_world_3d().direct_space_state
	var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3(0,15,0),center,1))
	check("The visible roof ridge blocks a downward approach",not down.is_empty() and absf(down.position.y-(center.y+7.7))<0.1,"hit=%s"%down.get("position",Vector3.ZERO))
	var side := space.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3(15,6.2,0),center+Vector3(0,6.2,0),1))
	check("The visible roof slope blocks entry above the walls",not side.is_empty() and side.position.x>1 and side.normal.y>0.2)
	var underside := space.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3(6.3,3,0),center+Vector3(6.3,8,0),1))
	check("The overhanging roof underside blocks upward entry",not underside.is_empty() and underside.normal.y< -0.9)
	player.position = center+Vector3(0,11,0)
	player.velocity = Vector3.ZERO
	await frames(75)
	check("The player lands on the roof rather than inside its visible mesh",player.is_on_floor() and player.position.y>center.y+7.3,"player=%s"%player.position)
	game.orbit.yaw = 0
	var from := player.position
	var minimum_height := player.position.y
	Input.action_press("move_forward")
	for i in range(35):
		await frames(1)
		minimum_height = minf(minimum_height,player.position.y)
	release()
	check("Actual walking remains supported along the roof ridge",from.distance_to(player.position)>1.5 and minimum_height>center.y+7.3,"travel=%.2f min_y=%.3f"%[from.distance_to(player.position),minimum_height])
	game.orbit.pitch = 0.35
	game.orbit.distance = 6.2
	game.orbit.snap()
	await frames(15)
	var sphere := SphereShape3D.new()
	sphere.radius = 0.21
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY,game.orbit.camera.global_position)
	query.collision_mask = 1
	check("Roof collision compresses the camera without entering the roof",game.orbit.arm.get_hit_length()<5.6 and space.intersect_shape(query).is_empty(),"arm=%.3f"%game.orbit.arm.get_hit_length())
	var roof: MeshInstance3D
	for child in building.get_children():
		if child is MeshInstance3D and child.mesh is PrismMesh: roof = child
	var second := MeshInstance3D.new()
	second.mesh = roof.mesh
	second.material_override = roof.material_override
	second.transform = roof.transform
	second.position.x += 25
	building.add_child(second)
	var merged := StaticBatcher.combine(building)
	await frames(3)
	down = space.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3(0,15,0),center,1))
	check("Static render batching preserves the original roof collision",merged>=2 and not down.is_empty() and absf(down.position.y-(center.y+7.7))<0.1)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.orbit.pitch = -0.35
		game.orbit.yaw = -0.5
		game.orbit.snap()
		await frames(20)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/roof-surface-m73.jpg")
	building.queue_free()
	player.recover()
	await finish_report("roof_surface","73 solid village roofs",started,"--verify-roof_surface")
