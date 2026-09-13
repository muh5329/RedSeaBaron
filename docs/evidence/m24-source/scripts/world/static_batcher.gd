class_name StaticBatcher
extends RefCounted
## Merge static scenery draw submissions by material; preserve original collision children.
static func combine(root: Node3D) -> int:
	var sources: Array[MeshInstance3D] = []
	_collect(root,sources)
	var groups := {}
	for source in sources:
		if source.name.begins_with("Terrain_") or source.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_ON or not source.material_override is StandardMaterial3D or source.mesh.get_surface_count()!=1: continue
		var material: Material = source.material_override
		if not groups.has(material): groups[material] = []
		groups[material].append(source)
	var merged := 0
	for material: Material in groups:
		var list: Array = groups[material]
		if list.size()<2: continue
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for source: MeshInstance3D in list:
			surface.append_from(source.mesh,0,root.global_transform.affine_inverse()*source.global_transform)
			for child in source.get_children():
				if child is Label3D: child.reparent(root,true)
			source.visible = false
			source.set_meta("batched_visual",true)
			merged += 1
		var batch := MeshInstance3D.new()
		batch.name = "StaticBatch_%d"%merged
		batch.mesh = surface.commit()
		batch.material_override = material
		root.add_child(batch)
	return merged

static func _collect(root: Node, results: Array[MeshInstance3D]) -> void:
	if root.has_meta("animated_part"): return
	if root is MeshInstance3D: results.append(root)
	for child in root.get_children(): _collect(child,results)
