class_name DamageSystem
extends RefCounted
const COMBAT_COVER_MASK: int = 1 | 8

static func health_of(actor: Object) -> HealthComponent:
	if actor is Node:
		for child in actor.get_children():
			if child is HealthComponent:
				return child
	return null

static func apply(actor: Object, amount: float, faction: StringName) -> bool:
	var health := health_of(actor)
	return health != null and health.take_damage(amount, faction)

static func clear_line(world: World3D, a: Vector3, b: Vector3, mask: int = 1) -> bool:
	return world.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a, b, mask)).is_empty()

static func can_see_health(world: World3D, from: Vector3, target: Node3D) -> bool:
	var health := health_of(target)
	if health==null or health.current<=0: return false
	var point := health.aim_anchor.global_position if is_instance_valid(health.aim_anchor) else target.global_position+Vector3.UP
	var hit := world.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,point,COMBAT_COVER_MASK))
	if hit.is_empty(): return true
	# A mounted rider is physically part of the bike. Hitting that specific
	# shape sees the rider; hitting chassis, wings or intervening cover does not.
	var receiver := health.occlusion_receiver
	if not is_instance_valid(receiver) or receiver.disabled: return false
	var body: CollisionObject3D = hit.collider
	return body==receiver.get_parent() and body.shape_owner_get_owner(body.shape_find_owner(hit.shape))==receiver
