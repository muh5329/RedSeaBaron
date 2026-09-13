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

func _input(event: InputEvent) -> void:
	if enabled and not event.is_echo() and event.is_action_pressed("workers"):
		pending_panel_toggle = true

func _ready() -> void:
	navigation = NavigationController.new()
	add_child(navigation)
	var worker := WorkerActor.new()
	worker.navigation = navigation
	worker.home = logistics.warehouse
	worker.position = logistics.warehouse.position+Vector3(-3,0.1,2)
	add_child(worker)
	workers.append(worker)
	worker.job_completed.connect(func(job: JobDefinition): message.emit("%s completed: %s"%[worker.worker_name,job.title]))
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
			job.source = logistics.sources[1]
			job.item_id = "ore"
		"Farm":
			job.title = "Harvest 5 olives for the warehouse"
			job.source = logistics.sources[0]
			job.item_id = "olive"
		"Transport":
			job.title = "Carry 5 timber to the warehouse"
			job.source = logistics.sources[2]
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

func order(kind: String) -> bool:
	if not enabled: return false
	var accepted := workers[0].assign(make_job(kind))
	message.emit("Job assigned: "+kind if accepted else "Worker is busy or carrying cargo; retry or recall first.")
	return accepted

func _process(_delta: float) -> void:
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
	if not panel.visible: return
	for pair in [["job_gather","Gather"],["job_farm","Farm"],["job_delivery","Deliver"],["job_shop","ShopKeep"],["job_transport","Transport"]]:
		if Input.is_action_just_pressed(pair[0]): order(pair[1])
	if Input.is_action_just_pressed("job_retry"):
		workers[0].retries = 0
		workers[0].retry()
	if Input.is_action_just_pressed("job_cancel") and not workers[0].cancel():
		message.emit("A parcel in transit must be delivered. Retry its route if blocked.")
	var worker := workers[0]
	readout.text = "WORK ORDERS     Mara · %s\n\n%s\nCargo · %s\nCompleted jobs · %d\n\n3  Gather ore    4  Harvest olives    5  Courier parcel\n6  Stock market from warehouse    7  Transport timber\n8  Retry blocked job    9  Recall to warehouse\nN  Close    ·    Jobs continue while you explore"%[worker.machine.current,worker.failure_reason if worker.machine.current in [&"Blocked",&"Failed"] else worker.executor.job.title if worker.executor.job else "Available for a task",worker.inventory.summary(),worker.completed_jobs]
