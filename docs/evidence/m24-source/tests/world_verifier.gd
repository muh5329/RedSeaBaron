extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	worker = game.workers.workers[0]
	var started := Time.get_ticks_msec()
	var stream: WorldStreamer = game.world.streamer
	var saved_player := player.position
	var saved_bike := bike.position
	await place(Vector2(0,80))
	bike.rotation.y = PI
	await press("interact")
	await press("transform_vehicle")
	await frames(75)
	Input.action_press("move_forward")
	await frames(115)
	Input.action_press("jump")
	await frames(110)
	check("Flight starts in authored region",bike.flight.airborne and game.world.core_active,"mounted=%s mode=%s speed=%.2f pos=%s"%[seat.mounted,bike.transformation.mode,bike.speed,bike.position])
	if not bike.flight.airborne:
		await finish_report("world","08 bounded world streaming",started,"--verify-world")
		return
	var from := bike.position
	var collided := false
	var missing := false
	var ticks := 0
	while bike.position.z<720 and ticks<1800:
		await frames(1)
		ticks += 1
		missing = missing or not stream.collision_ready(bike.position)
		collided = collided or not bike.flight.airborne
	release()
	check("Continuous flight crosses streaming boundaries",bike.position.z>=720 and bike.position.distance_to(from)>500 and not collided,"position=%s created=%d"%[bike.position,stream.created])
	check("Terrain remains ready during flight",not missing)
	check("Authored region physics and rendering deactivate",not game.world.core_active and game.world.bodies.all(func(b): return b.collision_layer==0) and game.world.geometry.all(func(n): return not n.visible))
	check("Resident terrain stays bounded",stream.chunks.size()<=25 and stream.peak_resident<=25 and stream.retired>0,"resident=%d retired=%d"%[stream.chunks.size(),stream.retired])
	game._set_paused(true)
	await frames(2)
	game._set_paused(false)
	check("Distant enemies stay inactive across pause/resume",game.enemies.all(func(e): return not is_instance_valid(e) or not e.simulation_enabled) and not game.cart.enabled)
	# Continue a real worker job while the player is outside the resident authored region.
	var logi: LogisticsWorld = game.logistics
	var before_stock := logi.warehouse.inventory.count("wood")
	check("Distant worker order accepted",game.workers.order("Transport"))
	var done := await until(idle,4800)
	check("Distant simulation completes logistics without physics",done and worker.abstract_mode and logi.warehouse.inventory.count("wood")==before_stock+5 and worker.inventory.mass()==0,"state=%s"%worker.machine.current)
	# Stop normal input and inspect distant coordinates with a dedicated focus, then test actual body grounding.
	seat.leave(true)
	game.bike.set_physics_process(false)
	player.set_controls(false)
	var locations := [Vector2(12000,12000),Vector2(-12000,12000),Vector2(-12000,-12000),Vector2(12000,-12000)]
	var all_grounded := true
	var all_bounded := true
	for at in locations:
		player.position = Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+3,at.y)
		player.velocity = Vector3.ZERO
		stream.refresh()
		await frames(100)
		all_grounded = all_grounded and player.is_on_floor() and absf(player.position.y-CoastalRegion.height_at(player.position.x,player.position.z))<0.6
		all_bounded = all_bounded and stream.chunks.size()<=25
	check("Distant quadrant terrain supports real body collision",all_grounded)
	check("25 km coordinate domain uses bounded residency",all_bounded and stream.peak_resident<=25,"build max=%.2f ms; created=%d retired=%d"%[stream.largest_build_ms,stream.created,stream.retired])
	# Boundary recovery must return to loaded, active authored terrain.
	player.position.x = WorldStreamer.HALF_EXTENT+5
	# Worst-case timer: recovery must not wait for the next coarse visibility update.
	game.world.tier_timer = 0.25
	await frames(2)
	check("Recovery activates checkpoint collision immediately",game.world.core_active and game.world.bodies.all(func(b): return b.collision_layer==1),"position=%s"%player.position)
	await frames(75)
	check("World boundary recovery returns to authored terrain",player.position.distance_to(player.spawn_position)<1 and game.world.core_active and player.is_on_floor(),"position=%s spawn=%s floor=%s"%[player.position,player.spawn_position,player.is_on_floor()])
	check("Returning restores worker state and core collision",not worker.abstract_mode and worker.inventory.mass()==0 and logi.warehouse.inventory.count("wood")==before_stock+5 and game.world.bodies.all(func(b): return b.collision_layer==1))
	var prior_created := stream.created
	await frames(50)
	check("Stationary streamer performs no repeated builds",stream.created==prior_created and stream.pending.is_empty())
	check("Generation per chunk stays under frame-stall guard",stream.largest_build_ms<100,"max=%.2f ms (100 ms upper bound, not a 60fps claim)"%stream.largest_build_ms)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/world-native-return.jpg")
	bike.position = saved_bike
	player.position = saved_player
	player.velocity = Vector3.ZERO
	game._set_paused(false)
	game.orbit.snap()
	await finish_report("world","08 bounded world streaming",started,"--verify-world")
