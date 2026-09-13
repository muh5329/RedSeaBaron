class_name PlayerCombat
extends Node3D
signal swing_started
signal rifle_fired
signal hit_confirmed
signal reload_finished
signal changed
signal enemy_defeated
var actor: PlayerController
var orbit: OrbitCamera
var config := WeaponConfig.new()
var health: HealthComponent
var enabled: bool = false
var weapon: String = "WRENCH"
var state: String = "READY"
var ammunition: int = 5
var reserve: int = 40
var aiming: bool = false
var target: EnemyActor
var clock: float = 0
var shot_cooldown: float = 0
var combo: int = 0
var combo_window: float = 0
var heavy: bool = false
var swing_targets: Dictionary = {}
var swing_count: int = 0
var shot_count: int = 0
var death_clock: float = 0
var wrench: Node3D
var rifle: WeaponVisual
var tracer: MeshInstance3D
var tracer_time: float = 0
var flash: MeshInstance3D
var target_marker: Label3D
var last_hit: String = ""
var queued_attack: bool = false
var queued_heavy: bool = false
var buffer_seconds: float = 0
var block_until_released: bool = false
var action_blocked: Callable

func _ready() -> void:
	health = HealthComponent.new()
	health.faction = &"player"
	actor.add_child(health)
	health.died.connect(func(): death_clock = 2.0; cancel(); actor.set_controls(false))
	actor.recovered.connect(func(): health.restore(); cancel(); target = null)
	actor.dodged.connect(cancel)
	_build_weapons()

func _build_weapons() -> void:
	var visual_wrench := WeaponVisual.new()
	wrench = visual_wrench
	actor.visual.right_arm.add_child(wrench)
	wrench.position = Vector3(0,-0.5,-0.12)
	rifle = WeaponVisual.new()
	rifle.kind = "RIFLE"
	actor.visual.torso.add_child(rifle)
	flash = rifle.flash
	rifle.visible = false
	target_marker = BlockoutKit.label(self, "[   ]", Vector3.ZERO, 56)
	target_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	target_marker.visible = false
	var line := BoxMesh.new()
	line.size = Vector3(0.025, 0.025, 1)
	tracer = BlockoutKit.mesh(self, line, Vector3.ZERO, Color("ffdd8a"))
	tracer.visible = false

func actions_blocked() -> bool:
	return action_blocked.is_valid() and action_blocked.call()

func can_act() -> bool:
	return enabled and actor.input_enabled and health.current > 0 and actor.dodge_remaining <= 0 and not actions_blocked()

func cancel() -> void:
	queued_attack = false
	buffer_seconds = 0
	if is_instance_valid(health):
		health.invulnerable = false
	state = "READY"
	clock = 0
	aiming = false
	swing_targets.clear()
	actor.speed_multiplier = 1.0
	orbit.lateral_offset = 0
	orbit.camera.fov = 64

func set_enabled(value: bool) -> void:
	enabled = value
	if not value:
		cancel()

func equip(next: String) -> void:
	if not can_act() or state != "READY":
		return
	_apply_weapon(next)

func _apply_weapon(next: String) -> void:
	weapon = next
	wrench.visible = weapon == "WRENCH"
	rifle.visible = weapon == "RIFLE"
	combo = 0

func restore_equipment(next: String, magazine: int, remaining: int) -> void:
	cancel()
	_apply_weapon(next)
	ammunition = magazine
	reserve = remaining
	shot_cooldown = 0
	block_until_released = true

func start_melee(is_heavy: bool = false) -> bool:
	if not can_act() or weapon != "WRENCH" or state != "READY" or not actor.is_on_floor():
		return false
	if not actor.spend_stamina(config.heavy_cost if is_heavy else config.light_cost):
		return false
	heavy = is_heavy
	combo = (combo % 3) + 1 if combo_window > 0 else 1
	combo_window = 1.4
	clock = 0
	state = "WINDUP"
	swing_targets.clear()
	swing_count += 1
	swing_started.emit()
	return true

