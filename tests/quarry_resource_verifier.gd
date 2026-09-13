extends "res://tests/logistics_verifier.gd"

func capture_mine(name: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args(): return
	await frames(20)
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/quarry-m58-%s.jpg"%name)

func approach() -> void:
	# Relocate only to the remote approach; walking through the opening is real input.
	player.position = QuarryAdit.position_3d()+Vector3(0,4,-8)
	player.velocity = Vector3.ZERO
	game.orbit.yaw = PI
	game.orbit.pitch = -0.15
	game.orbit.snap()
	await frames(100)
	# Isolate resource/architecture behavior; encounter suite separately fights these guards.
	game.encounters.set_enabled(false)

func enter_gallery() -> void:
	Input.action_press("move_forward")
	for i in range(220):
		await frames(1)
		if player.position.z>=QuarryAdit.CENTER.y-1: break
	release()
	await frames(10)

func load_isolated(data: Dictionary) -> bool:
	var result: bool = await game.saves.restore(data)
	game.encounters.set_enabled(false)
	return result

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await frames(60)
	var logi: LogisticsWorld = game.logistics
	var source := logi.source_by_id("red_mesa_ore")
	var home := logi.source_by_id("ore")
	var forest := logi.source_by_id("greenreach_wood")
	var pack: Inventory = game.hitch.backpack
	check("Red Mesa quarry contains a registered ore reserve",source!=null and source!=home)
	if source==null:
		await finish_report("quarry_resource","58 quarry ore adit",started,"--verify-quarry_resource")
		return
	check("Remote ore cannot be gathered from the village",not logi.use_station(source))
	await approach()
	var gallery: Node = game.world.streamer.find_child("QuarryAdit",true,false)
	check("Quarry gallery streams with its local reserve",gallery!=null and source.is_visible_in_tree() and not home.is_visible_in_tree() and game.world.streamer.chunks.size()<=25)
	var facade_solid := true
	for side in [-1,1]:
		var from := QuarryAdit.position_3d()+Vector3(side*4.05,1.0,-8)
		var facade_ray := PhysicsRayQueryParameters3D.create(from,from+Vector3(0,0,8),1)
		var facade_hit := game.get_world_3d().direct_space_state.intersect_ray(facade_ray)
		facade_solid = facade_solid and not facade_hit.is_empty() and facade_hit.position.z<QuarryAdit.CENTER.y-4.8
	check("Projecting entrance rocks have matching solid collision",facade_solid)
	await capture_mine("entrance")
	var outside := player.position
	await enter_gallery()
	check("Player walks through the mine opening to reachable ore",player.is_on_floor() and player.position.distance_to(outside)>5 and logi.can_reach(source),"position=%s distance=%.2f"%[player.position,player.position.distance_to(source.position)])
	var ray := PhysicsRayQueryParameters3D.create(source.position+Vector3.UP*2.7,source.position+Vector3.UP*6,1)
	var roof := game.get_world_3d().direct_space_state.intersect_ray(ray)
	check("Mine roof has real overhead collision",not roof.is_empty() and roof.position.y>QuarryAdit.position_3d().y+4 and roof.normal.dot(Vector3.DOWN)>0.9)
	home.stock.restore_contents({"ore":11})
	forest.stock.restore_contents({"wood":17})
	for i in range(3): await press("use_resource")
	check("Gather input consumes only the quarry's independent ore",pack.count("ore")==3 and source.stock.count("ore")==77 and home.stock.count("ore")==11)
	await capture_mine("inside")
	var inside := player.position
	player.position = QuarryAdit.position_3d()+Vector3(0,0.2,5.3)
	player.velocity = Vector3.ZERO
	await frames(20)
	check("Back wall prevents gathering despite being within reach distance",player.position.distance_to(source.position)<4.5 and not logi.use_station(source) and source.stock.count("ore")==77)
	player.position = inside
	player.velocity = Vector3.ZERO
	await frames(20)
	pack.add("ore",12)
	check("Full backpack cannot consume additional quarry ore",not logi.use_station(source) and source.stock.count("ore")==77)
	pack.remove("ore",12)
	var saved: Dictionary = game.saves.snapshot()
	check("Current save records all three independent regional/core stocks",saved.stock_revision==3 and saved.stocks.source_red_mesa_ore.get("ore",0)==77 and saved.stocks.source_ore.get("ore",0)==11 and saved.stocks.source_greenreach_wood.get("wood",0)==17 and SaveSchema.validate(saved,game))
	source.stock.restore_contents({"ore":4})
	home.stock.restore_contents({"ore":5})
	forest.stock.restore_contents({"wood":2})
	var loaded := await load_isolated(saved)
	check("Restore preserves quarry depletion without overwriting other sources",loaded and source.stock.count("ore")==77 and home.stock.count("ore")==11 and forest.stock.count("wood")==17 and pack.count("ore")==3)
	var bad := saved.duplicate(true)
	bad.stocks.erase("source_red_mesa_ore")
	check("Current save missing quarry stock rejects before mutation",not await load_isolated(bad) and source.stock.count("ore")==77 and home.stock.count("ore")==11)
	bad = saved.duplicate(true)
	bad.stocks.source_red_mesa_ore = {"ore":-1}
	check("Malformed quarry stock rejects before mutation",not await load_isolated(bad) and source.stock.count("ore")==77 and forest.stock.count("wood")==17)
	var legacy := saved.duplicate(true)
	legacy.stock_revision = 2
	legacy.stocks.erase("source_red_mesa_ore")
	loaded = await load_isolated(legacy)
	check("Revision 2 initializes only the newly added quarry",loaded and source.stock.count("ore")==80 and home.stock.count("ore")==11 and forest.stock.count("wood")==17)
	legacy.erase("stock_revision")
	legacy.stocks.erase("source_greenreach_wood")
	loaded = await load_isolated(legacy)
	check("Original stock saves initialize later sources and retain core depletion",loaded and source.stock.count("ore")==80 and forest.stock.count("wood")==60 and home.stock.count("ore")==11)
	logi.use_station(source)
	var retired: WeakRef = weakref(gallery)
	player.recover()
	await frames(40)
	check("Leaving frees the gallery and hides its depleted logical source",retired.get_ref()==null and not source.is_visible_in_tree() and source.stock.count("ore")==79)
	await approach()
	await enter_gallery()
	check("Returning rebuilds the gallery without resetting ore",game.world.streamer.find_child("QuarryAdit",true,false)!=null and source.stock.count("ore")==79 and pack.count("ore")==4 and logi.can_reach(source))
	player.recover()
	await frames(40)
	await walk_to(logi.market)
	var credits := logi.shop.credits
	var market_stock := logi.shop.stock.count("ore")
	var reserve: int = game.combat.reserve
	await press("use_resource")
	check("Quarry ore sells through the existing market",pack.count("ore")==0 and logi.shop.credits==credits+32 and logi.shop.stock.count("ore")==market_stock+4)
	await press("buy_ammunition")
	check("Harvested ore supplies ammunition without duplicating value",game.combat.reserve==reserve+5 and logi.shop.credits==credits+20 and logi.shop.stock.count("ore")==market_stock+3)
	await finish_report("quarry_resource","58 quarry ore adit",started,"--verify-quarry_resource")
