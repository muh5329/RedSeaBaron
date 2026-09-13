extends "res://tests/worker_verifier.gd"

func physical_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await get_tree().process_frame
	await frames(3)

func capture_roster(name: String) -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args(): return
	await frames(20)
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/multi-worker-m55-%s.jpg"%name)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var manager: WorkerManager = game.workers
	var logi: LogisticsWorld = game.logistics
	await until(func(): return manager.navigation.ready_for_paths,300)
	check("Two independently assignable workers are registered",manager.workers.size()==2)
	if manager.workers.size()!=2:
		await finish_report("multi_worker","55 independent worker roster",started,"--verify-multi_worker")
		return
	var mara := manager.worker_by_id("mara")
	var ivo := manager.worker_by_id("ivo")
	mara.inventory.add("ore",2)
	mara.completed_jobs = 7
	var legacy: Dictionary = game.saves.snapshot()
	mara.inventory.restore_contents({})
	mara.completed_jobs = 0
	legacy.erase("worker_roster_revision")
	legacy.erase("other_workers")
	await physical_key(KEY_N)
	await physical_key(KEY_TAB)
	check("Panel Tab selects Ivo without combat lock",manager.panel.visible and manager.selected_worker()==ivo and manager.readout.text.contains("Ivo") and game.combat.target==null)
	await physical_key(KEY_N)
	await physical_key(KEY_TAB)
	check("Closed panel does not change selected worker",manager.selected_worker()==ivo)
	game.combat.target = null
	# Position only the initial fixtures near their different sources. Jobs then move normally.
	mara.position = logi.source_by_id("olive").position+Vector3(0,0.1,3)
	ivo.position = logi.source_by_id("wood").position+Vector3(0,0.1,3)
	mara.velocity = Vector3.ZERO
	ivo.velocity = Vector3.ZERO
	await frames(20)
	manager.selected_worker_index = manager.workers.find(mara)
	var assigned_mara := manager.order("Farm")
	manager.selected_worker_index = manager.workers.find(ivo)
	var assigned_ivo := manager.order("Transport")
	check("Different selected workers accept independent jobs",assigned_mara and assigned_ivo and mara.executor.job.kind=="Farm" and ivo.executor.job.kind=="Transport")
	var acquired := await until(func(): return mara.inventory.count("olive")==5 and ivo.inventory.count("wood")==5,600)
	check("Both workers acquire real separate source stock",acquired and logi.source_by_id("olive").stock.count("olive")==55 and logi.source_by_id("wood").stock.count("wood")==55)
	game._set_paused(true)
	var carrying: Dictionary = game.saves.snapshot()
	check("Snapshot preserves distinct cargo under stable identities",SaveSchema.validate(carrying,game) and carrying.worker.inventory.get("olive",0)==5 and carrying.other_workers.ivo.inventory.get("wood",0)==5)
	mara.inventory.restore_contents({})
	ivo.inventory.restore_contents({})
	manager.workers.reverse()
	var loaded: bool = await game.saves.restore(carrying)
	check("Roster reordering cannot swap cargo or jobs on restore",loaded and mara.inventory.count("olive")==5 and ivo.inventory.count("wood")==5 and ivo.executor.job.kind=="Transport")
	manager.workers.reverse()
	var before_mara := mara.position
	var before_ivo := ivo.position
	await frames(30)
	check("Pause freezes both workers and rejects orders",mara.position.distance_to(before_mara)<0.001 and ivo.position.distance_to(before_ivo)<0.001 and not manager.order("Farm"))
	for fault in ["negative","missing","unknown","future","downgrade","routine","wrong_type","container"]:
		var bad := carrying.duplicate(true)
		match fault:
			"container": bad.other_workers = null
			"wrong_type": bad.other_workers.ivo = null
			"negative": bad.other_workers.ivo.inventory = {"wood":-1}
			"missing": bad.other_workers.erase("ivo")
			"unknown": bad.other_workers.stranger = bad.other_workers.ivo.duplicate(true)
			"future": bad.worker_roster_revision = 99
			"downgrade": bad.erase("worker_roster_revision")
			"routine": bad.other_workers.ivo.routine = {"active":true,"current_job":true,"step":0,"cycles":0}
		check("Invalid secondary roster rejects atomically: "+fault,not await game.saves.restore(bad) and mara.inventory.count("olive")==5 and ivo.inventory.count("wood")==5 and logi.source_by_id("wood").stock.count("wood")==55)
	ivo.worker_id = "mara"
	check("Duplicate registered worker identities reject saving",not SaveSchema.validate(game.saves.snapshot(),game))
	ivo.worker_id = ""
	check("Missing registered worker identity rejects saving",not SaveSchema.validate(game.saves.snapshot(),game))
	ivo.worker_id = "ivo"
	game._set_paused(false)
	var done := await until(func(): return mara.machine.current==&"Idle" and ivo.machine.current==&"Idle",3000)
	check("Restored independent jobs deliver once and return",done and mara.completed_jobs==1 and ivo.completed_jobs==1 and mara.inventory.mass()==0 and ivo.inventory.mass()==0 and logi.warehouse.inventory.count("olive")==5 and logi.warehouse.inventory.count("wood")==5)
	manager.selected_worker_index = manager.workers.find(ivo)
	var credits := logi.shop.credits
	var selling := manager.order("ShopKeep")
	done = await until(func(): return ivo.machine.current==&"Idle",1200)
	check("Ivo sells Mara's harvest through shared warehouse once",selling and done and ivo.completed_jobs==2 and mara.completed_jobs==1 and logi.shop.credits==credits+20 and logi.warehouse.inventory.count("olive")==0 and logi.market.inventory.count("olive")==5)
	manager.selected_worker_index = manager.workers.find(mara)
	var start_mara := manager.toggle_routine()
	manager.selected_worker_index = manager.workers.find(ivo)
	var start_ivo := manager.toggle_routine()
	await frames(12)
	var stopped_ivo := manager.toggle_routine()
	check("Stopping Ivo's routine leaves Mara running",start_mara and start_ivo and stopped_ivo and manager.state_for(mara).active and not manager.state_for(ivo).active and manager.state_for(ivo).current_job)
	game._set_paused(true)
	var routines: Dictionary = game.saves.snapshot()
	manager.state_for(mara).active = false
	manager.state_for(ivo).active = true
	loaded = await game.saves.restore(routines)
	check("Save restores each worker's active and finishing routine flags",loaded and manager.state_for(mara).active and not manager.state_for(ivo).active and manager.state_for(ivo).current_job and manager.state_for(mara).cycles==0 and manager.state_for(ivo).cycles==0)
	game._set_paused(false)
	await physical_key(KEY_N)
	await capture_roster("ivo-finishing")
	done = await until(func(): return manager.state_for(mara).cycles>=1 and ivo.machine.current==&"Idle",4200)
	manager.selected_worker_index = manager.workers.find(mara)
	manager.toggle_routine()
	check("Real completion advances only the owning worker's routine",done and manager.state_for(mara).cycles==1 and manager.state_for(ivo).cycles==0 and ivo.completed_jobs==3,"Mara cycles=%d Ivo cycles=%d jobs=%d"%[manager.state_for(mara).cycles,manager.state_for(ivo).cycles,ivo.completed_jobs])
	await capture_roster("mara-cycle")
	# Rewind to a true pre-roster snapshot; newer Ivo is initialized, Mara retains old data.
	loaded = await game.saves.restore(legacy)
	check("Legacy save initializes only newly introduced Ivo",loaded and ivo.machine.current==&"Idle" and ivo.inventory.mass()==0 and ivo.completed_jobs==0 and ivo.position.distance_to(ivo.initial_position)<0.6 and not manager.state_for(ivo).active and mara.completed_jobs==7 and mara.inventory.count("ore")==2 and logi.source_by_id("wood").stock.count("wood")==60)
	var temporary := WorkerActor.new()
	temporary.navigation = manager.navigation
	temporary.home = logi.warehouse
	temporary.position = logi.warehouse.position+Vector3(5,0.1,4)
	manager.add_child(temporary)
	manager.workers.append(temporary)
	await frames(6)
	manager.workers.erase(temporary)
	temporary.queue_free()
	await frames(6)
	check("Retired worker discards its routine state safely",manager.routine_states.size()==manager.workers.size())
	await finish_report("multi_worker","55 independent worker roster",started,"--verify-multi_worker")
