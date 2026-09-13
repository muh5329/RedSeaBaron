extends "res://tests/worker_verifier.gd"

func routine_key() -> void:
	if not game.workers.panel.visible: await press("workers")
	await press("job_routine")

func carrying_olives() -> bool:
	return worker.executor.job!=null and worker.executor.job.kind=="Farm" and worker.executor.acquired and not worker.executor.delivered

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	worker = game.workers.workers[0]
	var started := Time.get_ticks_msec()
	var manager: WorkerManager = game.workers
	var logi: LogisticsWorld = game.logistics
	await until(func(): return manager.navigation.ready_for_paths,300)
	await routine_key()
	check("Player input starts configured harvest-market routine",manager.routine_active and worker.executor.job!=null and worker.executor.job.kind=="Farm")
	check("Busy routine rejects unrelated job replacement",not manager.order("Deliver") and manager.routine_active)
	game._set_paused(true)
	var before := worker.position
	await frames(30)
	check("Pause freezes routine without advancing its step",manager.routine_active and manager.routine_step==0 and worker.position.distance_to(before)<0.001 and not manager.toggle_routine())
	game._set_paused(false)
	var completed := await until(func(): return manager.routine_cycles==1,4200)
	await routine_key()
	await until(idle,300)
	check("One order autonomously harvests and sells a full cycle",completed and worker.completed_jobs==2 and logi.market.inventory.count("olive")==5 and logi.warehouse.inventory.count("olive")==0 and logi.shop.credits==40)
	check("Stopping at cycle boundary prevents another harvest",not manager.routine_active and idle() and logi.sources[0].stock.count("olive")==55)
	await routine_key()
	var acquired := await until(carrying_olives,3000)
	check("Second routine reaches a real carrying stage",acquired and worker.inventory.count("olive")==5 and logi.sources[0].stock.count("olive")==50)
	var saved: Dictionary = game.saves.snapshot()
	check("Routine snapshot validates with in-flight job phase",SaveSchema.validate(saved,game))
	manager.routine_active = false
	manager.routine_step = 1
	var restored: bool = await game.saves.restore(saved)
	check("Restore preserves active routine and acquired cargo",restored and manager.routine_active and manager.routine_step==0 and worker.inventory.count("olive")==5 and logi.sources[0].stock.count("olive")==50)
	completed = await until(func(): return manager.routine_cycles==1,4200)
	await routine_key()
	await until(idle,300)
	check("Restored routine sells once without reacquiring goods",completed and logi.shop.credits==60 and logi.market.inventory.count("olive")==10 and logi.sources[0].stock.count("olive")==50)
	await routine_key()
	acquired = await until(carrying_olives,3000)
	await routine_key()
	var returned := await until(idle,2400)
	check("Stopping mid-job finishes safely and keeps harvested goods",acquired and returned and not manager.routine_active and worker.inventory.mass()==0 and logi.warehouse.inventory.count("olive")==5 and logi.shop.credits==60)
	logi.warehouse.inventory.capacity = logi.warehouse.inventory.mass()
	await routine_key()
	var blocked := await until(func(): return worker.machine.current==&"Failed",4200)
	check("Full warehouse blocks routine with cargo retained",blocked and manager.routine_active and manager.routine_step==0 and worker.inventory.count("olive")==5 and logi.sources[0].stock.count("olive")==40)
	await frames(120)
	check("Failed routine cannot spin or duplicate extraction",worker.machine.current==&"Failed" and logi.sources[0].stock.count("olive")==40 and manager.routine_cycles==0)
	logi.warehouse.inventory.capacity = 1000
	if not manager.panel.visible: await press("workers")
	await press("job_retry")
	completed = await until(func(): return manager.routine_cycles==1,1800)
	await routine_key()
	await until(idle,300)
	check("Retry completes blocked routine using retained cargo",completed and logi.shop.credits==80 and worker.inventory.mass()==0 and logi.sources[0].stock.count("olive")==40)
	check("Repeated routines conserve total harvested stock",logi.sources[0].stock.count("olive")+logi.warehouse.inventory.count("olive")+logi.market.inventory.count("olive")==60)
	var bad: Dictionary = saved.duplicate(true)
	bad.worker.routine.step = 1
	check("Inconsistent saved routine phase is rejected",not SaveSchema.validate(bad,game))
	var legacy: Dictionary = saved.duplicate(true)
	legacy.worker.erase("routine")
	check("Older worker saves without routines remain compatible",SaveSchema.validate(legacy,game))
	await finish_report("routine","20 autonomous harvest-market routines",started,"--verify-routine")
