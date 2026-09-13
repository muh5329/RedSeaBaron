class_name SurveySite
extends Node3D
signal visited(site: SurveySite)

@export var site_id: String
@export var title: String
@export var description: String
@export var interaction_radius: float = 3.0
var discovered: bool = false
var marker: MeshInstance3D

func prompt_action() -> String:
	return "Rest at " if discovered else "Stamp: "

func recovery_position() -> Vector3:
	return global_position + Vector3(0, 0.2, 1.5)

func _ready() -> void:
	BlockoutKit.cylinder(self, Vector3(0, 0.06, 0), 1.3, 0.12, Color("cdb787"), -1, 12)
	BlockoutKit.box(self, Vector3(0, 1.15, 0), Vector3(0.13, 2.3, 0.13), Color("695943"))
	BlockoutKit.box(self, Vector3(0, 1.8, 0), Vector3(1.7, 0.75, 0.18), Color("304e4b"))
	BlockoutKit.label(self, title.to_upper(), Vector3(0, 1.8, 0.12), 18)
	marker = BlockoutKit.box(self, Vector3(0, 3.0, 0), Vector3(0.38, 0.38, 0.38), Color("e9bd71"))
	marker.rotation.z = PI / 4

func can_interact(actor: Node3D) -> bool:
	return actor.global_position.distance_to(global_position) <= interaction_radius

func interact(actor: Node3D) -> bool:
	if not can_interact(actor):
		return false
	if not discovered:
		discovered = true
		marker.material_override = BlockoutKit.material(Color("80b5a0"))
		visited.emit(self)
	return true
