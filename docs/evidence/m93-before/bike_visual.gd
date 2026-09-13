class_name BikeVisual
extends Node3D
var front_wheel: Node3D
var rear_wheel: Node3D
var front_steering: Node3D
var rider: PlayerVisual
var ground_roll: float = 0
const RED := Color("a84e3d")
const STEEL := Color("596460")
const BRASS := Color("b39358")
const DARK := Color("273435")
const LEATHER := Color("4e493a")

func _ready() -> void:
	front_steering = Node3D.new()
	front_steering.position = Vector3(0,0.48,-1)
	add_child(front_steering)
	front_wheel = _wheel(front_steering,Vector3.ZERO)
	rear_wheel = _wheel(self,Vector3(0,0.48,1))
	VehicleMesh.fender(front_steering,Vector3.ZERO,RED,-0.85,1.1)
	for x in [-0.22,0.22]:
		VehicleMesh.rod(front_steering,Vector3(x,0,0),Vector3(x,0.91,0.2),0.055,STEEL)
		VehicleMesh.rod(front_steering,Vector3(x,0.09,0.02),Vector3(x,0.53,0.12),0.075,BRASS)
	VehicleMesh.rod(front_steering,Vector3(-0.22,0.9,0.2),Vector3(0.22,0.9,0.2),0.065,DARK)
	VehicleMesh.rod(front_steering,Vector3(-0.52,1,0.12),Vector3(0.52,1,0.12),0.045,STEEL)
	for x in [-0.48,0.48]:
		VehicleMesh.rod(front_steering,Vector3(x-0.095,1,0.12),Vector3(x+0.095,1,0.12),0.065,LEATHER)
	var lamp := BlockoutKit.cylinder(front_steering,Vector3(0,0.79,-0.06),0.23,0.22,BRASS,-1,16)
	lamp.rotation.x = PI/2
	var glass := BlockoutKit.cylinder(front_steering,Vector3(0,0.79,-0.18),0.18,0.025,Color("edce90"),-1,16)
	glass.rotation.x = PI/2
	for x in [-0.09,0.09]: VehicleMesh.rod(front_steering,Vector3(x,0.64,-0.201),Vector3(x,0.94,-0.201),0.014,DARK)
	VehicleMesh.rod(front_steering,Vector3(-0.16,0.79,-0.202),Vector3(0.16,0.79,-0.202),0.014,DARK)
	# Steering and wheel rotation have independent pivots.
	front_wheel.set_meta("animated_part",true)
	StaticBatcher.combine(front_steering)
	front_steering.set_meta("animated_part",true)
	rear_wheel.set_meta("animated_part",true)
	for side in [-1.0,1.0]:
		var x: float = side*0.25
		var neck := Vector3(x,1.26,-0.72)
		var lower := Vector3(x,0.46,-0.48)
		var pivot := Vector3(x,0.58,0.38)
		var seat_base := Vector3(x,1.13,0.55)
		for ends in [[neck,lower],[lower,pivot],[pivot,neck],[pivot,seat_base],[seat_base,neck],[pivot,Vector3(x,0.48,1.0)]]:
			VehicleMesh.rod(self,ends[0],ends[1],0.044,RED)
		VehicleMesh.rod(self,Vector3(x,0.5,1),Vector3(x,1.14,0.58),0.065,STEEL)
		for j in range(7):
			var coil := BlockoutKit.cylinder(self,Vector3(x,0.65+j*0.049,0.90-j*0.032),0.083,0.025,BRASS,-1,8)
			coil.rotation.x = -0.57
		VehicleMesh.rod(self,Vector3(side*0.35,0.52,0.02),Vector3(side*0.35,0.52,0.44),0.043,DARK)
	var fuel_tank := VehicleMesh.tank(self,Vector3(0,1.11,-0.32),RED)
	fuel_tank.name = "FuelTank"
	BlockoutKit.cylinder(self,Vector3(0,1.33,-0.44),0.074,0.035,BRASS,-1,12)
	BlockoutKit.box(self,Vector3(0,1.22,0.45),Vector3(0.54,0.15,0.84),LEATHER)
	for z in [0.16,0.36,0.56,0.76]: BlockoutKit.box(self,Vector3(0,1.299,z),Vector3(0.47,0.012,0.016),Color("87735a"))
	VehicleMesh.fender(self,Vector3(0,0.48,1),RED,-0.9,1.3)
	# Finned cylinder block, exposed crankcase and bolts.
	BlockoutKit.box(self,Vector3(0,0.77,-0.22),Vector3(0.39,0.32,0.48),DARK)
	for y in range(6): BlockoutKit.box(self,Vector3(0,0.69+y*0.052,-0.22),Vector3(0.48,0.025,0.53),STEEL)
	for x in [-0.255,0.255]:
		var crank := BlockoutKit.cylinder(self,Vector3(x,0.62,0.13),0.225,0.12,STEEL,-1,12)
		crank.rotation.z = PI/2
		var cover := BlockoutKit.cylinder(self,Vector3(x*1.25,0.62,0.13),0.15,0.03,BRASS,-1,12)
		cover.rotation.z = PI/2
		for a in range(6):
			var angle := a*TAU/6
			var bolt := BlockoutKit.cylinder(self,Vector3(x*1.27,0.62+cos(angle)*0.19,0.13+sin(angle)*0.19),0.022,0.025,DARK,-1,6)
			bolt.rotation.z = PI/2
	VehicleMesh.rod(self,Vector3(0.28,0.8,-0.4),Vector3(0.36,0.41,-0.28),0.065,BRASS)
	VehicleMesh.rod(self,Vector3(0.36,0.41,-0.28),Vector3(0.36,0.43,0.6),0.065,BRASS)
	VehicleMesh.rod(self,Vector3(0.36,0.43,0.6),Vector3(0.36,0.61,1.17),0.105,STEEL)
	BlockoutKit.box(self,Vector3(0,0.4,-0.2),Vector3(0.47,0.08,0.75),BRASS)
	for x in [-0.26,0.26]:
		VehicleMesh.rod(self,Vector3(x,1.13,0.7),Vector3(x,1.28,1.27),0.027,BRASS)
		VehicleMesh.rod(self,Vector3(x,1.28,0.77),Vector3(x,1.28,1.3),0.027,BRASS)
	for z in [0.82,1.02,1.25]: VehicleMesh.rod(self,Vector3(-0.26,1.28,z),Vector3(0.26,1.28,z),0.027,BRASS)
	BlockoutKit.box(self,Vector3(0,0.98,1.39),Vector3(0.16,0.12,0.04),Color("d96747"))
	StaticBatcher.combine(self)
	rider = PlayerVisual.new()
	rider.position = Vector3(0,0.37,0.08)
	rider.rotation.x = -0.14
	add_child(rider)
	rider.pose_riding()
	rider.visible = false

func _wheel(parent: Node3D, at: Vector3) -> Node3D:
	return VehicleMesh.wheel(parent,at,0.48,0.22,DARK,STEEL,BRASS)

func animate_vehicle(delta: float, speed: float, steering: float) -> void:
	front_steering.rotation.y = -steering*0.32
	front_wheel.rotation.x = fmod(front_wheel.rotation.x-speed*delta/0.48,TAU)
	rear_wheel.rotation.x = fmod(rear_wheel.rotation.x-speed*delta/0.48,TAU)
	rotation.z = lerpf(rotation.z,ground_roll-steering*clampf(absf(speed)/30,0,0.3),1-exp(-delta*7))
