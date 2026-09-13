extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await frames(60)
	var original: ResourceSource = game.logistics.sources[2]
	var second := ResourceSource.new()
	second.item_id = "wood"
	second.source_id = "other_wood"
	second.position = original.position+Vector3(8,0,0)
	game.logistics.add_child(second)
	game.logistics.sources.append(second)
	original.stock.restore_contents({"wood":17})
	second.stock.restore_contents({"wood":9})
	check("Two timber sources begin with distinct live stock",original.stock.count("wood")==17 and second.stock.count("wood")==9)
	var saved: Dictionary = game.saves.snapshot()
	check("Save retains the original source stock",saved.stocks.get("source_wood",{}).get("wood",0)==17)
	check("Save retains the second source under its own identity",saved.stocks.get("source_other_wood",{}).get("wood",0)==9)
	original.stock.restore_contents({"wood":5})
	second.stock.restore_contents({"wood":2})
	var loaded: bool = await game.saves.restore(saved)
	check("Restore does not duplicate or overwrite source quantities",loaded and original.stock.count("wood")==17 and second.stock.count("wood")==9,"original=%d second=%d"%[original.stock.count("wood"),second.stock.count("wood")])
	game.logistics.sources.reverse()
	check("Worker transport still resolves the intended timber source after reordering",game.workers.make_job("Transport").source==original)
	loaded = await game.saves.restore(saved)
	check("Resource registration order does not change restored stock",loaded and original.stock.count("wood")==17 and second.stock.count("wood")==9)
	game.logistics.sources.reverse()
	second.source_id = original.source_id
	check("Duplicate registered source identities reject saving",not SaveSchema.validate(game.saves.snapshot(),game))
	second.source_id = ""
	check("Missing registered source identity rejects saving",not SaveSchema.validate(game.saves.snapshot(),game))
	second.source_id = "other_wood"
	var corrupt := saved.duplicate(true)
	corrupt.stocks["source_other_wood"] = {"wood":-1}
	var before_original := original.stock.contents()
	var before_second := second.stock.contents()
	check("Invalid secondary stock rejects before either source mutates",not await game.saves.restore(corrupt) and original.stock.contents()==before_original and second.stock.contents()==before_second)
	game.logistics.sources.erase(second)
	second.queue_free()
	await finish_report("source_identity","51 stable resource source persistence",started,"--verify-source_identity")
