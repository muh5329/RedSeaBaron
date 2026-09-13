class_name CombatBrain
extends Node
## Reusable decision component; EnemyActor owns presentation and locomotion.
var navigation: NavigationController
var path := PackedVector3Array()
var path_index: int = 0
var route_clock: float = 0
var last_seen := Vector3.ZERO
var memory_seconds: float = 0
var route_requests: int = 0
var actor: CharacterBody3D
var target: PlayerController
var machine := StateMachine.new()
var decision_clock: float = 0
var enabled: bool = true
var strike_done: bool = false
var detection_range: float = 17.0
var attack_range: float = 2.15
var damage: float = 13.0

func _ready() -> void:
	machine.register(&"Idle", _idle)
	machine.register(&"Pursue", _pursue)
	machine.register(&"Attack", _attack)
	machine.register(&"Hit", _hit)
	machine.register(&"Return", _return_home)
	machine.register(&"Dead", func(_delta): actor.desired_velocity = Vector3.ZERO)
	machine.transitioned.connect(func(_old, next):
		strike_done = false
		if next in [&"Pursue",&"Return"]:
			path.clear()
			route_clock = 0
		actor.state_label.text = "%s · %s" % [actor.kind, next]
	)

func _physics_process(delta: float) -> void:
	if not enabled or not is_instance_valid(target):
		return
	route_clock -= delta
	decision_clock += delta
	var interval := 0.1 if actor.position.distance_to(target.position) < 80 else 1.0
	if decision_clock >= interval:
		var step := decision_clock
		decision_clock = 0
		machine.tick(step)

func _distance() -> float:
	return actor.global_position.distance_to(target.global_position)

func _sees() -> bool:
	var health := DamageSystem.health_of(target)
	return health != null and health.current > 0 and DamageSystem.clear_line(actor.get_world_3d(), actor.global_position + Vector3.UP, target.global_position + Vector3.UP)

func _idle(_delta: float) -> void:
	actor.desired_velocity = Vector3.ZERO
	if _distance() < detection_range and _sees():
		last_seen = target.position
		memory_seconds = 8
		machine.change(&"Pursue")

func _pursue(delta: float) -> void:
	var health := DamageSystem.health_of(target)
	if health==null or health.current<=0 or _distance()>28 or actor.position.distance_to(actor.home)>27:
		machine.change(&"Return")
		return
	if _sees():
		last_seen = target.position
		memory_seconds = 8
	else:
		memory_seconds -= delta
		if memory_seconds<=0:
			machine.change(&"Return")
			return
	if _distance()<attack_range and _sees():
		actor.desired_velocity = Vector3.ZERO
		machine.change(&"Attack")
		return
	_navigate(last_seen)

func _navigate(goal: Vector3) -> void:
	var steering_goal := goal
	# Seeing over a low barrier does not mean the actor's legs can cross it.
	var blocked := not DamageSystem.clear_line(actor.get_world_3d(),actor.position+Vector3.UP,goal+Vector3.UP) or not DamageSystem.clear_line(actor.get_world_3d(),actor.position+Vector3.UP*0.4,goal+Vector3.UP*0.4)
	if navigation and navigation.ready_for_paths and blocked:
		if route_clock<=0:
			navigation.refresh_near(actor.position)
			navigation.refresh_near(goal)
			path = navigation.route(actor.position,goal)
			path_index = 0
			route_clock = 1.0
			route_requests += 1
		while path_index<path.size() and Vector2(path[path_index].x-actor.position.x,path[path_index].z-actor.position.z).length()<0.6:
			path_index += 1
		if path_index<path.size(): steering_goal = path[path_index]
		else:
			actor.desired_velocity = Vector3.ZERO
			return
	var direction := steering_goal-actor.position
	direction.y = 0
	actor.desired_velocity = direction.normalized()*actor.move_speed if direction.length()>0.3 else Vector3.ZERO

func _attack(_delta: float) -> void:
	actor.desired_velocity = Vector3.ZERO
	if _distance()>28 or actor.position.distance_to(actor.home)>27:
		machine.change(&"Return")
		return
	actor.face(target.position)
	if machine.elapsed >= 0.55 and not strike_done:
		strike_done = true
		if _distance() < attack_range + 0.25 and _sees():
			DamageSystem.apply(target, damage, &"hostile")
	if machine.elapsed >= 1.2:
		machine.change(&"Pursue")

func _hit(_delta: float) -> void:
	actor.desired_velocity = Vector3.ZERO
	if machine.elapsed > 0.3:
		machine.change(&"Pursue")

func _return_home(_delta: float) -> void:
	var difference: Vector3 = actor.home - actor.position
	_navigate(actor.home)
	if difference.length() < 1:
		machine.change(&"Idle")

func react_to_hit() -> void:
	machine.change(&"Hit")

func die() -> void:
	machine.change(&"Dead")
	actor.desired_velocity = Vector3.ZERO
