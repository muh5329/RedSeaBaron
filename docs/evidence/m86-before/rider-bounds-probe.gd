extends SceneTree
var low := Vector3(INF,INF,INF)
var high := Vector3(-INF,-INF,-INF)
func _initialize() -> void:
	probe.call_deferred()
func walk(node: Node3D, frame: Transform3D) -> void:
	if node is MeshInstance3D and node.visible and node.mesh:
		var box: AABB = frame*node.global_transform*node.mesh.get_aabb()
		low = low.min(box.position)
		high = high.max(box.end)
	for child in node.get_children():
		if child is Node3D: walk(child,frame)
func probe() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	walk(game.bike.visual.rider,game.bike.visual.global_transform.affine_inverse())
	print("RIDER_BOUNDS low=",low," high=",high," center=",(low+high)/2," size=",high-low)
	quit()
