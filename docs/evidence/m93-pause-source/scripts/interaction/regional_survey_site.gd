class_name RegionalSurveySite
extends SurveySite
## Repeatable regional checkpoint; its active state derives from the saved position.
var actor: PlayerController
var combat: PlayerCombat
var timer: float = 0
var active_checkpoint: bool = false

func recovery_position() -> Vector3:
	var at := global_position+Vector3(0,0,1.5)
	at.y = CoastalRegion.height_at(at.x,at.z)+0.2
	return at

func prompt_action() -> String:
	return "Rest at " if actor.spawn_position.distance_to(recovery_position())<0.1 else "Set checkpoint: "

func can_interact(visitor: Node3D) -> bool:
	return visitor==actor and visible and actor.input_enabled and actor.is_on_floor() and actor.velocity.length()<1 and actor.dodge_remaining<=0 and combat.health.current>0 and combat.state=="READY" and super.can_interact(visitor)

func interact(visitor: Node3D) -> bool:
	# The composition root owns checkpoint assignment for both local and regional sites.
	return can_interact(visitor)

func _process(delta: float) -> void:
	timer -= delta
	if timer>0: return
	timer = 0.25
	visible = actor.global_position.distance_to(global_position)<150
	var active := actor.spawn_position.distance_to(recovery_position())<0.1
	if active!=active_checkpoint:
		active_checkpoint = active
		marker.material_override = BlockoutKit.material(Color("80b5a0") if active else Color("e9bd71"))
