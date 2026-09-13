class_name PlayerVisual
extends Node3D
## Shared traveler/worker presentation; stable joints support weapons and riding.
@export var coat_color: Color = Color("ad493a")
var torso: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var phase: float = 0.0

func _ready() -> void:
	var dark := Color("283b3d")
	var leather := Color("765540")
	var skin := Color("d4ac7f")
	var canvas := Color("e6c27d")
	torso = Node3D.new()
	torso.position.y = 0.94
	add_child(torso)
	BlockoutKit.cylinder(torso,Vector3(0,0.24,0),0.31,0.65,coat_color,0.255,10)
	BlockoutKit.cylinder(torso,Vector3(0,-0.04,0),0.315,0.10,leather,-1,10)
	BlockoutKit.box(torso,Vector3(0,-0.04,-0.309),Vector3(0.10,0.09,0.025),canvas)
	for y in [0.12,0.28,0.43]:
		BlockoutKit.sphere(torso,Vector3(0,y,-0.295),Vector3.ONE*0.045,canvas)
	for x in [-0.19,0.19]:
		BlockoutKit.box(torso,Vector3(x,0.24,-0.235),Vector3(0.13,0.18,0.04),leather)
	BlockoutKit.cylinder(torso,Vector3(0,0.60,0),0.11,0.18,skin,-1,8)
	BlockoutKit.sphere(torso,Vector3(0,0.79,0),Vector3(0.46,0.47,0.44),skin)
	BlockoutKit.sphere(torso,Vector3(0,0.97,0.025),Vector3(0.49,0.16,0.47),leather)
	BlockoutKit.cylinder(torso,Vector3(0,0.83,0),0.233,0.075,dark,-1,10)
	for x in [-0.105,0.105]:
		BlockoutKit.box(torso,Vector3(x,0.83,-0.22),Vector3(0.17,0.12,0.07),dark)
		BlockoutKit.box(torso,Vector3(x,0.83,-0.259),Vector3(0.12,0.075,0.018),canvas)
	BlockoutKit.sphere(torso,Vector3(0,0.72,-0.221),Vector3(0.09,0.09,0.09),skin)
	BlockoutKit.cylinder(torso,Vector3(0,0.56,0),0.285,0.10,canvas,-1,10)
	BlockoutKit.box(torso,Vector3(0.21,0.34,0.25),Vector3(0.13,0.45,0.07),canvas)
	BlockoutKit.box(torso,Vector3(0,0.23,0.30),Vector3(0.43,0.46,0.24),leather)
	BlockoutKit.box(torso,Vector3(0,0.43,0.325),Vector3(0.45,0.10,0.27),dark)
	for x in [-0.14,0.14]:
		BlockoutKit.box(torso,Vector3(x,0.24,0.426),Vector3(0.045,0.43,0.025),canvas)
	var roll := BlockoutKit.cylinder(torso,Vector3(0,0.56,0.31),0.09,0.48,canvas,-1,10)
	roll.rotation.z = PI/2
	for side in [-1.0,1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side*0.16,0.87,0)
		add_child(leg)
		BlockoutKit.cylinder(leg,Vector3(0,-0.29,0),0.115,0.58,dark,0.13,8)
		BlockoutKit.cylinder(leg,Vector3(0,-0.68,0),0.125,0.25,leather,-1,8)
		BlockoutKit.box(leg,Vector3(0,-0.78,-0.06),Vector3(0.25,0.14,0.37),leather)
		BlockoutKit.box(leg,Vector3(0,-0.83,-0.06),Vector3(0.26,0.035,0.38),dark)
		ColorBatch.combine(leg)
		leg.set_meta("animated_part",true)
		var arm := Node3D.new()
		arm.position = Vector3(side*0.36,0.47,0)
		torso.add_child(arm)
		BlockoutKit.cylinder(arm,Vector3(0,-0.20,0),0.095,0.40,coat_color,0.12,8)
		BlockoutKit.cylinder(arm,Vector3(0,-0.42,0),0.09,0.075,canvas,-1,8)
		BlockoutKit.sphere(arm,Vector3(0,-0.52,-0.02),Vector3(0.18,0.19,0.20),leather)
		ColorBatch.combine(arm)
		arm.set_meta("animated_part",true)
		if side<0:
			left_leg=leg
			left_arm=arm
		else:
			right_leg=leg
			right_arm=arm
	ColorBatch.combine(torso)

func animate(delta: float, speed: float, grounded: bool, dodge_fraction: float) -> void:
	phase += delta*speed*2.4
	var stride := minf(speed/8.0,1.0)*0.72 if grounded else 0.18
	left_leg.rotation.x = sin(phase)*stride
	right_leg.rotation.x = -sin(phase)*stride
	left_arm.rotation.x = -sin(phase)*stride*0.75
	right_arm.rotation.x = sin(phase)*stride*0.75
	torso.position.y = 0.94+absf(sin(phase))*stride*0.045
	rotation.x = -dodge_fraction*TAU if dodge_fraction>=0 else 0.0
	position = Vector3.UP*0.94-basis*(Vector3.UP*0.94)
