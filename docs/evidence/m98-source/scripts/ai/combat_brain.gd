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
var approach_clock: float = 0
var approach_target := Vector3(INF,INF,INF)
var approach_point := Vector3.ZERO
var approach_query := PhysicsShapeQueryParameters3D.new()
var actor: CharacterBody3D
var target: PlayerController
var machine := StateMachine.new()
var decision_clock: float = 0
var enabled: bool = true
var strike_done: bool = false
var strike_direction := Vector3.FORWARD
@export var commit_seconds: float = 0.35
@export var windup_seconds: float = 0.55
@export var recovery_seconds: float = 1.2
@export var attack_arc_degrees: float = 100.0
var detection_range: float = 17.0
var attack_range: float = 2.15
var damage: float = 13.0

func _ready() -> void:
	approach_query.collision_mask = DamageSystem.COMBAT_COVER_MASK
	for child in actor.get_children():
		if child is CollisionShape3D and child.shape!=null:
			approach_query.shape = child.shape
			break
	machine.register(&"Idle", _idle)
	machine.register(&"Pursue", _pursue)
	machine.register(&"Attack", _attack)
	machine.register(&"Hit", _hit)
	machine.register(&"Return", _return_home)
	machine.register(&"Dead", func(_delta): actor.desired_velocity = Vector3.ZERO)
	machine.transitioned.connect(func(_old, next):
		strike_done = false
		decision_clock = 0
		if next==&"Attack":
			actor.face(target.position)
			strike_direction = (target.position-actor.position).normalized()
		if next in [&"Pursue",&"Return"]:
			path.clear()
			route_clock = 0
		actor.state_label.text = "%s · %s" % [actor.kind, next]
	)

func _physics_process(delta: float) -> void:
	if not enabled or not is_instance_valid(target):
		return
	route_clock -= delta
	approach_clock -= delta
	decision_clock += delta
	var interval := 0.1 if actor.position.distance_to(target.position) < 80 else 1.0
	if decision_clock >= interval:
		var step := decision_clock
		decision_clock = 0
		machine.tick(step)

func _distance() -> float:
	return actor.global_position.distance_to(target.global_position)

func _sees() -> bool:
	return DamageSystem.can_see_health(actor.get_world_3d(),actor.global_position+Vector3.UP,target)

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
	goal = _mounted_approach(goal)
	var steering_goal := goal
	# Seeing over a low barrier does not mean the actor's legs can cross it.
	var blocked := not DamageSystem.clear_line(actor.get_world_3d(),actor.position+Vector3.UP,goal+Vector3.UP,DamageSystem.COMBAT_COVER_MASK) or not DamageSystem.clear_line(actor.get_world_3d(),actor.position+Vector3.UP*0.4,goal+Vector3.UP*0.4,DamageSystem.COMBAT_COVER_MASK)
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
	if machine.elapsed<commit_seconds:
		actor.face(target.position)
		strike_direction = target.position-actor.position
		strike_direction.y = 0
		strike_direction = strike_direction.normalized()
	if machine.elapsed >= windup_seconds and not strike_done:
		strike_done = true
		var offset: Vector3 = target.position-actor.position
		offset.y = 0
		var within_arc := offset.length()<0.05 or strike_direction.dot(offset.normalized())>=cos(deg_to_rad(attack_arc_degrees)*0.5)
		if within_arc and _distance() < attack_range + 0.25 and _sees():
			DamageSystem.apply(target, damage, &"hostile")
	if machine.elapsed >= recovery_seconds:
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

func _mounted_approach(goal: Vector3) -> Vector3:
	var health := DamageSystem.health_of(target)
	if health==null or not is_instance_valid(health.occlusion_receiver) or not _sees(): return goal
	if approach_clock>0 and approach_target.distance_to(goal)<0.25: return approach_point
	approach_clock = 0.5
	approach_target = goal
	approach_point = goal
	var best := INF
	var space := actor.get_world_3d().direct_space_state
	for i in range(12):
		var angle := i*TAU/12
		var candidate := goal+Vector3(sin(angle),0,cos(angle))*1.9
		var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(candidate+Vector3.UP*2,candidate-Vector3.UP*2,1))
		if floor_hit.is_empty() or floor_hit.normal.y<0.65 or absf(floor_hit.position.y-goal.y)>1: continue
		candidate.y = floor_hit.position.y+0.07
		approach_query.transform.origin = candidate+Vector3.UP*0.9
		if not space.intersect_shape(approach_query,1).is_empty(): continue
		if not DamageSystem.can_see_health(actor.get_world_3d(),candidate+Vector3.UP,target): continue
		var distance := actor.position.distance_squared_to(candidate)
		if distance<best:
			best = distance
			approach_point = candidate
	return approach_point
