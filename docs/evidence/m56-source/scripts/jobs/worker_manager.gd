class_name WorkerManager
extends Node3D
signal message(text: String)
var logistics: LogisticsWorld
var navigation: NavigationController
var workers: Array[WorkerActor] = []
var enabled: bool = false
var panel: PanelContainer
var readout: Label
var panel_key_held: bool = false
var pending_panel_toggle: bool = false
var pending_routine_toggle: bool = false
var routine := JobRoutine.new()
var routine_states: Dictionary = {}
var selected_worker_index: int = 0
var pending_next_worker: bool = false
# The original public properties continue to address Mara for existing integrations.
var routine_active: bool:
	get: return state_for(worker_by_id("mara")).active
	set(value): state_for(worker_by_id("mara")).active = value
var routine_job: bool:
	get: return state_for(worker_by_id("mara")).current_job
	set(value): state_for(worker_by_id("mara")).current_job = value
var routine_step: int:
	get: return state_for(worker_by_id("mara")).step
	set(value): state_for(worker_by_id("mara")).step = value
var routine_cycles: int:
	get: return state_for(worker_by_id("mara")).cycles
	set(value): state_for(worker_by_id("mara")).cycles = value

func worker_by_id(id: String) -> WorkerActor:
	for worker in workers:
		if worker.worker_id==id: return worker
	return null

func state_for(worker: WorkerActor) -> WorkerRoutineState:
	if not routine_states.has(worker): routine_states[worker] = WorkerRoutineState.new()
	return routine_states[worker]

func selected_worker() -> WorkerActor:
	selected_worker_index = clampi(selected_worker_index,0,workers.size()-1)
	return workers[selected_worker_index]

func _input(event: InputEvent) -> void:
	if enabled and panel.visible and not event.is_echo() and event.is_action_pressed("next_worker"):
		pending_next_worker = true
	if enabled and not event.is_echo() and event.is_action_pressed("workers"):
		pending_panel_toggle = true
	if enabled and panel.visible and not event.is_echo() and event.is_action_pressed("job_routine"):
		pending_routine_toggle = true

func _ready() -> void:
	navigation = NavigationController.new()
	add_child(navigation)
	for definition in [["mara","Mara",Vector3(-3,0.1,2),Color("4d8b83")],["ivo","Ivo",Vector3(-5,0.1,4),Color("52688a")]]:
		var worker := WorkerActor.new()
		worker.worker_id = definition[0]
		worker.worker_name = definition[1]
		worker.coat_color = definition[3]
		worker.navigation = navigation
		worker.home = logistics.warehouse
		worker.position = logistics.warehouse.position+definition[2]
		worker.initial_position = worker.position
		add_child(worker)
		workers.append(worker)
		state_for(worker)
		worker.job_completed.connect(_job_completed.bind(worker))
	var ui := CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	panel = PanelContainer.new()
	panel.position = Vector2(300,150)
	panel.size = Vector2(660,300)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("203a35")
	for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: style.set_content_margin(side,24)
	panel.add_theme_stylebox_override("panel",style)
	ui.add_child(panel)
	readout = Label.new()
	readout.add_theme_font_size_override("font_size",19)
	readout.add_theme_color_override("font_color",Color("f6e7c7"))
	panel.add_child(readout)
	panel.visible = false

func make_job(kind: String) -> JobDefinition:
	var job := JobDefinition.new()
	job.kind = kind
	job.destination = logistics.warehouse
	match kind:
		"Gather", "Mine":
			job.title = "Gather 5 iron ore for the warehouse"
			job.source = logistics.source_by_id("ore")
			job.item_id = "ore"
		"Farm":
			job.title = "Harvest 5 olives for the warehouse"
			job.source = logistics.source_by_id("olive")
			job.item_id = "olive"
		"Transport":
			job.title = "Carry 5 timber to the warehouse"
			job.source = logistics.source_by_id("wood")
			job.item_id = "wood"
		"ShopKeep":
			job.title = "Stock and sell 5 warehouse olives"
			job.source = logistics.warehouse
			job.destination = logistics.market
			job.shop = logistics.shop
			job.item_id = "olive"
		"Deliver":
			job.title = "Courier parcel to the south quay"
			job.source = logistics.dispatch
			job.destination = logistics.destination
			job.item_id = "package"
			job.amount = 1
			job.contract = DeliveryContract.new()
			job.contract.origin = logistics.dispatch
			job.contract.destination = logistics.destination
			job.contract.completed.connect(func(reward: int): logistics.shop.credits += reward)
	return job

