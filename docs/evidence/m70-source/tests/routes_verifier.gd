extends "res://tests/logistics_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var logi: LogisticsWorld = game.logistics
	check("Route selection rejects distant desk access",not logi.select_route("longfield"))
	await walk_to(logi.dispatch)
	game._set_paused(true)
	check("Pause blocks route selection",not logi.select_route("longfield"))
	game._set_paused(false)
	await press("delivery_route")
	check("Courier input selects Longfield with configured payment",logi.route_id=="longfield" and logi.contract.reward==180 and logi.contract.destination==logi.delivery_stations.longfield)
	check("Unknown route cannot alter the current offer",not logi.select_route("unknown") and logi.route_id=="longfield")
	await press("use_resource")
	var container := logi.nearby_container()
	check("Regional acceptance issues one real parcel",logi.contract.state=="IN_TRANSIT" and container.count("package")==1)
	check("Active delivery cannot change its destination or reward",not logi.select_route("south_quay") and logi.contract.reward==180)
	await walk_to(logi.destination)
	check("Local quay rejects a parcel addressed to Longfield",not logi.use_station(logi.destination) and logi.contract.state=="IN_TRANSIT" and container.count("package")==1)
	var saved: Dictionary = game.saves.snapshot()
	check("Regional route validates in a normal save",SaveSchema.validate(saved,game))
	logi.restore_route("south_quay")
	var loaded: bool = await game.saves.restore(saved)
	check("Load restores destination and payment with parcel intact",loaded and logi.route_id=="longfield" and logi.contract.reward==180 and container.count("package")==1)
	var corrupt := saved.duplicate(true)
	corrupt.economy.route = "unknown"
	check("Unknown saved route rejects before state mutation",not await game.saves.restore(corrupt) and logi.route_id=="longfield")
	# Fixture relocation isolates the endpoint transaction; airmail suite flies this route.
	if container!=game.hitch.backpack: container.transfer_to(game.hitch.backpack,"package",1)
	var endpoint: Storage = logi.contract.destination
	player.position = endpoint.position+Vector3(0,3,2)
	player.velocity = Vector3.ZERO
	await frames(90)
	check("Regional endpoint activates while home stations retire",endpoint.is_visible_in_tree() and not logi.dispatch.is_visible_in_tree() and game.world.streamer.collision_ready(player.position))
	var crowns := logi.shop.credits
	await press("use_resource")
	check("Correct endpoint consumes parcel and pays configured amount",logi.contract.state=="COMPLETED" and logi.shop.credits==crowns+180 and game.hitch.backpack.count("package")==0)
	check("Repeated delivery cannot duplicate reward",not logi.use_station(endpoint) and logi.shop.credits==crowns+180)
	player.recover()
	await frames(30)
	check("Returning home hides regional endpoint and restores courier",not endpoint.is_visible_in_tree() and logi.dispatch.is_visible_in_tree())
	await walk_to(logi.dispatch)
	check("Finished route can switch to local without losing completion history",logi.select_route("south_quay") and logi.contract.state=="AVAILABLE" and logi.contract.deliveries_completed==1 and logi.contract.receipt.mass()==0)
	var legacy: Dictionary = game.saves.snapshot()
	legacy.economy.erase("route")
	logi.restore_route("longfield")
	loaded = await game.saves.restore(legacy)
	check("Older save actually restores the original local route",loaded and logi.route_id=="south_quay" and logi.contract.destination==logi.destination and logi.contract.reward==75)
	var cycle: Array[String] = []
	for i in range(logi.routes.size()):
		await press("delivery_route")
		cycle.append(logi.route_id)
	check("Courier input cycles every catalog destination and wraps",cycle==["longfield","greenreach","south_quay"])
	check("Forest offer uses its own endpoint and payment",logi.select_route("greenreach") and logi.contract.destination==logi.delivery_stations.greenreach and logi.contract.reward==500)
	await press("use_resource")
	check("Forest acceptance issues one parcel and locks the route",logi.contract.state=="IN_TRANSIT" and not logi.select_route("longfield") and logi.nearby_container().count("package")==1)
	var forest_save: Dictionary = game.saves.snapshot()
	logi.restore_route("south_quay")
	loaded = await game.saves.restore(forest_save)
	check("Forest parcel destination survives a validated save restore",loaded and logi.route_id=="greenreach" and logi.contract.destination==logi.delivery_stations.greenreach and logi.contract.reward==500 and logi.nearby_container().count("package")==1)
	await finish_report("routes","22 selectable regional delivery routes",started,"--verify-routes")
