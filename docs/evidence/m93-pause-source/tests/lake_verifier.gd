extends "res://tests/worker_verifier.gd"

func relocate(at: Vector2, settle: int = 30) -> void:
	release()
	if seat.mounted: seat.leave(true)
	player.position = Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+0.2,at.y)
	player.velocity = Vector3.ZERO
	game.orbit.yaw = PI/2
	game.orbit.snap()
	await frames(settle)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var lake := RegionalLake.water_body()
	var center := RegionalLake.CENTER
	check("Lake visual and safety share the same bounded water resource",game.world.lake_surface.water==lake and lake in game.water.additional_waters and lake.bounds.size==Vector2(180,180))
	check("Elliptical lake excludes rectangular corners",lake.depth_at(Vector3(center.x+89,13,center.y+89))==0 and lake.depth_at(Vector3(center.x,13,center.y))==1)
	var uniforms: Vector4 = game.world.backdrop.material.get_shader_parameter("lake_basin")
	check("Distant terrain receives the same authored basin parameters",uniforms==Vector4(center.x,center.y,50,110) and game.world.backdrop.material.get_shader_parameter("lake_bottom")==8)
	game.hitch.backpack.add("wood",5)
	await relocate(center+Vector2(110,0),90)
	var from := player.position
	await press("move_forward",30)
	check("Dry lake bank retains normal traversal",player.surface_speed_multiplier==1 and player.position.distance_to(from)>1.8)
	await relocate(center+Vector2(82,0))
	Input.action_press("move_forward")
	await frames(25)
	check("Inland shallows apply wading slowdown",game.water.player_depth>0.12 and game.water.player_depth<1.25 and player.surface_speed_multiplier==0.6,"depth=%.3f"%game.water.player_depth)
	release()
	var trees_dry := true
	for chunk: TerrainChunk in game.world.streamer.chunks.values():
		for node in chunk.get_children():
			if not node is MultiMeshInstance3D: continue
			for i in range(node.multimesh.instance_count):
				if lake.depth_at(node.multimesh.get_instance_transform(i).origin)>0: trees_dry = false
	check("Streamed foliage is not planted beneath the lake",trees_dry)
	var recovered: int = game.water.player_recoveries
	await relocate(center,25)
	check("The carved basin has real underwater terrain collision",player.is_on_floor() and absf(player.position.y-8)<0.15 and game.world.streamer.collision_ready(player.position),"y=%.3f"%player.position.y)
	check("Submerged inland state cannot be saved",not game.saves.can_save())
	game._set_paused(true)
	var timer: float = game.water.player_timer
	await frames(150)
	check("Pause freezes inland water recovery",game.water.player_recoveries==recovered and game.water.player_timer==timer)
	game._set_paused(false)
	await frames(150)
	check("Deep lake water recovers the player with goods intact",game.water.player_recoveries==recovered+1 and game.hitch.backpack.count("wood")==5 and player.position.distance_to(player.spawn_position)<1)
	check("Returning to land clears the wading multiplier",player.surface_speed_multiplier==1 and game.water.player_depth==0)
	await relocate(center+Vector2(110,0),90)
	await place(center+Vector2(110,0))
	check("Lake approach permits normal grounded mounting",seat.enter())
	var bike_recovered: int = game.water.bike_recoveries
	bike.position = Vector3(center.x,8.2,center.y)
	bike.velocity = Vector3.ZERO
	bike.speed = 0
	await frames(90)
	check("A waterlogged bike recovers from the inland lake",game.water.bike_recoveries==bike_recovered+1 and seat.mounted and bike.position.distance_to(bike.home)<1 and game.hitch.backpack.count("wood")==5)
	seat.leave(true)
	await relocate(center+Vector2(110,0),90)
	game.orbit.yaw = PI/2
	game.orbit.pitch = -0.22
	game.orbit.distance = 8
	game.orbit.snap()
	await frames(30)
	check("Lake remains visual-only with a bounded draw distance",game.world.lake_surface.get_child_count()==0 and game.world.lake_surface.visibility_range_end==1000 and game.world.streamer.chunks.size()<=25)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/lake-native-m53.jpg")
	await finish_report("lake","53 inland lake and water safety",started,"--verify-lake")
