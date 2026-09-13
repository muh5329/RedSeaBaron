extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	worker = game.workers.workers[0]
	var started := Time.get_ticks_msec()
	var saves: SaveSystem = game.saves
	var path := "user://verification-save-%d.json" % (0 if OS.has_feature("web") else OS.get_process_id())
	var logi: LogisticsWorld = game.logistics
	await until(func(): return game.workers.navigation.ready_for_paths,300)
	await frames(30)
	game.hitch.backpack.add("ore",3)
	game.cart.inventory.add("wood",4)
	logi.shop.credits = 42
	game.combat.equip("RIFLE")
	game.combat.health.current = 73
	game.combat.ammunition = 2
	game.combat.reserve = 17
	game.sites[0].discovered = true
	logi.contract.accept(game.hitch.backpack)
	game.enemies[0].health.take_damage(999,&"player")
	worker.position = logi.sources[0].position+Vector3(0,0.1,3)
	await frames(20)
	game.workers.order("Farm")
	await until(func(): return worker.inventory.count("olive")==5,300)
	check("Save fixture has worker carrying real harvested goods",worker.executor.acquired and worker.inventory.count("olive")==5 and logi.sources[0].stock.count("olive")==55)
	check("Snapshot validates before writing",SaveSchema.validate(saves.snapshot(),game))
	check("Save writes committed file",saves.save_game(path) and FileAccess.file_exists(path) and not FileAccess.file_exists(path+".tmp"))
	game.hitch.backpack.remove("ore",3)
	game.cart.inventory.remove("wood",4)
	logi.shop.credits = 999
	game.combat.ammunition = 5
	game.combat.equip("WRENCH")
	player.dodge_remaining = 0.35
	player.jump_buffer = 0.15
	var restored := await saves.load_game(path)
	check("Saved state loads through actual JSON file",restored)
	check("Player equipment and cargo restore",game.hitch.backpack.count("ore")==3 and game.cart.inventory.count("wood")==4 and game.combat.ammunition==2 and game.combat.reserve==17 and game.combat.health.current==73 and game.combat.weapon=="RIFLE" and game.combat.rifle.visible)
	check("Restoration clears stale movement actions",player.dodge_remaining==0 and player.jump_buffer==0)
	check("Economy and parcel state restore without paying",logi.shop.credits==42 and logi.contract.state=="IN_TRANSIT" and game.hitch.backpack.count("package")==1)
	check("Defeated enemy and survey remain defeated/discovered",not is_instance_valid(game.enemies[0]) and game.sites[0].discovered)
	check("Worker resumes acquired stage with cargo intact",worker.executor.acquired and not worker.executor.delivered and worker.inventory.count("olive")==5)
	# A second load must not extract another batch or emit a completion reward.
	restored = await saves.load_game(path)
	check("Repeated restore does not duplicate stock",restored and worker.inventory.count("olive")==5 and logi.sources[0].stock.count("olive")==55 and logi.shop.credits==42)
	var done := await until(idle,1800)
	check("Restored worker finishes original delivery once",done and logi.warehouse.inventory.count("olive")==5 and worker.inventory.count("olive")==0 and logi.sources[0].stock.count("olive")==55)
	var original := saves.snapshot()
	var bad := original.duplicate(true)
	bad.cart.inventory["wood"] = -1
	check("Negative inventory save rejected before mutation",not await saves.restore(bad) and game.cart.inventory.count("wood")==4 and logi.shop.credits==42)
	bad = original.duplicate(true)
	bad.erase("worker")
	check("Partial save rejected without clearing live state",not await saves.restore(bad) and logi.warehouse.inventory.count("olive")==5)
	bad = original.duplicate(true)
	bad.version = 999
	check("Unknown schema version rejected",not await saves.restore(bad))
	bad = original.duplicate(true)
	bad.player.position[0] = NAN
	check("Non-finite coordinates rejected",not await saves.restore(bad))
	bad = original.duplicate(true)
	bad.player.ammo = 1.5
	check("Fractional ammunition save rejected",not await saves.restore(bad) and game.combat.ammunition==2)
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string("{truncated")
	file.close()
	check("Truncated file rejected without mutation",not await saves.load_game(path) and game.hitch.backpack.count("ore")==3)
	await place()
	game.cart.position = bike.position+Vector3(0,0.15,3.3)
	game.cart.velocity = Vector3.ZERO
	await frames(25)
	await press("interact")
	await press("hitch_cart")
	check("Mounted cargo save is supported",seat.mounted and bike.cart_attached and saves.save_game(path))
	game.hitch.toggle()
	seat.leave()
	restored = await saves.load_game(path)
	check("Load restores exclusive seat and hitch ownership",restored and seat.mounted and not player.visible and not player.input_enabled and bike.input_enabled and bike.cart_attached and game.cart.tow_vehicle==bike and game.orbit.follow_target==bike.camera_anchor)
	bike.flight.airborne = true
	check("Airborne saving rejected without overwriting file",not saves.save_game(path))
	bike.flight.airborne = false
	game.hitch.toggle()
	seat.leave(true)
	# Courier cannot be recalled into an orphaned package after acquisition.
	worker.position = logi.dispatch.position+Vector3(0,0.1,3)
	worker.velocity = Vector3.ZERO
	await frames(20)
	game.workers.order("Deliver")
	await until(func(): return worker.executor.acquired,300)
	check("Recall cannot orphan active courier parcel",worker.executor.job.kind=="Deliver" and worker.executor.acquired and not worker.cancel() and worker.inventory.count("package")==1)
	var before_death := saves.snapshot()
	game.enemies[1].health.take_damage(999,&"player")
	await frames(5)
	restored = await saves.restore(before_death)
	check("Rewinding enemy death restores health and upright presentation",restored and game.enemies[1].health.current==140 and absf(game.enemies[1].model.rotation.z)<0.01)
	if OS.has_feature("web"):
		var credits := logi.shop.credits
		var forest := logi.source_by_id("greenreach_wood")
		var forest_stock := forest.stock.contents()
		var ivo: WorkerActor = game.workers.worker_by_id("ivo")
		var ivo_cargo: Dictionary = ivo.inventory.contents()
		ivo.inventory.restore_contents({"wood":2})
		forest.stock.restore_contents({"wood":17})
		logi.shop.credits = 314159
		check("Browser restart probe saves through production API",saves.save_game("user://web-reload-probe.json"))
		logi.shop.credits = credits
		forest.stock.restore_contents(forest_stock)
		ivo.inventory.restore_contents(ivo_cargo)
		await get_tree().create_timer(6.0).timeout
	DirAccess.remove_absolute(path)
	await finish_report("save","10 validated persistence",started,"--verify-save")
