extends "res://tests/cart_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var path := "user://web-reload-probe.json"
	await frames(90)
	check("Browser reports persistent user filesystem",OS.is_userfs_persistent())
	check("Save file survives a fresh page launch",FileAccess.file_exists(path))
	var restored: bool = await game.saves.load_game(path)
	check("Cross-page save restores actual game state",restored and game.logistics.shop.credits==314159 and game.cart.inventory.count("wood")==4 and game.hitch.backpack.count("ore")==3)
	check("Cross-page worker cargo restores without duplicate parcel",restored and game.workers.workers[0].executor.acquired and game.workers.workers[0].inventory.count("package")==1)
	check("Cross-page load preserves depleted regional timber stock",restored and game.logistics.source_by_id("greenreach_wood").stock.count("wood")==17)
	check("Cross-page load preserves the second worker independently",restored and game.workers.worker_by_id("ivo").inventory.count("wood")==2 and game.workers.worker_by_id("mara").inventory.count("package")==1)
	check("Cross-page load preserves depleted quarry ore",restored and game.logistics.source_by_id("red_mesa_ore").stock.count("ore")==23)
	DirAccess.remove_absolute(path)
	await finish_report("resume","10 browser restart persistence",started,"--verify-resume")
