extends "res://tests/lake_verifier.gd"

func capture_crossing(label: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args(): return
	game.orbit.set_physics_process(false)
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.position = Vector3(RegionalBrook.CENTER.x+45,42,RegionalBrook.CENTER.y+58)
	camera.look_at(Vector3(RegionalBrook.CENTER.x,6,RegionalBrook.CENTER.y))
	camera.current = true
	await frames(20)
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/brook-m62-%s.jpg"%label)
	camera.queue_free()
	game.orbit.camera.current = true
	game.orbit.set_physics_process(true)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var center := RegionalBrook.CENTER
	var brook := RegionalBrook.water_body()
	check("Brook rendering and safety share one bounded resource",game.world.brook_surface.water==brook and brook in game.water.additional_waters and brook.bounds.size==Vector2(90,496))
	var channel: Vector4 = game.world.backdrop.material.get_shader_parameter("brook_channel")
	var ends: Vector3 = game.world.backdrop.material.get_shader_parameter("brook_ends")
	check("Horizon receives the same channel and end-cap parameters",channel==Vector4(center.x,center.y,8,36) and ends==Vector3(200,48,1) and game.world.backdrop.material.get_shader_parameter("brook_meander")==RegionalBrook.MEANDER)
	var water_covered := true
	for x in range(-48,49,4):
		for z in range(-252,253,4):
			var at := center+Vector2(x,z)
			var ground := CoastalRegion.height_at(at.x,at.y)
			if ground<RegionalBrook.LEVEL and not brook.bounds.has_point(at): water_covered = false
	check("Water bounds cover all submerged curved-channel samples",water_covered)
	await relocate(center+Vector2(-58,0),90)
	var bridge: Node = game.world.streamer.find_child("BrookBridge",true,false)
	check("Approaching the brook streams its bridge with solid deck",bridge!=null and game.world.streamer.collision_ready(player.position))
	var from := player.position
	game.orbit.yaw = -PI/2
	game.orbit.snap()
	Input.action_press("move_forward")
	var walked := await until(func(): return player.position.x>center.x+54,1900)
	release()
	check("Player physically walks across both bridge approaches",walked and player.position.x-from.x>110 and absf(player.position.z-center.y)<2,"from=%s to=%s"%[from,player.position])
	check("Bridge crossing stays dry and preserves water recovery state",game.water.player_depth==0 and game.water.player_recoveries==0 and player.surface_speed_multiplier==1)
	await capture_crossing("walk")
	await relocate(center+Vector2(-56,0),90)
	await place(center+Vector2(-52,0))
	bike.rotation.y = -PI/2
	bike.position.y = maxf(CoastalRegion.height_at(bike.position.x,bike.position.z),RegionalBrook.crossing_height(bike.position.x))+0.2
	var cart: CargoCart = game.cart
	cart.position = bike.position+bike.global_basis.z*3.3
	cart.position.y = maxf(CoastalRegion.height_at(cart.position.x,cart.position.z),RegionalBrook.crossing_height(cart.position.x))+0.2
	cart.rotation = bike.rotation
	cart.velocity = Vector3.ZERO
	player.position = bike.position+Vector3(0,0.1,2)
	player.velocity = Vector3.ZERO
	await frames(40)
	cart.inventory.add("ore",20)
	var coupled: bool = seat.enter() and game.hitch.toggle()
	check("Bridge approach accepts a real mounted loaded hitch",coupled and cart.inventory.count("ore")==20)
	var max_gap := 0.0
	var minimum_y := INF
	var samples := 0
	var restored_crossing := false
	Input.action_press("move_forward")
	for i in range(1200):
		await frames(1)
		max_gap = maxf(max_gap,bike.position.distance_to(cart.position))
		if absf(bike.position.x-center.x)<20:
			minimum_y = minf(minimum_y,bike.position.y)
			samples += 1
		if not restored_crossing and bike.position.x>center.x:
			restored_crossing = true
			release()
			await press("jump",90)
			var checkpoint: Dictionary = game.saves.snapshot()
			check("Stopped loaded bridge crossing permits a valid save",game.saves.can_save() and SaveSchema.validate(checkpoint,game))
			await capture_crossing("stopped-cargo")
			await relocate(Vector2.ZERO,90)
			check("Offsite restore fixture retires the bridge first",game.world.streamer.find_child("BrookBridge",true,false)==null)
			var loaded: bool = await game.saves.restore(checkpoint)
			await frames(30)
			check("Restore rebuilds bridge support before resuming loaded vehicles",loaded and seat.mounted and bike.is_on_floor() and bike.position.y>9.9 and cart.tow_vehicle==bike and cart.inventory.count("ore")==20 and game.water.bike_recoveries==0)
			Input.action_press("move_forward")
		if bike.position.x>center.x+54: break
	release()
	await press("jump",90)
	check("Loaded motorcycle and cart physically cross the brook",coupled and bike.position.x>center.x+54 and cart.position.x>center.x+46,"bike=%s cart=%s"%[bike.position,cart.position])
	check("Loaded crossing has continuous dry support",samples>30 and minimum_y>9.9 and game.water.bike_recoveries==0 and game.water.cart_recoveries==0,"deck samples=%d minimum y=%.3f"%[samples,minimum_y])
	check("Crossing conserves cargo and drawbar constraint",cart.inventory.count("ore")==20 and cart.tow_vehicle==bike and max_gap<4.6,"max gap=%.3f"%max_gap)
	await capture_crossing("cargo")
	if cart.tow_vehicle: game.hitch.toggle()
	if seat.mounted: seat.leave(true)
	var trees_dry := true
	for chunk: TerrainChunk in game.world.streamer.chunks.values():
		for node in chunk.get_children():
			if not node is MultiMeshInstance3D: continue
			for i in range(node.multimesh.instance_count):
				var at: Vector3 = node.multimesh.get_instance_transform(i).origin
				if brook.depth_at(at)>0 or RegionalBrook.clearing(Vector2(at.x,at.z)): trees_dry = false
	check("Vegetation avoids underwater terrain and bridge approaches",trees_dry)
	game.hitch.backpack.add("wood",5)
	var recovered: int = game.water.player_recoveries
	await relocate(Vector2(RegionalBrook.channel_x(center.y+60),center.y+60),30)
	check("Brook has real submerged terrain and rejects saving",player.is_on_floor() and absf(player.position.y-1)<0.15 and not game.saves.can_save(),"y=%.3f depth=%.3f"%[player.position.y,game.water.player_depth])
	await frames(150)
	check("Deep brook recovery preserves the player's goods",game.water.player_recoveries==recovered+1 and game.hitch.backpack.count("wood")==5 and player.position.distance_to(player.spawn_position)<1)
	var retired: WeakRef = weakref(bridge)
	await frames(60)
	check("Distant bridge retires with its terrain chunk",retired.get_ref()==null and game.world.streamer.chunks.size()<=25)
	await relocate(center+Vector2(-56,0),90)
	check("Returning rebuilds one bridge and retains parked cargo",game.world.streamer.find_children("BrookBridge","",true,false).size()==1 and cart.inventory.count("ore")==20)
	await capture_crossing("return")
	await finish_report("brook","62 brook and loaded bridge crossing",started,"--verify-brook")
