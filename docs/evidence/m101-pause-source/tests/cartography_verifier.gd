extends "res://tests/ui_verifier.gd"

func vista(at: Vector2, label: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args(): return
	var view := Camera3D.new()
	game.add_child(view)
	var location := Vector3(at.x,CoastalRegion.height_at(at.x,at.y),at.y)
	view.far = 1600
	view.position = location+(Vector3(680,40,650) if label=="snowcaps" else Vector3(100,30,120))
	view.look_at(location-Vector3.UP*20)
	view.current = true
	game.hud.root.visible = false
	await frames(2)
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/landform-"+label+"-m95.jpg")
	game.hud.root.visible = true
	view.queue_free()
	game.orbit.camera.current = true

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await frames(60)
	var mini: TravelMinimap = game.hud.minimap
	check("Minimap is visible and inside the gameplay viewport",mini.visible and get_viewport().get_visible_rect().encloses(mini.get_global_rect()))
	check("Minimap clears expanding field notes",mini.get_global_rect().position.y>=game.hud.field_notes_panel.get_global_rect().end.y+10)
	check("Minimap centers the traveler with a metric scale",mini.project(player.position).is_equal_approx(TravelMinimap.MID) and is_equal_approx(mini.project(player.position+Vector3(100,0,0)).x-TravelMinimap.MID.x,40))
	var count := mini.rebuilds
	await frames(30)
	check("Stationary minimap reuses its terrain texture",mini.rebuilds==count and mini.terrain!=null)
	await capture("minimap-m95")
	await key(KEY_M)
	game.hud.map_drawing.world_view = true
	game.hud.map_drawing.queue_redraw()
	await frames(20)
	check("Full map hides the minimap and pauses gameplay",game.paused and not mini.visible and game.hud.map_panel.visible)
	await capture("relief-map-m95")
	await key(KEY_M)
	check("Closing the map restores the minimap",not game.paused and mini.visible)
	var untouched := true
	for region in RegionCatalog.all(): untouched = untouched and is_zero_approx(WorldLandforms.offset(region.center))
	check("New landforms preserve established settlement elevations",untouched and is_zero_approx(WorldLandforms.offset(Vector2.ZERO)))
	var heights: Array[float] = []
	for i in range(40): heights.append(WorldLandforms.offset(WorldLandforms.DUNES+Vector2(i*8,0)))
	check("Dunes have traversable physical crest and trough relief",heights.max()-heights.min()>15)
	var valley := WorldLandforms.VALLEY
	check("Valley floor lies below its banks",CoastalRegion.height_at(valley.x+420,valley.y)-CoastalRegion.height_at(valley.x,valley.y)>25)
	check("Mountain summits cross the snow line",CoastalRegion.height_at(-1800,-8600)>195 and CoastalRegion.height_at(1100,-10300)>195)
	var peak_height := CoastalRegion.height_at(-1800,-8600)
	var continuous := true
	for direction: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		var sample := Vector2(-1800,-8600)+direction
		continuous = continuous and absf(CoastalRegion.height_at(sample.x,sample.y)-peak_height)<0.2
	check("Summit has no angular singularity or one-meter spikes",continuous)
	var dry := TerrainCartography.color_at(WorldLandforms.DUNES,8)
	var sea := TerrainCartography.color_at(Vector2(150,60),8)
	var snow := TerrainCartography.color_at(Vector2(-1800,-8600),8)
	check("Relief chart distinguishes desert, water and snow",dry.r>dry.b and sea.b>sea.r and snow.r>0.7 and snow.b>0.7)
	var supported := true
	for at: Vector2 in [WorldLandforms.DUNES,WorldLandforms.VALLEY,Vector2(-1800,-8600)]:
		player.position = Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+3,at.y)
		player.velocity = Vector3.ZERO
		await frames(120)
		supported = supported and player.is_on_floor() and game.world.streamer.collision_ready(player.position)
		await vista(at,"dunes" if at==WorldLandforms.DUNES else "valley" if at==WorldLandforms.VALLEY else "snowcaps")
	check("Real streamed landforms support the player",supported)
	check("Travel updates minimap with bounded cached terrain",mini.rebuilds>count and TerrainCartography.sheets.size()<=4 and game.world.streamer.chunks.size()<=25)
	check("Cave marker references an existing playable gallery",WorldLandforms.landmarks().any(func(row): return row[2]=="Cave" and row[1]==QuarryAdit.CENTER))
	player.recover()
	await frames(30)
	await finish_report("cartography","95 terrain relief and minimap",started,"--verify-cartography")
