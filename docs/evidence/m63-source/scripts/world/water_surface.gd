class_name WaterSurface
extends MeshInstance3D
## A bounded visual surface; water safety uses the same WaterBody resource.
var water: WaterBody
func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = water.bounds.size
	mesh = plane
	var center := water.bounds.get_center()
	position = Vector3(center.x,water.level,center.y)
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/water_surface.gdshader")
	material.set_shader_parameter("elliptical",water.elliptical)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_range_end = 1000