func _job_completed(job: JobDefinition, worker: WorkerActor) -> void:
	message.emit("%s completed: %s"%[worker.worker_name,job.title])
	var state := state_for(worker)
	if state.current_job and job.kind==routine.steps[state.step]:
		state.step += 1
		if state.step>=routine.steps.size():
			state.step = 0
			state.cycles += 1
			if not routine.repeat: state.active = false
	state.current_job = false

func order(kind: String) -> bool:
	if not enabled: return false
	var worker := selected_worker()
	var accepted := worker.assign(make_job(kind))
	if accepted:
		state_for(worker).active = false
		state_for(worker).current_job = false
	message.emit("%s assigned: %s"%[worker.worker_name,kind] if accepted else "Worker is busy or carrying cargo; retry or recall first.")
	return accepted

func toggle_routine() -> bool:
	if not enabled: return false
	var worker := selected_worker()
	var state := state_for(worker)
	if state.active:
		state.active = false
		message.emit("%s: stopping after the current job; carried goods stay safe."%worker.worker_name)
		return true
	if worker.machine.current!=&"Idle" or worker.inventory.mass()>0: return false
	state.step = 0
	state.cycles = 0
	state.current_job = false
	state.active = true
	message.emit("%s: harvest olives, stock market, repeat."%worker.worker_name)
	return true

func routine_snapshot(worker: WorkerActor = null) -> Dictionary:
	return state_for(worker if worker else worker_by_id("mara")).snapshot(routine.id)

func restore_routine(data: Dictionary, worker: WorkerActor = null) -> void:
	state_for(worker if worker else worker_by_id("mara")).restore(data)

func _process(_delta: float) -> void:
	var next_requested := pending_next_worker or Input.is_action_just_pressed("next_worker")
	pending_next_worker = false
	for old_worker in routine_states.keys():
		if not is_instance_valid(old_worker) or not workers.has(old_worker): routine_states.erase(old_worker)
	var routine_requested := pending_routine_toggle or Input.is_action_just_pressed("job_routine")
	pending_routine_toggle = false
	var held := Input.is_action_pressed("workers")
	var toggle := pending_panel_toggle or (held and not panel_key_held)
	pending_panel_toggle = false
	panel_key_held = held
	for worker in workers: worker.enabled = enabled
	if not enabled:
		panel.visible = false
		return
	if toggle:
		panel.visible = not panel.visible
		logistics.panel.visible = false
	if panel.visible:
		if next_requested: selected_worker_index = (selected_worker_index+1)%workers.size()
		if routine_requested and not toggle_routine(): message.emit("Finish the current job or return carried goods before starting a routine.")
		for pair in [["job_gather","Gather"],["job_farm","Farm"],["job_delivery","Deliver"],["job_shop","ShopKeep"],["job_transport","Transport"]]:
			if Input.is_action_just_pressed(pair[0]): order(pair[1])
		if Input.is_action_just_pressed("job_retry"):
			selected_worker().retries = 0
			selected_worker().retry()
		if Input.is_action_just_pressed("job_cancel"):
			state_for(selected_worker()).active = false
			state_for(selected_worker()).current_job = false
			if not selected_worker().cancel(): message.emit("A parcel in transit must be delivered. Retry its route if blocked.")
	for worker in workers:
		var state := state_for(worker)
		if state.active and worker.machine.current==&"Idle":
			state.current_job = worker.assign(make_job(routine.steps[state.step]))
			if not state.current_job:
				state.active = false
				message.emit("%s: routine stopped; next job could not be assigned."%worker.worker_name)
	if not panel.visible: return
	var worker := selected_worker()
	var state := state_for(worker)
	readout.text = "WORK ORDERS     %s · %s    [Tab: next worker]\n\n%s\nCargo · %s\nCompleted jobs · %d\nRoutine · %s · %d cycles\n0  Start / stop harvest-and-market routine\n\n3  Gather ore    4  Harvest olives    5  Courier parcel\n6  Stock market from warehouse    7  Transport timber\n8  Retry blocked job    9  Recall to warehouse\nN  Close    ·    Jobs continue while you explore"%[worker.worker_name,worker.machine.current,worker.failure_reason if worker.machine.current in [&"Blocked",&"Failed"] else worker.executor.job.title if worker.executor.job else "Available for a task",worker.inventory.summary(),worker.completed_jobs,"Running" if state.active else "Finishing current job" if state.current_job else "Stopped",state.cycles]

func blocks_combat_input() -> bool:
	return enabled and (panel.visible or pending_panel_toggle or Input.is_action_just_pressed("workers"))
