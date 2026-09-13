class_name PlayerVisual
extends Node3D
## Art-independent locomotion presentation; replace this with a rig later.
@export var coat_color: Color = Color("ad493a")
var torso: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var phase: float = 0.0

func _ready() -> void:
	var red := coat_color
	var dark := Color("283b3d")
	var leather := Color("765540")
	torso = Node3D.new()
	torso.position.y = 0.94
	add_child(torso)
	BlockoutKit.box(torso, Vector3(0, 0.24, 0), Vector3(0.57, 0.65, 0.34), red)
	BlockoutKit.box(torso, Vector3(0, -0.07, 0), Vector3(0.58, 0.09, 0.36), leather)
	BlockoutKit.sphere(torso, Vector3(0, 0.82, 0), Vector3(0.41, 0.26, 0.41), Color("d4ac7f"))
	BlockoutKit.sphere(torso, Vector3(0, 0.95, 0.02), Vector3(0.44, 0.16, 0.43), leather)
	BlockoutKit.box(torso, Vector3(0, 0.84, -0.195), Vector3(0.36, 0.10, 0.055), dark)
	for x in [-0.1, 0.1]:
		BlockoutKit.box(torso, Vector3(x, 0.85, -0.23), Vector3(0.12, 0.075, 0.03), Color("e8c47c"))
	BlockoutKit.box(torso, Vector3(0, 0.57, 0), Vector3(0.42, 0.10, 0.40), Color("e6c27d"))
	BlockoutKit.box(torso, Vector3(0.21, 0.33, 0.22), Vector3(0.14, 0.47, 0.08), Color("e6c27d"))
	BlockoutKit.box(torso, Vector3(0, 0.23, 0.27), Vector3(0.43, 0.47, 0.22), leather)
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.16, 0.87, 0)
		add_child(leg)
		BlockoutKit.box(leg, Vector3(0, -0.31, 0), Vector3(0.23, 0.60, 0.26), dark)
		BlockoutKit.box(leg, Vector3(0, -0.72, -0.05), Vector3(0.25, 0.27, 0.38), leather)
		var arm := Node3D.new()
		arm.set_meta("animated_part",true)
		arm.position = Vector3(side * 0.36, 0.47, 0)
		torso.add_child(arm)
		BlockoutKit.box(arm, Vector3(0, -0.24, 0), Vector3(0.19, 0.47, 0.23), red)
		BlockoutKit.box(arm, Vector3(0, -0.53, -0.02), Vector3(0.17, 0.15, 0.20), leather)
		if side < 0.0:
			left_leg = leg
			left_arm = arm
		else:
			right_leg = leg
			right_arm = arm

	StaticBatcher.combine(torso)

func animate(delta: float, speed: float, grounded: bool, dodge_fraction: float) -> void:
	phase += delta * speed * 2.4
	var stride := minf(speed / 8.0, 1.0) * 0.72 if grounded else 0.18
	left_leg.rotation.x = sin(phase) * stride
	right_leg.rotation.x = -sin(phase) * stride
	left_arm.rotation.x = -sin(phase) * stride * 0.75
	right_arm.rotation.x = sin(phase) * stride * 0.75
	torso.position.y = 0.94 + absf(sin(phase)) * stride * 0.045
	rotation.x = -dodge_fraction * TAU if dodge_fraction >= 0.0 else 0.0
	position = Vector3.UP * 0.94 - basis * (Vector3.UP * 0.94)
