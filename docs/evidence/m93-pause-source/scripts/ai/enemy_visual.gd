class_name EnemyVisual
extends Node3D
## Distinct human and quadruped silhouettes, with shared locomotion/attack joints.
var kind: String = "Raider"
var arm: Node3D
var gait: Array[Node3D] = []
const LEATHER := Color("514a3b")
const SKIN := Color("b99d7d")

func _ready() -> void:
	if kind=="Cinder beast": _beast()
	else: _raider()
	ColorBatch.combine(self)

func _joint(at: Vector3, length: float, radius: float, color: Color, paw: bool = false) -> Node3D:
	var joint := Node3D.new()
	joint.position = at
	add_child(joint)
	BlockoutKit.cylinder(joint,Vector3(0,-length*0.5,0),radius,length,color,radius*0.85,8)
	BlockoutKit.sphere(joint,Vector3(0,-length,0),Vector3(radius*2.1,radius*1.8,radius*2.1),color)
	if paw:
		BlockoutKit.box(joint,Vector3(0,-length-0.065,-0.055),Vector3(radius*2.3,0.13,radius*3.0),LEATHER)
	return joint

func _finish_joint(joint: Node3D) -> void:
	ColorBatch.combine(joint)
	joint.set_meta("animated_part",true)

func _raider() -> void:
	BlockoutKit.cylinder(self,Vector3(0,1.1,0),0.34,0.66,Color("77664d"),0.27,8)
	BlockoutKit.box(self,Vector3(0,0.78,0),Vector3(0.48,0.15,0.36),LEATHER)
	BlockoutKit.cylinder(self,Vector3(0,1.49,0),0.11,0.17,SKIN,-1,8)
	BlockoutKit.sphere(self,Vector3(0,1.68,0),Vector3(0.49,0.5,0.49),SKIN)
	BlockoutKit.sphere(self,Vector3(0,1.83,0.035),Vector3(0.53,0.23,0.51),Color("433d32"))
	BlockoutKit.box(self,Vector3(0,1.60,-0.13),Vector3(0.46,0.15,0.25),LEATHER)
	for x in [-0.105,0.105]: BlockoutKit.box(self,Vector3(x,1.74,-0.224),Vector3(0.075,0.055,0.03),Color("332f28"))
	BlockoutKit.cylinder(self,Vector3(0,1.43,0),0.31,0.095,Color("a45b40"),-1,8)
	BlockoutKit.box(self,Vector3(-0.15,1.25,-0.26),Vector3(0.14,0.4,0.05),Color("a45b40"))
	BlockoutKit.box(self,Vector3(0.13,1.13,0.29),Vector3(0.33,0.4,0.18),LEATHER)
	for side in [-1.0,1.0]:
		var leg := _joint(Vector3(side*0.18,0.77,0),0.58,0.12,Color("494b40"),true)
		_finish_joint(leg)
		leg.set_meta("phase_offset",0.0 if side<0 else PI)
		gait.append(leg)
		var hand := _joint(Vector3(side*0.40,1.38,0),0.57,0.095,SKIN)
		BlockoutKit.cylinder(hand,Vector3(0,-0.13,0),0.135,0.26,Color("77664d"),-1,8)
		if side>0:
			arm = hand
			BlockoutKit.box(hand,Vector3(0,-0.58,-0.25),Vector3(0.10,0.13,0.66),Color("575d55"))
			BlockoutKit.box(hand,Vector3(0,-0.58,-0.57),Vector3(0.30,0.24,0.15),Color("6e746a"))
		hand.set_meta("phase_offset",PI if side<0 else 0.0)
		gait.append(hand)
		_finish_joint(hand)

func _beast() -> void:
	var hide := Color("5b6454")
	BlockoutKit.sphere(self,Vector3(0,0.88,0.08),Vector3(0.91,0.75,1.10),hide)
	BlockoutKit.sphere(self,Vector3(0,0.96,-0.44),Vector3(0.66,0.60,0.60),hide)
	BlockoutKit.box(self,Vector3(0,0.83,-0.69),Vector3(0.44,0.20,0.22),LEATHER)
	for x in [-0.22,0.22]:
		BlockoutKit.sphere(self,Vector3(x,1.075,-0.663),Vector3(0.10,0.08,0.05),Color("ed9b48"))
		var horn := BlockoutKit.cylinder(self,Vector3(x,1.37,-0.46),0.11,0.46,Color("cfc6a4"),0.015,6)
		horn.rotation.z = -signf(x)*0.3
		BlockoutKit.cylinder(self,Vector3(x*0.65,0.76,-0.78),0.05,0.18,Color("d9d0ac"),0.01,5)
	for z in [-0.12,0.15,0.4]:
		BlockoutKit.cylinder(self,Vector3(0,1.24,z),0.14,0.28,Color("a7673e"),0.01,5)
	for x in [-0.32,0.32]:
		for z in [-0.32,0.34]:
			var leg := _joint(Vector3(x,0.60,z),0.44,0.105,hide,true)
			for claw in [-0.065,0.065]:
				BlockoutKit.box(leg,Vector3(claw,-0.49,-0.21),Vector3(0.04,0.055,0.12),Color("cfc6a4"))
			if x>0 and z<0: arm=leg
			leg.set_meta("phase_offset",PI if (x>0)!=(z>0) else 0.0)
			gait.append(leg)
			_finish_joint(leg)
	var tail := BlockoutKit.cylinder(self,Vector3(0,0.8,0.71),0.08,0.44,hide,0.025,8)
	tail.rotation.x = PI/2-0.35

func animate_walk(delta: float, phase: float, speed: float, attacking: bool) -> void:
	for joint in gait:
		if attacking and joint==arm: continue
		var target := sin(phase+float(joint.get_meta("phase_offset",0)))*0.45*clampf(speed/3,0,1)
		joint.rotation.x = lerpf(joint.rotation.x,target,1-exp(-delta*12))
