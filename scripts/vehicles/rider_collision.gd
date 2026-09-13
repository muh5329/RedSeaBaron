class_name RiderCollision
extends RefCounted
## A cleaned convex envelope of the actual fixed riding pose, in BikeVisual space.
var bike: BikeController
var collision: CollisionShape3D
var active: bool = false

func setup(owner_bike: BikeController) -> void:
	bike = owner_bike
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append_faces(bike.visual.rider,bike.visual.global_transform.affine_inverse(),surface)
	collision = CollisionShape3D.new()
	collision.name = "MountedRiderCollision"
	collision.shape = surface.commit().create_convex_shape(true,false)
	collision.disabled = true
	bike.add_child(collision)
	sync_transform()

func _append_faces(node: Node3D, frame: Transform3D, surface: SurfaceTool) -> void:
	# The rider root is hidden while parked; only skip individually hidden source
	# meshes left behind by ColorBatch, not the root's inherited visibility.
	if node is MeshInstance3D and node.visible and node.mesh:
		var pose := frame*node.global_transform
		for vertex: Vector3 in node.mesh.get_faces(): surface.add_vertex(pose*vertex)
	for child in node.get_children():
		if child is Node3D: _append_faces(child,frame,surface)

func can_fit(visual_pose: Transform3D, ignore_actor: CollisionObject3D = null) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.transform = bike.global_transform*visual_pose
	query.collision_mask = VehicleClearance.WORLD_AND_NPCS
	var excluded: Array[RID] = [bike.get_rid()]
	if ignore_actor: excluded.append(ignore_actor.get_rid())
	query.exclude = excluded
	return bike.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func set_mounted(value: bool) -> void:
	active = value
	collision.disabled = not value
	sync_transform()

func restrict_pose(previous_visual: Transform3D) -> void:
	if active and not can_fit(bike.visual.transform):
		bike.visual.transform = previous_visual

func sync_transform() -> void:
	collision.transform = bike.visual.transform
