extends "res://tests/worker_verifier.gd"

func collision_count(node: Node) -> int:
	var count := 1 if node is CollisionObject3D else 0
	for child in node.get_children(): count += collision_count(child)
	return count

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var backdrop: WorldBackdrop = game.world.backdrop
	var mesh_id := backdrop.geometry.mesh.get_instance_id()
	var material_id := backdrop.material.get_instance_id()
	check("Horizon uses one bounded reusable mesh",backdrop.get_child_count()==1 and backdrop.geometry.mesh.get_surface_count()==1 and backdrop.geometry.mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX].size()<20000)
	check("Horizon cannot replace gameplay collision",collision_count(backdrop)==0)
	var reused := true
	var covered := true
	var grounded := true
	var bounded := true
	for at in [Vector2(0,12),Vector2(300,300),Vector2(4800,1255),Vector2(-1000,-10000),Vector2(-12000,12000)]:
		player.position = Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+3,at.y)
		player.velocity = Vector3.ZERO
		game.orbit.snap()
		await frames(90)
		reused = reused and backdrop.geometry.mesh.get_instance_id()==mesh_id and backdrop.material.get_instance_id()==material_id
		var offset := Vector2(player.position.x,player.position.z)-backdrop.anchor
		covered = covered and WorldBackdrop.WIDTH/2-maxf(absf(offset.x),absf(offset.y))>game.orbit.camera.far
		grounded = grounded and player.is_on_floor() and game.world.streamer.collision_ready(player.position)
		bounded = bounded and game.world.streamer.chunks.size()<=25
	check("Distant relocation reuses mesh and material resources",reused)
	check("Horizon covers camera range in every tested region",covered)
	check("Real streamed terrain still supports player collision",grounded)
	check("Horizon does not expand terrain residency",bounded)
	var moves := backdrop.relocations
	await frames(60)
	check("Stationary horizon does not recreate or relocate resources",backdrop.relocations==moves and backdrop.geometry.mesh.get_instance_id()==mesh_id)
	if DisplayServer.get_name()!="headless":
		var calls: Array[float] = []
		for i in range(30):
			await frames(2)
			calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		calls.sort()
		check("Decorated horizon stays within rendering budget",calls[15]>0 and calls[15]<500 and Engine.get_frames_per_second()>=50,"calls=%.0f fps=%d"%[calls[15],Engine.get_frames_per_second()])
	player.recover()
	await frames(30)
	await finish_report("backdrop","21 bounded distant terrain horizon",started,"--verify-backdrop")
