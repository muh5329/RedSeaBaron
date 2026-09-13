class_name DamageSystem
extends RefCounted

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
