extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	game.encounters.set_enabled(false)
	for region: RegionDefinition in RegionCatalog.all():
		var center := region.position_3d()
		var roof_height := 10.6 if region.biome=="Highlands" else 5.6
		player.position = center+Vector3(0,roof_height+4,0)
		player.velocity = Vector3.ZERO
		await frames(100)
		var hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3(0,20,0),center+Vector3(0,0.4,0),1))
		check(region.title+" roof has a physical top surface",not hit.is_empty() and absf(hit.position.y-center.y-roof_height)<0.1,"hit=%s expected_y=%.3f"%[hit.get("position",Vector3.ZERO),center.y+roof_height])
		check(region.title+" supports a player on its visible roof",player.is_on_floor() and absf(player.position.y-center.y-roof_height)<0.15,"player_y=%.3f"%player.position.y)
	var saved: Dictionary = game.saves.snapshot()
	var saved_position := player.position
	var owner_cell := WorldStreamer.coordinate(saved_position)
	var old_chunk: int = game.world.streamer.chunks[owner_cell].get_instance_id()
	check("A supported rooftop session is valid for saving",game.saves.can_save() and SaveSchema.validate(saved,game))
	player.recover()
	await frames(90)
	check("Leaving the region retires its roof owner chunk",not game.world.streamer.chunks.has(owner_cell))
	var restored: bool = await game.saves.restore(saved)
	check("Restoration rebuilds the roof owner before controls resume",restored and game.world.streamer.collision_ready(player.position) and game.world.streamer.chunks[owner_cell].get_instance_id()!=old_chunk)
	await frames(30)
	check("Restored player stays on the rebuilt roof",player.is_on_floor() and absf(player.position.y-saved_position.y)<0.15)
	check("Roof collision remains inside the bounded terrain window",game.world.streamer.chunks.size()<=25 and game.world.streamer.peak_resident<=25)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.orbit.yaw = -0.5
		game.orbit.pitch = -0.35
		game.orbit.distance = 6.2
		game.orbit.snap()
		await frames(20)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/regional-roof-m75-restored.jpg")
	player.recover()
	await finish_report("regional_roof","75 solid streamed landmark roofs",started,"--verify-regional_roof")
