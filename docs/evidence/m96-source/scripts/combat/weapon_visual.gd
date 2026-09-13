class_name WeaponVisual
extends Node3D
## Geometry and hand attachment only. PlayerCombat owns all weapon rules.
var kind: String = "WRENCH"
var flash: MeshInstance3D
var bolt: Node3D
const GRIP := Vector3(0,-0.06,0.04)

func _ready() -> void:
	if kind=="RIFLE": _rifle()
	else: _wrench()

func _tube(at: Vector3, radius: float, length: float, color: Color) -> MeshInstance3D:
	var part := BlockoutKit.cylinder(self,at,radius,length,color,-1,10)
	part.rotation.x = PI/2
	return part

func _wrench() -> void:
	var steel := Color("919c94")
	_tube(Vector3(0,0,-0.31),0.038,0.69,steel)
	_tube(Vector3(0,0,-0.10),0.051,0.25,Color("514d42"))
	BlockoutKit.box(self,Vector3(0,0,-0.58),Vector3(0.28,0.10,0.16),steel)
	for side in [-1.0,1.0]:
		var jaw := BlockoutKit.box(self,Vector3(side*0.11,0,-0.70),Vector3(0.09,0.10,0.24),Color("b9c1b3"))
		jaw.rotation.y = side*0.12
	ColorBatch.combine(self)

func _rifle() -> void:
	var wood := Color("835837")
	var steel := Color("414d4e")
	BlockoutKit.box(self,Vector3(0,-0.025,0.20),Vector3(0.15,0.21,0.39),wood)
	BlockoutKit.box(self,Vector3(0,-0.025,0.40),Vector3(0.16,0.22,0.035),steel)
	BlockoutKit.box(self,Vector3(0,-0.015,-0.05),Vector3(0.11,0.12,0.25),wood)
	_tube(Vector3(0,-0.025,-0.39),0.067,0.62,wood)
	_tube(Vector3(0,0.035,-0.70),0.029,0.95,steel)
	BlockoutKit.box(self,Vector3(0,0.03,-0.20),Vector3(0.105,0.09,0.34),steel)
	BlockoutKit.box(self,Vector3(0,-0.105,-0.045),Vector3(0.06,0.04,0.12),steel)
	for z in [-0.36,-0.64]: _tube(Vector3(0,-0.018,z),0.071,0.035,steel)
	for z in [-0.14,-1.07]: BlockoutKit.box(self,Vector3(0,0.09,z),Vector3(0.028,0.065,0.04),steel)
	ColorBatch.combine(self)
	bolt = Node3D.new()
	add_child(bolt)
	var lever := BlockoutKit.cylinder(bolt,Vector3(0.09,0.04,-0.15),0.015,0.13,steel,-1,8)
	lever.rotation.z = PI/2
	BlockoutKit.sphere(bolt,Vector3(0.16,0.025,-0.15),Vector3.ONE*0.055,steel)
	ColorBatch.combine(bolt)
	bolt.set_meta("animated_part",true)
	flash = BlockoutKit.sphere(self,Vector3(0,0.035,-1.19),Vector3(0.20,0.20,0.4),Color("ffc564"))
	flash.visible = false

func present_rifle(avatar: PlayerVisual, pitch: float, reloading: bool, elapsed: float) -> void:
	avatar.right_arm.rotation = Vector3(1.05,0,-0.10)
	rotation = Vector3(pitch,0,0)
	var hand := avatar.right_arm.to_global(Vector3(0,-0.52,-0.02))
	position = get_parent().to_local(hand)-basis*GRIP
	bolt.position.z = maxf(0,sin(elapsed*4))*0.10 if reloading else 0.0
