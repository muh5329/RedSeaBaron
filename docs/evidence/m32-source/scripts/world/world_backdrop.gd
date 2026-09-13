class_name WorldBackdrop
extends Node3D
## One reusable GPU-displaced horizon mesh; never supplies gameplay collision.
const WIDTH: float = 4096
var focus: Node3D
var geometry: MeshInstance3D
var material: ShaderMaterial
var anchor := Vector2(INF,INF)
var relocations: int = 0

func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE*WIDTH
	plane.subdivide_width = 127
	plane.subdivide_depth = 127
	geometry = MeshInstance3D.new()
	geometry.mesh = plane
	geometry.extra_cull_margin = 180
	geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material = ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/world_backdrop.gdshader")
	geometry.material_override = material
	add_child(geometry)
	_process(0)

func _process(_delta: float) -> void:
	if not is_instance_valid(focus): return
	var point := Vector2(focus.position.x,focus.position.z)
	var snapped := (point/256).round()*256
	if snapped!=anchor:
		anchor = snapped
		geometry.position = Vector3(anchor.x,0,anchor.y)
		relocations += 1
	material.set_shader_parameter("focus_point",point)
