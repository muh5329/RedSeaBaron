extends "res://tests/logistics_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var logi: LogisticsWorld = game.logistics
	var shop := logi.shop
	var combat: PlayerCombat = game.combat
	shop.credits = 100
	combat.reserve = 0
	combat.ammunition = 0
	check("Remote ammunition purchase rejected",not logi.buy_ammunition() and shop.credits==100)
	await walk_to(logi.market)
	await press("buy_ammunition")
	check("Market input exchanges ore and earnings for rounds",combat.reserve==5 and shop.credits==88 and shop.stock.count("ore")==5)
	var observed: Array = []
	var callback := func():
		observed.append([shop.credits,combat.reserve,shop.stock.count("ore"),logi.buy_ammunition()])
	shop.stock.changed.connect(callback)
	check("Second supply purchase succeeds",logi.buy_ammunition())
	shop.stock.changed.disconnect(callback)
	check("Notifications observe committed trade and reject reentry",observed.size()==1 and observed[0]==[76,10,4,false],str(observed))
	game._set_paused(true)
	check("Paused supply request cannot spend money",not logi.buy_ammunition() and shop.credits==76)
	game._set_paused(false)
	combat.equip("RIFLE")
	check("Actual reload blocks supply purchase",combat.reload_weapon() and not logi.buy_ammunition() and shop.credits==76)
	combat.cancel()
	combat.reserve = 98
	check("Reserve cap rejects whole bundle without partial charge",not logi.buy_ammunition() and combat.reserve==98 and shop.stock.count("ore")==4)
	combat.reserve = 10
	shop.credits = 11
	check("Insufficient money retains stock and ammunition",not logi.buy_ammunition() and shop.stock.count("ore")==4 and combat.reserve==10)
	shop.credits = 76
	shop.stock.remove("ore",4)
	check("Empty market ore blocks ammunition production",not logi.buy_ammunition() and shop.credits==76)
	game.hitch.backpack.add("ore",1)
	await press("use_resource")
	check("Player-supplied ore restores ammunition supply chain",shop.stock.count("ore")==1 and shop.credits==84 and logi.buy_ammunition() and combat.reserve==15 and shop.credits==72)
	await walk_to(logi.dispatch)
	await press("use_resource")
	var container := logi.nearby_container()
	check("Courier accepts first parcel normally",logi.contract.state=="IN_TRANSIT" and container.count("package")==1)
	check("In-transit contract cannot issue another parcel",not logi.use_station(logi.dispatch,true) and container.count("package")==1)
	# Transaction fixtures reposition endpoints; the integration suite proves the driven route.
	if container!=game.hitch.backpack: container.transfer_to(game.hitch.backpack,"package",1)
	await walk_to(logi.destination)
	await press("use_resource")
	check("First delivery pays and records completion",logi.contract.deliveries_completed==1 and shop.credits==147 and logi.contract.receipt.count("package")==1)
	check("Repeated delivery cannot claim previous reward",not logi.use_station(logi.destination) and shop.credits==147)
	await walk_to(logi.dispatch)
	container = logi.nearby_container()
	var capacity := container.capacity
	container.capacity = container.mass()
	check("Full cargo preserves completed contract and receipt",not logi.use_station(logi.dispatch,true) and logi.contract.state=="COMPLETED" and logi.contract.receipt.count("package")==1)
	container.capacity = capacity
	Input.action_press("sprint")
	await press("use_resource")
	release()
	check("Courier input issues one new parcel after completion",logi.contract.state=="IN_TRANSIT" and container.count("package")==1 and logi.contract.receipt.mass()==0 and shop.credits==147)
	if container!=game.hitch.backpack: container.transfer_to(game.hitch.backpack,"package",1)
	await walk_to(logi.destination)
	await press("use_resource")
	check("Second delivery pays once without accumulating receipt cargo",logi.contract.deliveries_completed==2 and shop.credits==222 and logi.contract.receipt.count("package")==1 and not logi.use_station(logi.destination))
	var path := "user://economy-verifier-%d.json" % (0 if OS.has_feature("web") else OS.get_process_id())
	await frames(15)
	check("Extended economy saves through production API",game.saves.save_game(path))
	logi.contract.deliveries_completed = 0
	combat.reserve = 0
	shop.credits = 0
	var loaded: bool = await game.saves.load_game(path)
	check("Reload preserves rounds, earnings and delivery history",loaded and combat.reserve==15 and shop.credits==222 and logi.contract.deliveries_completed==2 and logi.contract.state=="COMPLETED")
	var legacy: Dictionary = game.saves.snapshot()
	legacy.economy.erase("deliveries_completed")
	check("Earlier version-one saves retain compatibility",SaveSchema.validate(legacy,game))
	var bad: Dictionary = game.saves.snapshot()
	bad.economy.deliveries_completed = 1.5
	check("Fractional completion history is rejected",not SaveSchema.validate(bad,game))
	# Browser filesystem sync is asynchronous; do not delete a file in its pending batch.
	if OS.has_feature("web"): await frames(360)
	DirAccess.remove_absolute(path)
	if OS.has_feature("web"): await frames(360)
	await finish_report("economy","15 repeat deliveries and ammunition supply",started,"--verify-economy")
