extends "res://tests/routine_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	worker = game.workers.workers[0]
	var started := Time.get_ticks_msec()
	var manager: WorkerManager = game.workers
	await until(func(): return manager.navigation.ready_for_paths,300)
	await routine_key()
	var reached := await until(func(): return worker.executor.job!=null and worker.executor.job.kind=="ShopKeep" and not worker.executor.delivered,3600)
	check("Routine reaches its final selling job",reached)
	await routine_key()
	check("Stop keeps current selling job but disables repetition",not manager.routine_active and worker.executor.job.kind=="ShopKeep")
	var stopped: Dictionary = game.saves.snapshot()
	var done := await until(idle,900)
	check("Finishing stopped final job still counts its completed cycle",done and manager.routine_cycles==1 and game.logistics.shop.credits==40,"cycles=%d credits=%d"%[manager.routine_cycles,game.logistics.shop.credits])
	var loaded: bool = await game.saves.restore(stopped)
	done = await until(idle,900)
	check("Stopped routine save finishes and counts exactly once",loaded and done and manager.routine_cycles==1 and not manager.routine_active and game.logistics.shop.credits==40 and game.logistics.market.inventory.count("olive")==5)
	await finish_report("routine_stop","20 stopped routine completion accounting",started,"--verify-routine_stop")
