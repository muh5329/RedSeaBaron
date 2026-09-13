extends "res://tests/worker_verifier.gd"
var village_checkpoint: Vector3

func settle(at: Vector3, ticks: int = 90) -> void:
	release()
	player.position = at
	player.velocity = Vector3.ZERO
	await frames(ticks)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	game.encounters.set_enabled(false)
	village_checkpoint = player.spawn_position
	game.hitch.backpack.add("wood",3)
	var board: SurveySite
	for region: RegionDefinition in RegionCatalog.all():
		var at := region.center+Vector2(-12,8)
		var previous := player.spawn_position
		await settle(Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+0.2,at.y+1.5))
		check(region.title+" arrival alone keeps the previous checkpoint",player.spawn_position.is_equal_approx(previous))
		await press("interact")
		check(region.title+" can establish a nearby recovery checkpoint",Vector2(player.spawn_position.x-at.x,player.spawn_position.z-at.y).length()<3,"checkpoint=%s"%player.spawn_position)
		var checkpoint := player.spawn_position
		var cell := WorldStreamer.coordinate(checkpoint)
		await settle(village_checkpoint,45)
		check(region.title+" checkpoint terrain retires when far away",not game.world.streamer.chunks.has(cell))
		await press("reset_player")
		await frames(30)
		check(region.title+" cold recovery restores solid ground and cargo",game.world.streamer.collision_ready(checkpoint) and player.is_on_floor() and player.position.distance_to(checkpoint)<0.35 and game.hitch.backpack.count("wood")==3,"player=%s checkpoint=%s"%[player.position,checkpoint])
		for candidate: SurveySite in game.interaction.sites:
			if candidate.site_id==region.id: board = candidate
	if board==null:
		await finish_report("regional_survey","79 regional survey checkpoints",started,"--verify-regional_survey")
		return
	var checkpoint := player.spawn_position
	var saved: Dictionary = game.saves.snapshot()
	check("Regional checkpoint uses the existing validated save record",game.saves.can_save() and SaveSchema.validate(saved,game) and saved.survey.size()==3)
	player.spawn_position = village_checkpoint
	var obstruction := Node3D.new()
	game.add_child(obstruction)
	BlockoutKit.box(obstruction,board.position+Vector3(0,1.2,0.75),Vector3(3,2.4,0.2),Color("574939"),true)
	await frames(15)
	await press("interact")
	check("Cover blocks nearby checkpoint interaction",player.spawn_position.is_equal_approx(village_checkpoint))
	obstruction.queue_free()
	await frames(15)
	game._set_paused(true)
	await press("interact")
	check("Paused survey cannot change checkpoint",player.spawn_position.is_equal_approx(village_checkpoint) and not board.interact(player))
	game._set_paused(false)
	game.encounters.set_enabled(false)
	Input.action_press("jump")
	await press("interact")
	release()
	check("Jumping rejects checkpoint assignment",player.spawn_position.is_equal_approx(village_checkpoint) and not board.interact(player))
	await frames(60)
	game.combat.health.take_damage(999,&"hostile")
	await press("interact")
	check("Dead player cannot establish checkpoint",game.combat.health.current==0 and player.spawn_position.is_equal_approx(village_checkpoint) and not board.interact(player))
	await frames(140)
	await settle(checkpoint)
	# Mount beside the board using the production seat, then use the real E dismount.
	bike.position = checkpoint+Vector3(-1.7,0,0)
	bike.velocity = Vector3.ZERO
	bike.speed = 0
	bike.rotation = Vector3.ZERO
	game.world.refresh_tiers()
	await frames(30)
	var mounted := seat.enter()
	check("Mounted survey access is rejected",mounted and not board.interact(player) and not game.interaction.enabled)
	await press("interact")
	check("Dismount key does not also set a checkpoint",not seat.mounted and player.spawn_position.is_equal_approx(village_checkpoint))
	bike.position = bike.home
	game.world.refresh_tiers()
	await settle(checkpoint+Vector3(8,0,0),30)
	await press("interact")
	check("Remote survey calls and input are rejected",not board.interact(player) and player.spawn_position.is_equal_approx(village_checkpoint))
	await settle(village_checkpoint,45)
	var restored: bool = await game.saves.restore(saved)
	game.encounters.set_enabled(false)
	await frames(30)
	check("Loading restores regional checkpoint and supported player",restored and player.spawn_position.is_equal_approx(checkpoint) and player.is_on_floor() and game.hitch.backpack.count("wood")==3)
	await settle(village_checkpoint,45)
	await press("reset_player")
	await frames(30)
	check("Loaded checkpoint survives a second cold recovery",player.position.distance_to(checkpoint)<0.35 and player.is_on_floor())
	check("Regional rest does not stamp the village survey route",game.sites.size()==3 and game.hud.visited_count==0 and not game.hud.route_complete)
	check("Repeated recoveries retain bounded chunk residency",game.world.streamer.chunks.size()<=25 and game.world.streamer.peak_resident<=25)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.orbit.yaw = 0.4
		game.orbit.pitch = -0.18
		game.orbit.snap()
		await frames(20)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/regional-survey-m79.jpg")
	await finish_report("regional_survey","79 regional survey checkpoints",started,"--verify-regional_survey")
