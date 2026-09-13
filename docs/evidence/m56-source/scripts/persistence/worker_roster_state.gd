class_name WorkerRosterState
extends RefCounted
const REVISION: int = 2

static func snapshot(worker: WorkerActor, manager: WorkerManager) -> Dictionary:
	if worker==null: return {}
	var job: JobDefinition = worker.executor.job
	var worker_data := {"routine":manager.routine_snapshot(worker),"position":SaveSchema.vector(worker.position),"inventory":worker.inventory.contents(),"state":str(worker.machine.current),"elapsed":worker.machine.elapsed,"completed":worker.completed_jobs,"kind":job.kind if job else "","acquired":worker.executor.acquired,"delivered":worker.executor.delivered,"goal":SaveSchema.vector(worker.goal),"resume":str(worker.resume_state),"retries":worker.retries}
	if job and job.contract:
		worker_data["contract"] = job.contract.state
		worker_data["receipt"] = job.contract.receipt.contents()
	return worker_data

static func initial(worker: WorkerActor, manager: WorkerManager) -> Dictionary:
	return {"routine":WorkerRoutineState.new().snapshot(manager.routine.id),"position":SaveSchema.vector(worker.initial_position),"inventory":{},"state":"Idle","elapsed":0,"completed":0,"kind":"","acquired":false,"delivered":false,"goal":SaveSchema.vector(worker.initial_position),"resume":"MoveToTask","retries":0}

static func other_snapshots(manager: WorkerManager) -> Dictionary:
	var result := {}
	for worker in manager.workers:
		if worker.worker_id!="mara": result[worker.worker_id] = snapshot(worker,manager)
	return result

static func record(data: Dictionary, worker: WorkerActor) -> Variant:
	if worker.worker_id=="mara": return data.worker
	if data.get("worker_roster_revision",1)<REVISION:
		return initial(worker,worker.get_parent())
	return data.other_workers[worker.worker_id]

static func validate(data: Dictionary, manager: WorkerManager) -> bool:
	var revision: Variant = data.get("worker_roster_revision",1)
	if not SaveSchema.whole(revision,1,REVISION): return false
	if revision==1 and data.has("other_workers"): return false
	if revision==REVISION and not data.get("other_workers") is Dictionary: return false
	var ids := {}
	for worker in manager.workers:
		if worker.worker_id.strip_edges().is_empty() or ids.has(worker.worker_id): return false
		ids[worker.worker_id] = true
		if worker.worker_id!="mara" and revision==REVISION and not data.other_workers.has(worker.worker_id): return false
		if not valid_worker(record(data,worker)): return false
	if not ids.has("mara"): return false
	if revision==REVISION:
		if data.other_workers.size()!=ids.size()-1: return false
		for id in data.other_workers:
			if id=="mara" or not ids.has(id): return false
	return true

static func valid_worker(value: Variant) -> bool:
	if not value is Dictionary: return false
	var w: Dictionary = value
	var routine: Variant = w.get("routine",{})
	if not routine is Dictionary or routine.get("id","harvest_market")!="harvest_market" or not routine.get("active",false) is bool or not SaveSchema.whole(routine.get("step",0),0,1) or not SaveSchema.whole(routine.get("cycles",0),0,1000000): return false
	if not SaveSchema.valid_vector(w.get("position")) or not Inventory.valid_contents(w.get("inventory"),60) or w.get("state") not in SaveSchema.STATES or not SaveSchema.whole(w.get("completed"),0,1000000): return false
	if not SaveSchema.number(w.get("elapsed"),0,1000000) or not SaveSchema.whole(w.get("retries"),0,100000) or not SaveSchema.valid_vector(w.get("goal")) or w.get("resume") not in SaveSchema.STATES: return false
	if w.get("kind")!="" and w.get("kind") not in SaveSchema.KINDS: return false
	if w.state!="Idle" and w.kind=="": return false
	if not w.get("acquired") is bool or not w.get("delivered") is bool: return false
	if w.delivered and not w.acquired: return false
	if not routine.get("current_job",false) is bool: return false
	if routine.get("current_job",false) and (w.delivered or w.state=="Idle"): return false
	if (routine.get("active",false) or routine.get("current_job",false)) and w.state!="Idle":
		var step: int = int(routine.get("step",0))
		if w.delivered: step = (step+1)%2
		if w.kind!=["Farm","ShopKeep"][step]: return false
	if w.kind=="Deliver" and (w.get("contract") not in ["AVAILABLE","IN_TRANSIT","COMPLETED"] or not Inventory.valid_contents(w.get("receipt"),60)): return false
	return true

static func restore(worker: WorkerActor, w: Dictionary, manager: WorkerManager) -> void:
	manager.restore_routine(w.get("routine",{}),worker)
	worker.position = SaveSchema.decode(w.position)
	worker.velocity = Vector3.ZERO
	worker.desired = Vector3.ZERO
	worker.inventory.restore_contents(w.inventory)
	worker.completed_jobs = int(w.completed)
	worker.retries = int(w.retries)
	worker.resume_state = StringName(w.resume)
	worker.executor = JobExecutor.new()
	if w.kind!="": worker.executor.job = manager.make_job(w.kind)
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
	worker.path = manager.navigation.route(worker.position,worker.goal)
	worker.path_index = 0
	worker.tick_accumulator = 0
	worker.abstract_timer = 0
