class_name ColorBatch
extends RefCounted
## Merge opaque BlockoutKit parts into one colored surface per rigid joint.
## Texture, transparent and custom materials stay outside this narrow path.
static func combine(root: Node3D) -> int:
	var found: Array[MeshInstance3D] = []
	StaticBatcher._collect(root,found)
	var sources: Array[MeshInstance3D] = []
	for source in found:
		if not source.visible or source.has_meta("batched_visual") or source.mesh.get_surface_count()!=1: continue
		if source.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_ON: continue
		if not source.material_override in BlockoutKit.materials.values(): continue
		if source.material_override.albedo_color.a<1.0: continue
		sources.append(source)
	if sources.size()<2: return 0
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for source in sources:
		var arrays := source.mesh.surface_get_arrays(0)
		var colors := PackedColorArray()
		colors.resize(arrays[Mesh.ARRAY_VERTEX].size())
		colors.fill(source.material_override.albedo_color)
		arrays[Mesh.ARRAY_COLOR] = colors
		var geometry := ArrayMesh.new()
		geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		if geometry.surface_get_array_index_len(0)==0:
			var indexed := SurfaceTool.new()
			indexed.create_from(geometry,0)
			indexed.index()
			geometry = indexed.commit()
		surface.append_from(geometry,0,root.global_transform.affine_inverse()*source.global_transform)
		for child in source.get_children():
			if child is Label3D: child.reparent(root,true)
		source.visible = false
		source.set_meta("batched_visual",true)
	var material := StandardMaterial3D.new()
	material.roughness = 0.94
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	var batch := MeshInstance3D.new()
	batch.name = "ColorBatch"
	batch.mesh = surface.commit()
	batch.material_override = material
	root.add_child(batch)
	return sources.size()
