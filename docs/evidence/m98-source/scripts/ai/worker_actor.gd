class_name WorkerActor
extends CharacterBody3D
signal job_completed(job: JobDefinition)
var worker_name: String = "Mara"
var worker_id: String = ""
var coat_color := Color("4d8b83")
var initial_position := Vector3.ZERO
var navigation: NavigationController
var home: Storage
var inventory := Inventory.new()
var executor := JobExecutor.new()
var machine := StateMachine.new()
var visual: PlayerVisual
var label: Label3D
var enabled: bool = false
var abstract_mode: bool = false
var abstract_timer: float = 0
var desired := Vector3.ZERO
var path := PackedVector3Array()
var path_index: int = 0
var goal := Vector3.ZERO
var resume_state: StringName = &"MoveToTask"
var failure_reason: String = ""
var retries: int = 0
var completed_jobs: int = 0
var distance_travelled: float = 0
var tick_accumulator: float = 0
var stuck_time: float = 0
var last_position := Vector3.ZERO
var history: Array[StringName] = [&"Idle"]

func status_text() -> String:
	const LABELS := {&"Idle":"Available",&"MoveToTask":"Walking to source",&"AcquireResource":"Collecting goods",&"PerformTask":"Working",&"DeliverResource":"Delivering cargo",&"Return":"Returning to warehouse",&"Blocked":"Waiting for retry",&"Failed":"Needs attention"}
	return String(LABELS.get(machine.current,"Working"))

func _ready() -> void:
	collision_layer = 32
	collision_mask = 9
	floor_snap_length = 0.6
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	visual = PlayerVisual.new()
	visual.coat_color = coat_color
	add_child(visual)
	label = BlockoutKit.label(self,"",Vector3(0,2.7,0),24)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	machine.register(&"Idle",func(_d): desired=Vector3.ZERO)
	machine.register(&"MoveToTask",func(d): _move_to(d,&"AcquireResource"))
	machine.register(&"AcquireResource",func(_d):
		if executor.acquire(inventory): machine.change(&"PerformTask")
		else: _blocked(executor.failure,&"AcquireResource")
	)
	machine.register(&"PerformTask",func(_d):
		desired = Vector3.ZERO
		if machine.elapsed>=executor.job.work_seconds:
			if is_instance_valid(executor.job.destination):
				_plan(executor.job.destination.position,&"DeliverResource")
			else: _blocked("Destination unavailable",&"PerformTask")
	)
	machine.register(&"DeliverResource",func(d):
		if _move_to(d,&"DeliverResource",true):
			if executor.deliver(inventory):
				completed_jobs += 1
				job_completed.emit(executor.job)
				_plan(home.position,&"Return")
			else: _blocked(executor.failure,&"DeliverResource")
	)
	machine.register(&"Return",func(d):
		if _move_to(d,&"Return",true):
			inventory.transfer_available(home.inventory)
			if inventory.mass()>0:
				_blocked("Home storage full",&"Return")
			else: machine.change(&"Idle")
	)
	machine.register(&"Blocked",func(_d):
		desired = Vector3.ZERO
		if machine.elapsed>=2.0:
			retries += 1
			if retries>3: machine.change(&"Failed")
			else: retry()
	)
	machine.register(&"Failed",func(_d): desired=Vector3.ZERO)
	machine.transitioned.connect(func(_old,next):
		history.append(next)
		if history.size()>64: history.pop_front()
	)
	last_position = position

func assign(job: JobDefinition) -> bool:
	if not enabled or machine.current!=&"Idle" or inventory.mass()>0 or job==null or not is_instance_valid(job.source) or not is_instance_valid(job.destination) or job.amount<=0: return false
	executor = JobExecutor.new()
	executor.job = job
	retries = 0
	_plan(job.source.position,&"MoveToTask")
	return true

func _plan(at: Vector3, state: StringName) -> void:
	goal = at
	path = navigation.route(position,goal)
	path_index = 0
	stuck_time = 0
	if path.is_empty(): _blocked("No route",state)
	else: machine.change(state)

func _blocked(reason: String, state: StringName) -> void:
	failure_reason = reason
	resume_state = state
	desired = Vector3.ZERO
	machine.change(&"Blocked")
	machine.elapsed = 0

func retry() -> void:
	if not enabled or machine.current not in [&"Blocked",&"Failed"]: return
	if not abstract_mode:
		navigation.refresh_near(position)
		navigation.refresh_near(goal)
	if resume_state in [&"MoveToTask",&"DeliverResource",&"Return"]: _plan(goal,resume_state)
	else: machine.change(resume_state)

func cancel() -> bool:
	if not enabled or machine.current==&"Idle": return false
	if executor.job and executor.job.contract and executor.acquired and not executor.delivered: return false
	retries = 0
	_plan(home.position,&"Return")
	return true

func _move_to(delta: float, next: StringName, return_arrival: bool = false) -> bool:
	var difference := goal-position
	difference.y = 0
	if difference.length()<4.0 and (abstract_mode or DamageSystem.clear_line(get_world_3d(),position+Vector3.UP,goal+Vector3.UP,DamageSystem.COMBAT_COVER_MASK)):
		desired = Vector3.ZERO
		if not return_arrival: machine.change(next)
		return true
	if path_index<path.size():
		difference = path[path_index]-position
		difference.y = 0
		if difference.length()<0.65:
			path_index += 1
			return false
	else:
		difference = goal-position
		difference.y = 0
	desired = difference.normalized()*4.8
	if position.distance_to(last_position)<0.08: stuck_time += delta
	else: stuck_time = 0
	last_position = position
	if stuck_time>1.5: _blocked("Route obstructed",machine.current)
	return false

func _physics_process(delta: float) -> void:
	if not enabled: return
	if abstract_mode:
		abstract_timer += delta
		if abstract_timer>=1:
			abstract_timer -= 1
			machine.tick(1.0)
			if desired.length()>0.1:
				var target := path[path_index] if path_index<path.size() else goal
				position = position.move_toward(target,4.8)
				position.y = CoastalRegion.height_at(position.x,position.z)+0.08
			velocity = Vector3.ZERO
		return
	tick_accumulator += delta
	if tick_accumulator>=0.1:
		machine.tick(tick_accumulator)
		tick_accumulator = 0
		label.text = "%s · %s\n%s"%[worker_name,status_text(),inventory.summary() if inventory.mass()>0 else failure_reason if machine.current in [&"Blocked",&"Failed"] else "Ready" if machine.current==&"Idle" else executor.job.title]
	var from := position
	velocity.x = desired.x
	velocity.z = desired.z
	velocity.y -= delta*24
	move_and_slide()
	distance_travelled += from.distance_to(position)
	if desired.length()>0.1: visual.rotation.y = atan2(-desired.x,-desired.z)
	visual.animate(delta,Vector2(velocity.x,velocity.z).length(),is_on_floor(),-1)
	if machine.current==&"PerformTask": _animate_work(delta)

func _animate_work(delta: float) -> void:
	if executor.job!=null and is_instance_valid(executor.job.source):
		var toward := executor.job.source.global_position-global_position
		toward.y = 0
		if toward.length_squared()>0.01:
			visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-toward.x,-toward.z),1-exp(-delta*12))
	# The arm hangs down local -Y; positive X lifts its hand toward local -Z.
	visual.right_arm.rotation.x = 0.8+sin(machine.elapsed*9)*0.5
