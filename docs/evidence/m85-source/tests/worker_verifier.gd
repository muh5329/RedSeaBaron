extends "res://tests/cart_verifier.gd"
var worker: WorkerActor

func until(test: Callable, maximum: int = 2400) -> bool:
	var elapsed := 0
	while not test.call() and elapsed<maximum:
		await frames(6)
		elapsed += 6
	return test.call()

func idle() -> bool:
	return worker.machine.current==&"Idle"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var manager: WorkerManager = game.workers
	var logi: LogisticsWorld = game.logistics
	worker = manager.workers[0]
	await until(func(): return manager.navigation.ready_for_paths,300)
	check("Local navigation builds incrementally",manager.navigation.ready_for_paths and manager.navigation.sampled_cells==79*79)
	await press("workers")
	await press("job_farm")
	check("Player input assigns a farm job",worker.executor.job!=null and worker.executor.job.kind=="Farm" and not idle())
	check("Busy worker rejects replacement job",not worker.assign(manager.make_job("Gather")))
	var completed := await until(idle,2700)
	check("Worker autonomously harvests and returns",completed and worker.completed_jobs==1,"state=%s reason=%s pos=%s"%[worker.machine.current,worker.failure_reason,worker.position])
	check("Harvest enters warehouse and leaves no carried duplicate",logi.warehouse.inventory.count("olive")==5 and worker.inventory.count("olive")==0 and logi.sources[0].stock.count("olive")==55)
	check("Worker used explicit job states",[&"MoveToTask",&"AcquireResource",&"PerformTask",&"DeliverResource",&"Return",&"Idle"].all(func(s): return worker.history.has(s)))
	check("Harvest route was actually traversed",worker.distance_travelled>75,"meters=%.1f"%worker.distance_travelled)
	manager.order("ShopKeep")
	var balance := logi.shop.credits
	completed = await until(idle,1500)
	check("Worker stocks market and sells warehouse goods",completed and logi.market.inventory.count("olive")==5 and logi.warehouse.inventory.count("olive")==0 and logi.shop.credits==balance+20)
	if not completed:
		await finish_report("worker","07 autonomous jobs",started,"--verify-worker")
		return
	manager.order("Gather")
	completed = await until(idle,3000)
	check("Worker gathers ore through same job executor",completed and logi.warehouse.inventory.count("ore")==5 and logi.sources[1].stock.count("ore")==55,"state=%s reason=%s pos=%s"%[worker.machine.current,worker.failure_reason,worker.position])
	manager.order("Deliver")
	var courier := worker.executor.job
	balance = logi.shop.credits
	completed = await until(idle,3300)
	check("Worker completes courier contract without micromanagement",completed and courier.contract!=null and courier.contract.state=="COMPLETED" and logi.shop.credits==balance+75,"state=%s reason=%s pos=%s"%[worker.machine.current,worker.failure_reason,worker.position])
	check("Courier uses same one-shot delivery API",courier.contract!=null and not courier.contract.deliver(worker.inventory) and logi.shop.credits==balance+75)
	var source := ResourceSource.new()
	source.title = "Verifier resource"
	source.item_id = "wood"
	source.position = logi.warehouse.position+Vector3(-6,0,0)
	source.position.y = CoastalRegion.height_at(source.position.x,source.position.z)+0.1
	game.add_child(source)
	source.stock.remove("wood",60)
	var job := JobDefinition.new()
	job.title = "Recover from exhausted source"
	job.item_id = "wood"
	job.source = source
	job.destination = logi.warehouse
	worker.assign(job)
	await until(func(): return worker.machine.current==&"Blocked",600)
	check("Empty source yields visible blocked state",worker.machine.current==&"Blocked" and worker.inventory.mass()==0)
	source.stock.add("wood",5)
	completed = await until(idle,900)
	check("Worker retries replenished resource automatically",completed and logi.warehouse.inventory.count("wood")==5 and source.stock.count("wood")==0)
	# Fill destination after accepting the next job; inventory remains on worker until space exists.
	source.stock.add("wood",5)
	logi.warehouse.inventory.capacity = logi.warehouse.inventory.mass()
	worker.assign(job)
	await until(func(): return worker.machine.current==&"Blocked" and worker.executor.acquired,900)
	check("Full destination retains carried goods",worker.machine.current==&"Blocked" and worker.inventory.count("wood")==5 and source.stock.count("wood")==0)
	var from := worker.position
	game._set_paused(true)
	await frames(30)
	check("Pause freezes worker and rejects new assignments",worker.position.distance_to(from)<0.001 and not worker.assign(job))
	game._set_paused(false)
	logi.warehouse.inventory.capacity = 1000
	completed = await until(idle,900)
	check("Freed destination resumes delivery without duplication",completed and logi.warehouse.inventory.count("wood")==10 and worker.inventory.count("wood")==0)
	# Competing executors draw from exactly the same source transaction.
	source.stock.add("wood",5)
	var first := JobExecutor.new()
	var second := JobExecutor.new()
	first.job = job
	second.job = job
	var a := Inventory.new()
	var b := Inventory.new()
	check("Competing jobs cannot extract the same stock twice",first.acquire(a) and not second.acquire(b) and a.count("wood")==5 and b.count("wood")==0 and source.stock.count("wood")==0)
	a.transfer_to(source.stock,"wood",5)
	worker.assign(job)
	await until(func(): return worker.inventory.count("wood")==5,600)
	check("Recall preserves carried cargo",worker.cancel())
	completed = await until(idle,900)
	check("Recalled cargo reaches home storage",completed and worker.inventory.count("wood")==0 and logi.warehouse.inventory.count("wood")==15)
	# Removal after assignment must become a readable failure, never a freed-object crash.
	worker.assign(job)
	source.queue_free()
	await until(func(): return worker.machine.current==&"Blocked",600)
	check("Removed source is handled without state corruption",worker.machine.current==&"Blocked" and worker.inventory.mass()==0)
	worker.cancel()
	await until(idle,600)
	check("Worker returns to usable idle after failure",idle())
	var fresh := ResourceSource.new()
	fresh.item_id = "wood"
	fresh.position = logi.warehouse.position+Vector3(-8,0,5)
	fresh.position.y = CoastalRegion.height_at(fresh.position.x,fresh.position.z)+0.1
	game.add_child(fresh)
	fresh.stock.remove("wood",55)
	job.source = fresh
	var stored := logi.warehouse.inventory.count("wood")
	var blockers: Array[Node3D] = []
	for pair in [[Vector3(1.1,2,0),Vector3(0.2,4,3)],[Vector3(-1.1,2,0),Vector3(0.2,4,3)],[Vector3(0,2,1.1),Vector3(3,4,0.2)],[Vector3(0,2,-1.1),Vector3(3,4,0.2)]]:
		blockers.append(BlockoutKit.box(game,worker.position+pair[0],pair[1],Color("987e60"),true))
	await frames(3)
	worker.assign(job)
	await until(func(): return worker.machine.current==&"Blocked",500)
	check("Physical enclosure triggers navigation recovery",worker.machine.current==&"Blocked" and worker.failure_reason in ["Route obstructed","No route"])
	for blocker in blockers: blocker.queue_free()
	await frames(3)
	completed = await until(idle,1200)
	check("Removing obstacle restores autonomous route",completed and logi.warehouse.inventory.count("wood")==stored+5)
	fresh.stock.add("wood",5)
	stored = logi.warehouse.inventory.count("wood")
	var second_worker := WorkerActor.new()
	second_worker.worker_name = "Ivo"
	second_worker.navigation = manager.navigation
	second_worker.home = logi.warehouse
	second_worker.position = fresh.position+Vector3(0,0.1,2.5)
	manager.add_child(second_worker)
	manager.workers.append(second_worker)
	await frames(10)
	var previous_completed := worker.completed_jobs
	check("Two workers can receive competing jobs",worker.assign(job) and second_worker.assign(job))
	await until(func(): return worker.completed_jobs>previous_completed or second_worker.completed_jobs>0,1200)
	check("Concurrent workers conserve scarce source stock",logi.warehouse.inventory.count("wood")==stored+5 and fresh.stock.count("wood")==0 and worker.inventory.count("wood")+second_worker.inventory.count("wood")==0)
	worker.cancel()
	second_worker.cancel()
	await until(func(): return idle() and second_worker.machine.current==&"Idle",900)
	manager.workers.erase(second_worker)
	second_worker.queue_free()
	fresh.queue_free()
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		manager.panel.visible = true
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/worker-native-complete.jpg")
	await finish_report("worker","07 autonomous jobs",started,"--verify-worker")
