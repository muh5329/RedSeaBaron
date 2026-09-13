class_name SaveSystem
extends Node
signal message(text: String)
const PATH: String = "user://red_sea_baron_v1.json"
var game: Node3D
var busy: bool = false
var last_error: String = ""

func snapshot() -> Dictionary:
	var worker: WorkerActor = game.workers.workers[0]
	var job: JobDefinition = worker.executor.job
	var stocks := {}
	for station: Storage in game.logistics.stations: stocks[station.station_id] = station.inventory.contents()
	for source: ResourceSource in game.logistics.sources: stocks["source_"+source.item_id] = source.stock.contents()
	var worker_data := {"position":SaveSchema.vector(worker.position),"inventory":worker.inventory.contents(),"state":str(worker.machine.current),"elapsed":worker.machine.elapsed,"completed":worker.completed_jobs,"kind":job.kind if job else "","acquired":worker.executor.acquired,"delivered":worker.executor.delivered,"goal":SaveSchema.vector(worker.goal),"resume":str(worker.resume_state),"retries":worker.retries}
	if job and job.contract:
		worker_data["contract"] = job.contract.state
		worker_data["receipt"] = job.contract.receipt.contents()
	var enemies: Array = []
	for enemy: EnemyActor in game.enemies:
		if not is_instance_valid(enemy):
			enemies.append({"kind":"Raider","position":[0,2,0],"home":[0,2,0],"health":0})
		else:
			enemies.append({"kind":enemy.kind,"position":SaveSchema.vector(enemy.position),"home":SaveSchema.vector(enemy.home),"health":enemy.health.current})
	return {"regions":game.regions.discovered.duplicate(),"camera":[game.orbit.yaw,game.orbit.pitch,game.orbit.distance],"enemies":enemies,"version":SaveSchema.VERSION,"player":{"position":SaveSchema.vector(game.player.position),"checkpoint":SaveSchema.vector(game.player.spawn_position),"facing":game.player.visual.rotation.y,"health":game.combat.health.current,"stamina":game.player.stamina,"weapon":game.combat.weapon,"ammo":game.combat.ammunition,"reserve":game.combat.reserve,"inventory":game.hitch.backpack.contents()},"bike":{"position":SaveSchema.vector(game.bike.position),"yaw":game.bike.rotation.y,"mode":game.bike.transformation.mode,"mounted":game.seat.mounted},"cart":{"position":SaveSchema.vector(game.cart.position),"yaw":game.cart.rotation.y,"attached":game.bike.cart_attached,"inventory":game.cart.inventory.contents()},"economy":{"credits":game.logistics.shop.credits,"deliveries_completed":game.logistics.contract.deliveries_completed,"sold":game.logistics.shop.sold_units,"contract":game.logistics.contract.state,"receipt":game.logistics.contract.receipt.contents()},"worker":worker_data,"stocks":stocks,"survey":game.sites.map(func(site): return site.discovered)}

func can_save() -> bool:
	return not busy and game.combat.health.current>0 and game.combat.state=="READY" and game.player.dodge_remaining<=0 and not game.bike.flight.airborne and game.bike.transformation.mode in ["BIKE","AIRCRAFT"] and absf(game.bike.speed)<1 and (game.bike.is_on_floor() if game.seat.mounted else game.player.is_on_floor())

func save_game(path: String = PATH) -> bool:
	if not can_save():
		message.emit("Stop on solid ground, finish combat and wing movement, then save.")
		return false
	var data := snapshot()
	if not SaveSchema.validate(data,game):
		last_error = "Current state is not supported by save version 1."
		message.emit(last_error)
		return false
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:
		last_error = "Cannot write save file."
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var error := DirAccess.rename_absolute(path+".tmp",path)
	if error!=OK:
		last_error = "Cannot commit save file."
		return false
	message.emit("Journey saved, including worker cargo and job progress.")
	return true

func load_game(path: String = PATH) -> bool:
	if busy or not FileAccess.file_exists(path): return false
	var file := FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>1024*1024: return false
	var parser := JSON.new()
	var result := parser.parse(file.get_as_text())
	file.close()
	if result!=OK:
		last_error = "Save rejected: malformed JSON."
		message.emit(last_error)
		return false
	return await restore(parser.data)