func request_melee(is_heavy: bool = false) -> bool:
	if start_melee(is_heavy): return true
	if can_act() and weapon=="WRENCH" and state=="RECOVERY":
		queued_attack = true
		queued_heavy = is_heavy
		buffer_seconds = 0.28
		return true
	return false

func toggle_lock() -> void:
	if not can_act():
		return
	if is_instance_valid(target):
		target = null
		return
	var best := INF
	for enemy in get_tree().get_nodes_in_group("hostiles"):
		if not enemy is EnemyActor or enemy.health.current <= 0:
			continue
		var distance: float = enemy.position.distance_to(actor.position)
		if distance < 24 and distance < best and _clear_to(enemy):
			target = enemy
			best = distance

func _clear_to(enemy: EnemyActor) -> bool:
	return DamageSystem.clear_line(actor.get_world_3d(), actor.position + Vector3.UP * 1.2, enemy.position + Vector3.UP)

func _melee_hit() -> void:
	var forward := Vector3.FORWARD.rotated(Vector3.UP, actor.visual.rotation.y)
	for enemy in get_tree().get_nodes_in_group("hostiles"):
		if not enemy is EnemyActor or enemy.health.current <= 0 or swing_targets.has(enemy.get_instance_id()):
			continue
		var difference: Vector3 = enemy.position - actor.position
		var flat := Vector3(difference.x, 0, difference.z)
		if flat.length() <= config.melee_range and absf(difference.y) < 1.6 and forward.dot(flat.normalized()) > 0.25 and _clear_to(enemy):
			swing_targets[enemy.get_instance_id()] = true
			if DamageSystem.apply(enemy, config.heavy_damage if heavy else config.light_damage + (combo - 1) * 3, &"player"):
				hit_confirmed.emit()
				last_hit = "Wrench hit · %s" % enemy.kind
				if enemy.health.current <= 0:
					enemy_defeated.emit()

func reload_weapon() -> bool:
	if not can_act() or weapon != "RIFLE" or state != "READY" or ammunition >= config.magazine_size or reserve <= 0:
		return false
	state = "RELOAD"
	clock = 0
	return true

