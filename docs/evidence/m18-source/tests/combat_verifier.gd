extends Node
var game: Node3D
var combat: PlayerCombat
var player: PlayerController
var enemies: Array[EnemyActor] = []
var checks: Array[Dictionary] = []
var elapsed_start: int

func frames(n: int) -> void:
	for i in range(n):
		await get_tree().physics_frame

func release() -> void:
	for action in InputMap.get_actions():
		Input.action_release(action)

func check(test: String, passed: bool, detail: String = "") -> void:
	checks.append({"test": test, "passed": passed, "detail": detail})
	print("RSB_COMBAT | ", "PASS" if passed else "FAIL", " | ", test, " | ", detail)
	game.hud.verified_label.visible = true
	game.hud.verified_label.text = "COMBAT CHECKS %d / %d\n%s" % [checks.filter(func(c): return c.passed).size(), checks.size(), test]

func fixture(distance: float = 2.0, kind: String = "Raider") -> EnemyActor:
	release()
	combat.cancel()
	combat.target = null
	combat.health.restore()
	player.stamina = 100
	player.global_position = Vector3(0, CoastalRegion.height_at(0, 40) + 0.12, 40)
	player.velocity = Vector3.ZERO
	player.dodge_remaining = 0
	player.visual.rotation = Vector3.ZERO
	game.orbit.yaw = 0
	game.orbit.pitch = -0.1
	game.orbit.snap()
	for old in enemies:
		if is_instance_valid(old):
			old.queue_free()
	enemies.clear()
	await frames(15)
	var enemy := EnemyActor.new()
	enemy.kind = kind
	enemy.target = player
	enemy.position = Vector3(0, CoastalRegion.height_at(0, 40-distance) + 0.1, 40-distance)
	enemy.home = enemy.position
	game.add_child(enemy)
	enemy.brain.enabled = false
	enemies.append(enemy)
	await frames(15)
	return enemy

