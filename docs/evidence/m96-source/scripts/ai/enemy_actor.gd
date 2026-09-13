class_name EnemyActor
extends CharacterBody3D
var kind: String = "Raider"
var target: PlayerController
var home := Vector3.ZERO
var move_speed: float = 3.0
var desired_velocity := Vector3.ZERO
var health: HealthComponent
var brain: CombatBrain
var model: EnemyVisual
var state_label: Label3D
var health_label: Label3D
var hit_flash: float = 0
var death_time: float = 0
var simulation_enabled: bool = true
var arm: Node3D
var attack_cue: EnemyAttackCue
var phase: float = 0

func _ready() -> void:
	add_to_group("hostiles")
	collision_layer = 4
	collision_mask = 3
	floor_snap_length = 0.5
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.4
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	health = HealthComponent.new()
	health.faction = &"hostile"
	health.maximum = 90 if kind == "Raider" else 140
	add_child(health)
	model = EnemyVisual.new()
	model.kind = kind
	add_child(model)
	arm = model.arm
	if kind=="Cinder beast": move_speed=2.6
	state_label = BlockoutKit.label(self, kind + " · Idle", Vector3(0, 2.6, 0), 23)
	state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	health_label = BlockoutKit.label(self, "", Vector3(0, 2.3, 0), 19)
	health_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	brain = CombatBrain.new()
	brain.actor = self
	brain.target = target
	if kind != "Raider":
		brain.damage = 19
	add_child(brain)
	attack_cue = EnemyAttackCue.new()
	add_child(attack_cue)
	attack_cue.build(brain.attack_range+0.25,brain.attack_arc_degrees)
	health.damaged.connect(func(_amount): hit_flash = 0.22; brain.react_to_hit())
	health.died.connect(func():
		brain.die()
		set_collision_layer_value(3, false)
		death_time = 0.01
	)

func face(point: Vector3) -> void:
	var difference := point - position
	if Vector2(difference.x, difference.z).length() > 0.1:
		model.rotation.y = atan2(-difference.x, -difference.z)

func _physics_process(delta: float) -> void:
	if not simulation_enabled:
		return
	attack_cue.present(brain,model.rotation.y)
	hit_flash = maxf(0, hit_flash - delta)
	health_label.text = "%d / %d" % [health.current, health.maximum]
	health_label.modulate = Color("ffb17b") if hit_flash > 0 else Color("f5e4bd")
	if health.current <= 0:
		death_time += delta
		model.rotation.z = lerpf(model.rotation.z, PI / 2, delta * 6)
		if death_time > 15:
			queue_free()
		return
	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	velocity.y -= 24 * delta
	move_and_slide()
	if desired_velocity.length() > 0.1:
		face(position + desired_velocity)
	phase += delta * desired_velocity.length() * 2
	model.position.y = absf(sin(phase)) * 0.05
	model.animate_walk(delta,phase,desired_velocity.length(),brain.machine.current==&"Attack")
	if brain.machine.current==&"Attack":
		var time := brain.machine.elapsed
		if time<brain.windup_seconds:
			arm.rotation.x = lerpf(-0.4,-1.6,clampf(time/brain.windup_seconds,0,1))
		else:
			arm.rotation.x = lerpf(0.8,0,clampf((time-brain.windup_seconds)/(brain.recovery_seconds-brain.windup_seconds),0,1))

func set_simulation(value: bool) -> void:
	simulation_enabled = value
	brain.enabled = value
	if not value:
		desired_velocity = Vector3.ZERO
