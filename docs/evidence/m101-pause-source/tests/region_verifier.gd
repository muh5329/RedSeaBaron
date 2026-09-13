extends "res://tests/worker_verifier.gd"

func locate(region: RegionDefinition) -> TerrainChunk:
	return game.world.streamer.chunks.get(WorldStreamer.coordinate(region.position_3d()))

func approach(region: RegionDefinition) -> void:
	release()
	player.position = region.position_3d()+Vector3(0,4,48)
	player.position.y = CoastalRegion.height_at(player.position.x,player.position.z)+4
	player.velocity = Vector3.ZERO
	game.orbit.yaw = 0
	game.orbit.snap()
	await frames(100)
	await press("move_forward",250)
	await frames(35)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var catalog := RegionCatalog.all()
	var events: Array[String] = []
	game.regions.discovered_region.connect(func(region: RegionDefinition): events.append(region.id))
	var first_chunk: WeakRef
	var first_tree := Transform3D.IDENTITY
	var bounded := true
	for region in catalog:
		await approach(region)
		var chunk := locate(region)
		check("%s landmark streams with its terrain"%region.title,chunk!=null and chunk.get_node_or_null("Landmark_"+region.id)!=null and player.is_on_floor())
		check("Walking approach discovers "+region.title,game.regions.discovered.get(region.id,false) and player.position.distance_to(region.position_3d())<35,"position=%s"%player.position)
		var scene_count := 0
		for resident: TerrainChunk in game.world.streamer.chunks.values():
			for node in resident.get_children():
				if node is MultiMeshInstance3D: scene_count += node.multimesh.instance_count
		bounded = bounded and scene_count<=1400 and game.world.streamer.chunks.size()<=25
		if region.id=="greenreach":
			first_chunk = weakref(chunk)
			var trees: MultiMeshInstance3D = chunk.get_node("Scenery_tree")
			first_tree = trees.multimesh.get_instance_transform(0)
			if DisplayServer.get_name()!="headless":
				var calls: Array[float] = []
				var rates: Array[float] = []
				for sample in range(30):
					await frames(2)
					calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
					rates.append(Engine.get_frames_per_second())
				calls.sort()
				rates.sort()
				check("Populated forest stays within its render budget",calls[15]>0 and calls[15]<500 and rates[15]>=50,"calls=%.0f fps=%.0f"%[calls[15],rates[15]])
		if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
			await frames(2)
			RenderingServer.force_draw()
			get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/region-native-%s.jpg"%region.id)
	check("Regional decoration remains bounded with terrain",bounded,"resident=%d"%game.world.streamer.chunks.size())
	check("Retired region releases its scenery node",first_chunk.get_ref()==null)
	check("Discovery emits one event per visited landmark",events.size()==4 and game.regions.discovered.size()==4)
	var saved: Dictionary = game.saves.snapshot()
	game.regions.discovered.clear()
	var restored: bool = await game.saves.restore(saved)
	check("Saved journey restores regional discoveries",restored and game.regions.discovered.size()==4)
	var legacy: Dictionary = saved.duplicate(true)
	legacy.erase("regions")
	check("Earlier saves without regions still validate",SaveSchema.validate(legacy,game))
	var bad: Dictionary = saved.duplicate(true)
	bad.regions["unknown_region"] = true
	check("Unknown regional save keys reject before mutation",not await game.saves.restore(bad) and game.regions.discovered.size()==4)
	await approach(catalog[0])
	var regenerated := locate(catalog[0])
	var trees: MultiMeshInstance3D = regenerated.get_node("Scenery_tree")
	check("Retired region regenerates deterministic foliage",trees.multimesh.get_instance_transform(0).is_equal_approx(first_tree))
	check("Revisit preserves discovery without duplicate events",events.size()==4)
	game._set_paused(true)
	game.regions.discovered.erase("greenreach")
	await frames(40)
	check("Paused exploration cannot discover landmarks",not game.regions.discovered.has("greenreach"))
	game.regions.discovered["greenreach"] = true
	game._set_paused(false)
	check("Decorated chunk builds remain under stall guard",game.world.streamer.largest_build_ms<100,"max %.2f ms"%game.world.streamer.largest_build_ms)
	player.recover()
	await frames(30)
	await finish_report("region","17 streamed regional scenery and discovery",started,"--verify-region")