func fire() -> bool:
	if not can_act() or weapon != "RIFLE" or state != "READY" or shot_cooldown > 0 or ammunition <= 0:
		return false
	ammunition -= 1
	shot_count += 1
	rifle_fired.emit()
	shot_cooldown = config.shot_interval
	var from := orbit.camera.global_position
	var direction := -orbit.camera.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * 120, 5)
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	var end: Vector3 = hit.position if not hit.is_empty() else from + direction * 120
	var muzzle := actor.position + Vector3.UP * 1.35
	# A second ray from the actor prevents shooting through nearby cover from camera clearance.
	var cover := actor.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(muzzle, end, 1))
	if not cover.is_empty():
		end = cover.position
	elif not hit.is_empty() and DamageSystem.apply(hit.collider, config.rifle_damage, &"player"):
		hit_confirmed.emit()
		last_hit = "Rifle hit"
		var victim := DamageSystem.health_of(hit.collider)
		if victim.current <= 0:
			enemy_defeated.emit()
	var length := muzzle.distance_to(end)
	if length > 0.05:
		tracer.global_position = (muzzle + end) * 0.5
		tracer.look_at(end)
		tracer.scale = Vector3(1, 1, length)
	tracer_time = 0.07
	tracer.visible = true
	flash.visible = true
	orbit.pitch = clampf(orbit.pitch + 0.024, -1.1, 0.35)
	return true

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	if health.current <= 0:
		death_clock -= delta
		if death_clock <= 0:
			actor.recover()
			actor.set_controls(true)
		return
	health.invulnerable = actor.dodge_remaining > 0.14 and actor.dodge_remaining < 0.44
	buffer_seconds = maxf(0,buffer_seconds-delta)
	if buffer_seconds<=0: queued_attack = false
	shot_cooldown = maxf(0, shot_cooldown - delta)
	combo_window = maxf(0, combo_window - delta)
	tracer_time = maxf(0, tracer_time - delta)
	tracer.visible = tracer_time > 0
	flash.visible = tracer_time > 0
	if actions_blocked():
		cancel()
		# Panels are live: dodge timing and movement still belong to the player.
		health.invulnerable = actor.dodge_remaining > 0.14 and actor.dodge_remaining < 0.44
		block_until_released = true
		target_marker.visible = false
		if weapon=="RIFLE": rifle.present_rifle(actor.visual,-0.08,false,0)
		else: actor.visual.right_arm.rotation.z = 0
		return
	if Input.is_action_just_pressed("equip_wrench"):
		equip("WRENCH")
	if Input.is_action_just_pressed("equip_rifle"):
		equip("RIFLE")
	if Input.is_action_just_pressed("lock_target"):
		toggle_lock()
	if Input.is_action_just_pressed("reload"):
		reload_weapon()
	aiming = can_act() and weapon == "RIFLE" and Input.is_action_pressed("aim")
	if block_until_released and not Input.is_action_pressed("attack"):
		block_until_released = false
	if Input.is_action_just_pressed("attack") and not block_until_released:
		if weapon == "WRENCH":
			request_melee(false)
		else:
			fire()
	if Input.is_action_just_pressed("heavy_attack"):
		request_melee(true)
	if is_instance_valid(target):
		if target.health.current <= 0 or actor.position.distance_to(target.position) > 30 or not _clear_to(target):
			target = null
	orbit.lateral_offset = 0.7 if weapon == "RIFLE" or is_instance_valid(target) else 0.0
	if is_instance_valid(target):
		var difference := target.position - actor.position - Vector3.RIGHT.rotated(Vector3.UP, orbit.yaw) * orbit.effective_lateral_offset
		orbit.yaw = lerp_angle(orbit.yaw, atan2(-difference.x, -difference.z), delta * 8)
		orbit.pitch = lerpf(orbit.pitch, clampf(atan2(difference.y - 0.55, Vector2(difference.x, difference.z).length()), -1.1, 0.35), delta * 7)
		var facing := target.position-actor.position
		actor.visual.rotation.y = atan2(-facing.x,-facing.z) if weapon=="WRENCH" else orbit.yaw
	elif aiming:
		actor.visual.rotation.y = orbit.yaw
	target_marker.visible = is_instance_valid(target)
	if is_instance_valid(target):
		target_marker.global_position = target.global_position + Vector3.UP * 1.2
	orbit.camera.fov = lerpf(orbit.camera.fov, 48.0 if aiming else 64.0, delta * 10)
	actor.speed_multiplier = 0.45 if aiming else (0.35 if state in ["WINDUP", "ACTIVE"] else 1.0)
	clock += delta
	if state == "WINDUP" and clock > (0.38 if heavy else 0.15):
		state = "ACTIVE"
		clock = 0
	if state == "ACTIVE":
		_melee_hit()
		if clock > 0.15:
			state = "RECOVERY"
			clock = 0
	if state == "RECOVERY" and clock > (0.42 if heavy else 0.22):
		state = "READY"
	if state=="READY" and queued_attack:
		queued_attack = false
		start_melee(queued_heavy)
	if state == "RELOAD" and clock >= config.reload_seconds:
		var amount := mini(config.magazine_size - ammunition, reserve)
		ammunition += amount
		reserve -= amount
		state = "READY"
		reload_finished.emit()
	if weapon == "RIFLE":
		rifle.present_rifle(actor.visual,orbit.pitch if aiming or is_instance_valid(target) else -0.08,state=="RELOAD",clock)
	elif weapon == "WRENCH" and state != "READY":
		actor.visual.right_arm.rotation.x = -1.4 if state == "WINDUP" else 0.7
		actor.visual.right_arm.rotation.z = -0.8 if state == "ACTIVE" else 0
	else:
		actor.visual.right_arm.rotation.z = 0
