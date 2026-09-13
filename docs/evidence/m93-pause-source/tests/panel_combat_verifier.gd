extends "res://tests/ui_verifier.gd"
var combat: PlayerCombat

func prepare(next_weapon: String = "RIFLE") -> void:
	release()
	game.logistics.panel.visible = false
	game.workers.panel.visible = false
	game._set_paused(false)
	game.world.enabled = false
	combat.cancel()
	combat._apply_weapon(next_weapon)
	combat.ammunition = 5
	combat.reserve = 40
	combat.shot_cooldown = 0
	combat.block_until_released = false
	player.position = Vector3(-20,CoastalRegion.height_at(-20,80)+0.1,80)
	player.velocity = Vector3.ZERO
	player.dodge_remaining = 0
	player.stamina = 100
	await frames(10)

func panel_key(code: Key) -> void:
	await key(code)
	# Panel visibility runs on idle frames; native shader warmup can batch physics ticks.
	await get_tree().process_frame
	await frames(2)

func click_panel(panel: Control) -> void:
	var point := get_viewport().get_final_transform()*panel.get_global_rect().get_center()
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = down
		Input.parse_input_event(event)
		await frames(2)

func together(panel_key: Key) -> void:
	for code in [panel_key,KEY_F]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = true
		Input.parse_input_event(event)
	await frames(2)
	for code in [panel_key,KEY_F]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		Input.parse_input_event(event)
	await frames(2)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	combat = game.combat
	var started := Time.get_ticks_msec()
	await prepare()
	await panel_key(KEY_B)
	await click_panel(game.logistics.panel)
	check("Cargo panel clicks cannot spend a rifle round",game.logistics.panel.visible and combat.ammunition==5,"panel=%s ammo=%d gate=%s pending=%s"%[game.logistics.panel.visible,combat.ammunition,combat.actions_blocked(),game.logistics.pending_panel_toggle])
	await prepare()
	await panel_key(KEY_N)
	await click_panel(game.workers.panel)
	check("Worker panel clicks cannot fire into the world",game.workers.panel.visible and combat.ammunition==5)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		await frames(16)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/panel-combat-native.jpg")
	await frames(45)
	var ammo := combat.ammunition
	await press("attack")
	check("Open orders reject keyboard attacks",combat.ammunition==ammo)
	combat.ammunition = 3
	await press("reload")
	check("Open orders reject starting a reload",combat.state=="READY")
	combat.cancel()
	await press("equip_wrench")
	check("Open orders cannot change weapon underneath the panel",combat.weapon=="RIFLE")
	await prepare("WRENCH")
	await panel_key(KEY_B)
	var swings := combat.swing_count
	await press("heavy_attack")
	check("Open cargo rejects heavy melee",combat.swing_count==swings)
	await prepare()
	combat.ammunition = 2
	await press("reload")
	await frames(12)
	await panel_key(KEY_B)
	await frames(110)
	check("Opening cargo cancels reload without creating ammunition",combat.state=="READY" and combat.ammunition==2 and combat.reserve==40)
	await prepare("WRENCH")
	var enemy := EnemyActor.new()
	enemy.target = player
	enemy.position = player.position+Vector3(0,0,-2)
	enemy.home = enemy.position
	game.add_child(enemy)
	enemy.brain.enabled = false
	player.visual.rotation.y = 0
	await press("attack",1)
	await panel_key(KEY_B)
	await frames(40)
	check("Opening cargo cancels an uncommitted swing",enemy.health.current==enemy.health.maximum and combat.state=="READY")
	enemy.queue_free()
	for code in [KEY_B,KEY_N]:
		await prepare()
		await together(code)
		check("Same-frame panel open and attack cannot leak a shot "+str(code),combat.ammunition==5)
	await prepare()
	await panel_key(KEY_B)
	Input.action_press("attack")
	await frames(4)
	await panel_key(KEY_B)
	var held_ammo := combat.ammunition
	await frames(45)
	check("Closing a panel does not fire a held attack",combat.ammunition==held_ammo)
	Input.action_release("attack")
	await frames(3)
	await press("attack")
	check("A fresh attack works after the panel closes",combat.ammunition==held_ammo-1)
	await prepare()
	await panel_key(KEY_N)
	var before := player.position
	await press("move_forward",20)
	check("Live orders retain movement controls",player.position.distance_to(before)>0.8 and game.workers.panel.visible)
	await prepare()
	await press("dodge",6)
	await panel_key(KEY_B)
	check("A live panel preserves the active dodge immunity window",combat.health.invulnerable)
	await frames(45)
	check("Panel use cannot leave dodge immunity stuck on",not combat.health.invulnerable)
	await finish_report("panel_combat","42 inventory and orders combat gating",started,"--verify-panel_combat")