func run(owner_game: Node3D) -> void:
	game = owner_game
	combat = game.combat
	player = game.player
	elapsed_start = Time.get_ticks_msec()
	var saved_position := player.position
	var saved_spawn := player.spawn_position
	var saved_yaw: float = game.orbit.yaw
	var saved_pitch: float = game.orbit.pitch
	var saved_weapon := combat.weapon
	var saved_ammo := combat.ammunition
	var saved_reserve := combat.reserve
	for camp_enemy in game.enemies:
		if is_instance_valid(camp_enemy):
			camp_enemy.set_simulation(false)
	game.orbit.input_enabled = false
	var enemy := await fixture()
	combat.equip("WRENCH")
	combat.combo_window = 0
	Input.action_press("attack")
	await frames(6)
	var visible_swing := absf(player.visual.right_arm.rotation.x) > 0.6
	await frames(44)
	Input.action_release("attack")
	check("Light swing one hit only", enemy.health.current == 64, "health=%.0f; expected=64" % enemy.health.current)
	check("Melee costs stamina and animates", player.stamina < 100 and visible_swing and combat.wrench.visible)
	combat.combo_window = 1
	var previous := enemy.health.current
	combat.start_melee()
	await frames(40)
	check("Combo advances damage", combat.combo == 2 and enemy.health.current == previous-29, "combo=%d; health=%.0f" % [combat.combo, enemy.health.current])
	player.stamina = 100
	combat.start_melee(true)
	await frames(70)
	check("Heavy hit kills and disables hurt body", enemy.health.current == 0 and enemy.collision_layer == 0 and enemy.brain.machine.current == &"Dead")
	var dead_hp := enemy.health.current
	check("Dead actors reject damage", not enemy.health.take_damage(99, &"player") and enemy.health.current == dead_hp)
	enemy = await fixture()
	Input.action_press("move_forward")
	await frames(60)
	release()
	check("Player cannot walk through enemy body", player.position.distance_to(enemy.position) > 0.7)
	enemy = await fixture()
	Input.action_press("dodge")
	await frames(8)
	release()
	var before_hp := combat.health.current
	check("Dodge window rejects incoming damage", not combat.health.take_damage(10, &"hostile") and combat.health.current == before_hp)
	await frames(40)
	check("Dodge immunity expires", combat.health.take_damage(10, &"hostile") and combat.health.current == before_hp - 10)
	enemy = await fixture()
	check("Faction filter", not combat.health.take_damage(20, &"player") and combat.health.current == 100)
	player.visual.rotation.y = PI
	combat.start_melee()
	await frames(45)
	check("Wrench cannot hit behind actor", enemy.health.current == enemy.health.maximum)
	enemy = await fixture(4)
	combat.start_melee(true)
	await frames(70)
	check("Wrench range bound", enemy.health.current == enemy.health.maximum)
	enemy = await fixture()
	var wall := BlockoutKit.box(game, player.position + Vector3(0, 1.5, -1), Vector3(4, 3, 0.3), Color("8a8270"), true)
	await frames(3)
	combat.start_melee()
	await frames(45)
	check("Melee respects world occlusion", enemy.health.current == enemy.health.maximum)
	wall.queue_free()
	await frames(3)
	combat.target = null
	combat.toggle_lock()
	check("Lock selects live enemy", combat.target == enemy)
	enemy.health.take_damage(999, &"player")
	await frames(4)
	check("Lock drops dead target", combat.target == null)
	enemy = await fixture(10)
	combat.equip("RIFLE")
	combat.ammunition = 5
	combat.shot_cooldown = 0
	combat.toggle_lock()
	await frames(90)
	var yaw_before: float = game.orbit.pitch
	Input.action_press("aim")
	await frames(20)
	check("Rifle aim narrows camera", combat.aiming and game.orbit.camera.fov < 53)
	Input.action_press("attack")
	await frames(2)
	Input.action_release("attack")
	check("Hitscan deals damage and consumes round", enemy.health.current == 42 and combat.ammunition == 4, "hp=%.0f; ammo=%d" % [enemy.health.current, combat.ammunition])
	check("Shot presents recoil and flash", combat.shot_count > 0 and combat.tracer.visible and game.orbit.pitch > yaw_before)
	var count := combat.shot_count
	combat.fire()
	check("Shot rate guard", combat.shot_count == count)
	release()
	combat.ammunition = 0
	combat.shot_cooldown = 0
	check("Empty rifle cannot fire", not combat.fire() and combat.ammunition == 0)
	combat.reserve = 3
	combat.reload_weapon()
	await frames(110)
	check("Partial reload conserves ammo", combat.ammunition == 3 and combat.reserve == 0, "mag=%d; reserve=%d" % [combat.ammunition, combat.reserve])
	combat.ammunition = 1
	combat.reserve = 10
	combat.reload_weapon()
	Input.action_press("dodge")
	await frames(2)
	release()
	await frames(115)
	check("Dodge cancels reload without minting ammo", combat.ammunition == 1 and combat.reserve == 10 and combat.state == "READY")
	combat.reload_weapon()
	game._set_paused(true)
	check("Paused fire and attack reject", not combat.fire() and not combat.start_melee())
	await frames(110)
	check("Pause cancels reload transaction", combat.ammunition == 1 and combat.reserve == 10)
	game._set_paused(false)
	for camp_enemy in game.enemies:
		if is_instance_valid(camp_enemy): camp_enemy.set_simulation(false)
	game.orbit.input_enabled = false
	enemy = await fixture(10)
	combat.equip("RIFLE")
	combat.ammunition = 5
	combat.shot_cooldown = 0
	combat.toggle_lock()
	await frames(90)
	wall = BlockoutKit.box(game, player.position + Vector3(0, 1.5, -2.8), Vector3(6, 4, 0.3), Color("8a8270"), true)
	await frames(4)
	combat.fire()
	check("Rifle and lock respect cover", enemy.health.current == enemy.health.maximum and combat.target == null)
	wall.queue_free()
	await frames(3)
	for kind in ["Raider", "Cinder beast"]:
		enemy = await fixture(8, kind)
		enemy.brain.enabled = true
		await frames(20)
		check(kind + " detects and pursues", enemy.brain.machine.current == &"Pursue")
		await frames(210)
		check(kind + " attacks player", combat.health.current < 100, "player hp=%.0f; state=%s" % [combat.health.current, enemy.brain.machine.current])
		enemy.health.take_damage(12, &"player")
		check(kind + " hit reaction", enemy.brain.machine.current == &"Hit")
		enemy.health.take_damage(999, &"player")
		check(kind + " dies", enemy.brain.machine.current == &"Dead")
	enemy = await fixture(2)
	combat.health.take_damage(999, &"hostile")
	check("Player death gates actions", not combat.can_act() and not player.input_enabled)
	await frames(130)
	check("Death recovers at checkpoint", combat.health.current == 100 and player.input_enabled and player.position.distance_to(player.spawn_position) < 1)
	for old in enemies:
		if is_instance_valid(old): old.queue_free()
	release()
	combat.cancel()
	combat.health.restore()
	combat.equip(saved_weapon)
	combat.ammunition = saved_ammo
	combat.reserve = saved_reserve
	combat.target = null
	player.position = saved_position
	player.spawn_position = saved_spawn
	player.velocity = Vector3.ZERO
	player.stamina = 100
	game.orbit.yaw = saved_yaw
	game.orbit.pitch = saved_pitch
	game.orbit.input_enabled = true
	game.orbit.snap()
	for camp_enemy in game.enemies:
		if is_instance_valid(camp_enemy): camp_enemy.set_simulation(true)
	var passed := checks.filter(func(c): return c.passed).size()
	var report := {"milestone":"02 combat", "passed":passed, "total":checks.size(), "platform":OS.get_name(), "elapsed_seconds":(Time.get_ticks_msec()-elapsed_start)/1000.0, "tests":checks}
	var json := JSON.stringify(report, "  ")
	print("RSB_COMBAT_REPORT ", JSON.stringify(report))
	game.hud.verified_label.text = "COMBAT: %d / %d PASSED" % [passed, checks.size()]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(()=>{let p=document.createElement('pre');p.id='combat-report';p.style='position:fixed;right:16px;top:16px;max-height:65vh;overflow:auto;max-width:460px;padding:16px;background:#152d29;color:#f4e3bb;z-index:10;font:12px monospace';p.textContent=%s;document.body.appendChild(p)})()" % JSON.stringify(json), true)
	else:
		var file := FileAccess.open("res://docs/evidence/combat-native-report.json", FileAccess.WRITE)
		file.store_string(json)
	if "--verify-combat" in OS.get_cmdline_user_args():
		get_tree().quit(0 if passed == checks.size() else 1)