func restore(data: Variant) -> bool:
	if busy or not SaveSchema.validate(data,game):
		last_error = "Save rejected: invalid, unsupported or incomplete state."
		message.emit(last_error)
		return false
	busy = true
	var was_paused: bool = game.paused
	game._set_paused(true)
	game.combat.cancel()
	game.combat.target = null
	game.bike.flight.reset()
	game.bike.transformation.reset()
	game.bike.position = SaveSchema.decode(data.bike.position)
	game.bike.rotation = Vector3(0,data.bike.yaw,0)
	game.bike.velocity = Vector3.ZERO
	game.bike.speed = 0
	game.bike.transformation.mode = data.bike.mode
	game.bike.transformation.progress = 1 if data.bike.mode=="AIRCRAFT" else 0
	game.bike.transformation._present()
	game.cart.position = SaveSchema.decode(data.cart.position)
	game.cart.rotation = Vector3(0,data.cart.yaw,0)
	game.cart.velocity = Vector3.ZERO
	game.cart.tow_vehicle = game.bike if data.cart.attached else null
	game.bike.cart_attached = data.cart.attached
	game.bike.tow_cart = game.cart if data.cart.attached else null
	game.cart.inventory.restore_contents(data.cart.inventory)
	game.bike.cargo_mass = 20+game.cart.inventory.mass() if data.cart.attached else 0
	game.player.position = SaveSchema.decode(data.player.position)
	game.player.spawn_position = SaveSchema.decode(data.player.checkpoint)
	game.player.velocity = Vector3.ZERO
	game.player.dodge_remaining = 0
	game.player.jump_buffer = 0
	game.player.coyote = 0
	game.player.regen_delay = 0
	game.player.sprint_exhausted = false
	game.player.visual.rotation = Vector3(0,data.player.facing,0)
	game.orbit.yaw = data.camera[0]
	game.orbit.pitch = data.camera[1]
	game.orbit.distance = data.camera[2]
	game.player.stamina = data.player.stamina
	game.combat.health.current = data.player.health
	game.combat.restore_equipment(data.player.weapon,int(data.player.ammo),int(data.player.reserve))
	game.hitch.backpack.restore_contents(data.player.inventory)
	game.seat.restore_ownership(data.bike.mounted)
	game.orbit.distance = data.camera[2]
	for station: Storage in game.logistics.stations: station.inventory.restore_contents(data.stocks[station.station_id])
	for source: ResourceSource in game.logistics.sources: source.stock.restore_contents(data.stocks["source_"+source.item_id])
	game.regions.discovered = data.get("regions",{}).duplicate()
	game.logistics.shop.credits = int(data.economy.credits)
	game.logistics.shop.sold_units = int(data.economy.sold)
	game.logistics.contract.deliveries_completed = int(data.economy.get("deliveries_completed",1 if data.economy.contract=="COMPLETED" else 0))
	game.logistics.contract.state = data.economy.contract
	game.logistics.contract.receipt.restore_contents(data.economy.receipt)
	for i in range(game.sites.size()): game.sites[i].discovered = data.survey[i]
	for i in range(game.sites.size()):
		game.sites[i].marker.material_override = BlockoutKit.material(Color("80b5a0") if data.survey[i] else Color("e9bd71"))
	game.hud.update_route()
	for i in range(data.enemies.size()):
		var saved: Dictionary = data.enemies[i]
		var enemy: EnemyActor = game.enemies[i]
		if saved.health<=0:
			if is_instance_valid(enemy): enemy.queue_free()
			game.enemies[i] = null
			continue
		if not is_instance_valid(enemy):
			enemy = EnemyActor.new()
			enemy.kind = saved.kind
			enemy.target = game.player
			game.add_child(enemy)
			game.enemies[i] = enemy
		enemy.position = SaveSchema.decode(saved.position)
		enemy.home = SaveSchema.decode(saved.home)
		enemy.health.current = saved.health
		enemy.velocity = Vector3.ZERO
		enemy.desired_velocity = Vector3.ZERO
		enemy.death_time = 0
		enemy.model.rotation.z = 0
		enemy.collision_layer = 4
		enemy.brain.machine.change(&"Idle")
		enemy.brain.navigation = game.workers.navigation
		enemy.set_simulation(false)
	var worker: WorkerActor = game.workers.workers[0]
	var w: Dictionary = data.worker
	worker.position = SaveSchema.decode(w.position)
	worker.velocity = Vector3.ZERO
	worker.desired = Vector3.ZERO
	worker.inventory.restore_contents(w.inventory)
	worker.completed_jobs = int(w.completed)
	worker.retries = int(w.retries)
	worker.resume_state = StringName(w.resume)
	worker.executor = JobExecutor.new()
	if w.kind!="": worker.executor.job = game.workers.make_job(w.kind)
	worker.executor.acquired = w.acquired
	worker.executor.delivered = w.delivered
	if worker.executor.job and worker.executor.job.contract:
		worker.executor.job.contract.state = w.contract
		worker.executor.job.contract.receipt.restore_contents(w.receipt)
	worker.goal = SaveSchema.decode(w.goal)
	worker.machine.change(StringName(w.state))
	worker.machine.elapsed = w.elapsed
	worker.failure_reason = "Restored job; retry if its route remains blocked."
	worker.stuck_time = 0
	worker.last_position = worker.position
	while not game.workers.navigation.ready_for_paths: await get_tree().physics_frame
	worker.path = game.workers.navigation.route(worker.position,worker.goal)
	worker.path_index = 0
	game.world.streamer.refresh()
	while not game.world.streamer.pending.is_empty():
		game.world.streamer._build(game.world.streamer.pending.pop_front())
		await get_tree().physics_frame
	game.world.enabled = true
	game.world.tier_timer = 0
	game.world._process(0)
	await get_tree().physics_frame
	game._set_paused(was_paused)
	if not was_paused and not game.verification_running: game._capture_mouse()
	game.orbit.snap()
	busy = false
	message.emit("Journey restored. Worker cargo and progress preserved.")
	return true

func _input(event: InputEvent) -> void:
	if event.is_echo() or not game.started or game.verification_running or busy: return
	if event.is_action_pressed("save_game"): save_game()
	if event.is_action_pressed("load_game"): await load_game()
