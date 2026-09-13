extends "res://tests/logistics_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await frames(60)
	var logi: LogisticsWorld = game.logistics
	var source: ResourceSource = logi.source_by_id("greenreach_wood")
	var home_source := logi.source_by_id("wood")
	var pack: Inventory = game.hitch.backpack
	check("Greenreach has its own registered timber reserve",source!=null and source!=home_source)
	if source==null:
		await finish_report("forest_resource","52 regional timber and legacy stock migration",started,"--verify-forest_resource")
		return
	check("Regional timber cannot be harvested from the village",not logi.use_station(source))
	# Endpoint/save fixture: forest_airmail separately proves the physical journey.
	player.position = source.position+Vector3(0,3,2.5)
	player.velocity = Vector3.ZERO
	await frames(90)
	check("Forest reserve activates with streamed ground and retires home visuals",source.is_visible_in_tree() and not home_source.is_visible_in_tree() and game.world.streamer.collision_ready(player.position))
	home_source.stock.restore_contents({"wood":17})
	var original := home_source.stock.count("wood")
	for i in range(3): await press("use_resource")
	check("Gather input removes only regional timber",pack.count("wood")==3 and source.stock.count("wood")==57 and home_source.stock.count("wood")==original)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.orbit.yaw = 0
		game.orbit.distance = 7
		game.orbit.snap()
		await frames(20)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/forest-resource-native-m52.jpg")
	pack.add("wood",27)
	check("Full pack does not consume regional stock",not logi.use_station(source) and source.stock.count("wood")==57)
	pack.remove("wood",27)
	var saved: Dictionary = game.saves.snapshot()
	check("Current stock revision records regional depletion",saved.get("stock_revision",1)==SaveSchema.STOCK_REVISION and saved.stocks.get("source_greenreach_wood",{}).get("wood",0)==57 and SaveSchema.validate(saved,game))
	source.stock.restore_contents({"wood":4})
	home_source.stock.restore_contents({"wood":5})
	var loaded: bool = await game.saves.restore(saved)
	check("Save restore preserves independent village and forest timber",loaded and source.stock.count("wood")==57 and home_source.stock.count("wood")==original and pack.count("wood")==3)
	var corrupt := saved.duplicate(true)
	corrupt.stocks.erase("source_greenreach_wood")
	check("Incomplete current-revision stock rejects before mutation",not await game.saves.restore(corrupt) and source.stock.count("wood")==57)
	corrupt = saved.duplicate(true)
	corrupt.stocks["source_greenreach_wood"] = {"wood":-1}
	check("Malformed regional stock rejects before mutation",not await game.saves.restore(corrupt) and source.stock.count("wood")==57)
	var legacy := saved.duplicate(true)
	legacy.erase("stock_revision")
	legacy.stocks.erase("source_greenreach_wood")
	loaded = await game.saves.restore(legacy)
	check("Legacy save initializes new timber without resetting original stock",loaded and source.stock.count("wood")==60 and home_source.stock.count("wood")==original and pack.count("wood")==3,"village=%d forest=%d"%[home_source.stock.count("wood"),source.stock.count("wood")])
	corrupt = saved.duplicate(true)
	corrupt.stock_revision = 99
	check("Future stock revisions reject without changing resources",not await game.saves.restore(corrupt) and source.stock.count("wood")==60)
	await press("use_resource")
	player.recover()
	await frames(30)
	check("Leaving the region hides timber while preserving depletion",not source.is_visible_in_tree() and source.stock.count("wood")==59 and home_source.is_visible_in_tree())
	player.position = source.position+Vector3(0,3,2.5)
	player.velocity = Vector3.ZERO
	await frames(90)
	check("Returning to the forest preserves harvested stock",source.is_visible_in_tree() and source.stock.count("wood")==59 and pack.count("wood")==4)
	player.recover()
	await frames(30)
	await walk_to(logi.market)
	var credits := logi.shop.credits
	await press("use_resource")
	check("Regional timber enters the existing market economy",pack.count("wood")==0 and logi.shop.credits==credits+20 and logi.shop.stock.count("wood")==4)
	await finish_report("forest_resource","52 regional timber and legacy stock migration",started,"--verify-forest_resource")
