class_name FoliageFade
extends RefCounted
## Cached opaque/dithered materials retain MultiMesh instance centers.
static var materials: Dictionary = {}
static func material(color: Color, vertex_colors: bool = false) -> ShaderMaterial:
	var key := color.to_html()+str(vertex_colors)
	if not materials.has(key):
		var result := ShaderMaterial.new()
		result.shader = preload("res://assets/shaders/foliage_fade.gdshader")
		result.set_shader_parameter("tint",color)
		result.set_shader_parameter("vertex_colors",vertex_colors)
		materials[key] = result
	return materials[key]
