class_name VehicleClearance
extends RefCounted

static func turn_clear(body: CharacterBody3D, yaw: float, mask: int) -> bool:
	# CharacterBody sweeps translation, but assigning a yaw can overlap a neighbor.
	var pose := Transform3D(Basis(Vector3.UP,yaw),body.global_position)
	for child in body.get_children():
		if not child is CollisionShape3D or child.disabled: continue
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = child.shape
		query.transform = pose*child.transform
		query.collision_mask = mask
		query.exclude = [body.get_rid()]
		if not body.get_world_3d().direct_space_state.intersect_shape(query).is_empty(): return false
	return true
