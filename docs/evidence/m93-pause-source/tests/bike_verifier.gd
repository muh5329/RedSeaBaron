extends Node
var game: Node3D
var player: PlayerController
var bike: BikeController
var seat: VehicleSeat
var checks: Array[Dictionary] = []

func frames(n: int) -> void:
	for i in range(n): await get_tree().physics_frame

func release() -> void:
	for action in InputMap.get_actions(): Input.action_release(action)

func press(action: String, n: int = 2) -> void:
	Input.action_press(action)
	await frames(n)
	Input.action_release(action)
	await frames(2)

func check(label: String, ok: bool, detail: String = "") -> void:
	checks.append({"test":label,"passed":ok,"detail":detail})
	print("RSB_BIKE | ", "PASS" if ok else "FAIL", " | ", label, " | ", detail)
	game.hud.verified_label.visible = true
	game.hud.verified_label.text = "BIKE CHECKS %d / %d\n%s" % [checks.filter(func(c): return c.passed).size(),checks.size(),label]

func place(at: Vector2 = Vector2(0, 80)) -> void:
	release()
	if seat.mounted: seat.leave(true)
	bike.position = Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+0.2,at.y)
	bike.speed = 0
	bike.velocity = Vector3.ZERO
	bike.rotation = Vector3.ZERO
	player.position = bike.position + Vector3(1.65,0.15,0)
	player.velocity = Vector3.ZERO
	player.stamina = 100
	game.combat.health.restore()
	game.orbit.yaw = 0
	game.orbit.pitch = -0.27
	game.orbit.snap()
	await frames(30)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var saved_player := player.position
	var saved_bike := bike.position
	var saved_weapon: String = game.combat.weapon
	var saved_ammo: int = game.combat.ammunition
	var started := Time.get_ticks_msec()
	await place()
	check("Grounded motorcycle",bike.is_on_floor())
	player.position.x += 9
	check("Remote mounting rejected",not seat.enter() and not seat.mounted)
	await place()
	Input.action_press("jump")
	Input.action_press("interact")
	await frames(2)
	release()
	check("Jump plus mount rejected",not seat.mounted)
	await place()
	Input.action_press("dodge")
	Input.action_press("interact")
	await frames(2)
	release()
	check("Dodge plus mount rejected",not seat.mounted)
	await frames(40)
	await place()
	game.combat.equip("RIFLE")
	var ammo: int = game.combat.ammunition
	Input.action_press("interact")
	Input.action_press("attack")
	await frames(3)
	release()
	check("Mount transfers exclusive controls",seat.mounted and not player.input_enabled and bike.input_enabled and not player.visible and bike.visual.rider.visible and game.orbit.follow_target==bike.camera_anchor)
	check("Simultaneous mount/fire cannot shoot",game.combat.ammunition==ammo)
	check("Mounted melee/rifle blocked",not game.combat.fire() and not game.combat.start_melee())
	var transitions := seat.transition_count
	check("Duplicate mount rejected",not seat.enter() and seat.transition_count==transitions)
	var from := bike.position
	Input.action_press("move_forward")
	await frames(120)
	var travelled := from.distance_to(bike.position)
	check("Acceleration and travel",bike.speed>12 and travelled>10,"speed=%.2f; distance=%.2f" % [bike.speed,travelled])
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/bike-native-driving.jpg")
	check("Moving dismount denied",not seat.leave() and seat.mounted)
	Input.action_press("move_right")
	await frames(45)
	check("Steering changes heading",absf(bike.rotation.y)>0.5,"yaw=%.2f front wheel yaw=%.2f" % [bike.rotation.y,bike.visual.front_steering.rotation.y])
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.orbit.set_physics_process(false)
		var view := Camera3D.new()
		game.add_child(view)
		view.global_position = bike.global_position+bike.global_basis*Vector3(3,3,-5)
		view.look_at(bike.global_position+Vector3.UP*0.8)
		view.current = true
		await frames(2)
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/bike-steering-m74.jpg")
		view.queue_free()
		game.orbit.camera.current = true
		game.orbit.set_physics_process(true)
	release()
	await press("jump",90)
	check("Brake stops vehicle",absf(bike.speed)<0.2,"speed=%.3f" % bike.speed)
	check("Physics remains upright",absf(bike.rotation.x)<0.01 and absf(bike.rotation.z)<0.01)
	await press("interact")
	check("Dismount restores actor and camera",not seat.mounted and player.input_enabled and player.visible and not bike.input_enabled and game.combat.enabled and game.orbit.follow_target==player)
	check("Dismount uses clear ground",player.position.distance_to(bike.position)>1.0 and player.collision_mask==13)
	await place()
	await press("interact")
	from = bike.position
	await press("move_back",60)
	check("Reverse works",bike.position.z>from.z+2.0 and bike.speed<0)
	bike.speed = 0
	bike.velocity = Vector3.ZERO
	game._set_paused(true)
	from = bike.position
	await press("move_forward",40)
	check("Pause freezes vehicle and combat",bike.position.distance_to(from)<0.001 and not bike.input_enabled and not game.combat.enabled)
	game._set_paused(false)
	check("Resume preserves seat ownership",seat.mounted and bike.input_enabled and not player.input_enabled and not game.combat.enabled)
	# Tall blocking boxes occupy all four candidate dismount positions.
	var blockers: Array[Node3D] = []
	for offset in [Vector3(1.7,0,0),Vector3(-1.7,0,0),Vector3(0,0,2.2),Vector3(0,0,-2.2)]:
		blockers.append(BlockoutKit.box(game,bike.position+offset+Vector3.UP*2,Vector3(1.1,4,1.1),Color("987e60"),true))
	await frames(3)
	check("Blocked dismount preserves mounted state",not seat.leave() and seat.mounted and not player.visible)
	for block in blockers: block.queue_free()
	await frames(3)
	check("Dismount recovers after obstruction removed",seat.leave())
	await place(Vector2(32,20))
	bike.rotation.y = -PI/2
	await press("interact")
	await press("move_forward",90)
	check("World wall prevents driving through",bike.position.x<35.1,"x=%.3f" % bike.position.x)
	check("Collision reduces speed",absf(bike.speed)<0.5,"speed=%.3f" % bike.speed)
	await place()
	await press("interact")
	game.combat.health.take_damage(999,&"hostile")
	check("Mounted death releases seat",not seat.mounted and player.visible and not bike.input_enabled)
	await frames(130)
	check("Mounted death recovers playable actor",game.combat.health.current==100 and player.input_enabled)
	await place()
	await press("interact")
	bike.position.y = -12
	await frames(15)
	check("Out-of-bounds riding recovery",seat.mounted and bike.position.distance_to(bike.home)<1 and game.orbit.follow_target==bike.camera_anchor)
	await place(Vector2(0,80))
	bike.rotation.y = PI
	await press("interact")
	Input.action_press("move_forward")
	var seam_contacts: Array = []
	for step in range(120):
		await frames(1)
		if step>25 and bike.speed<0.5 and (seam_contacts.is_empty() or step==119):
			var contacts: Array = []
			for slide in range(bike.get_slide_collision_count()):
				var hit := bike.get_slide_collision(slide)
				for contact in range(hit.get_collision_count()):
					var collider := hit.get_collider(contact)
					contacts.append({"collider":str(collider.get_path()) if collider is Node else str(collider),"normal":str(hit.get_normal(contact)),"point":str(hit.get_position(contact)),"depth":hit.get_depth(),"shape":hit.get_collider_shape_index(contact)})
			seam_contacts.append({"frame":step,"position":str(bike.position),"velocity":str(bike.velocity),"floor":bike.is_on_floor(),"wall":bike.is_on_wall(),"contacts":contacts})
	release()
	check("Ground contacts do not erase acceleration at terrain seams",bike.position.z>93 and bike.speed>12,"z=%.2f speed=%.2f contacts=%s"%[bike.position.z,bike.speed,JSON.stringify(seam_contacts)])
	release()
	seat.leave(true)
	bike.position = saved_bike
	bike.velocity = Vector3.ZERO
	bike.speed = 0
	bike.rotation = Vector3.ZERO
	player.position = saved_player
	player.velocity = Vector3.ZERO
	game.combat.health.restore()
	game.combat.equip(saved_weapon)
	game.combat.ammunition = saved_ammo
	game.orbit.snap()
	release()
	var passed := checks.filter(func(c): return c.passed).size()
	var report := {"milestone":"03 grounded bike","passed":passed,"total":checks.size(),"platform":OS.get_name(),"elapsed_seconds":(Time.get_ticks_msec()-started)/1000.0,"tests":checks}
	print("RSB_BIKE_REPORT ",JSON.stringify(report))
	game.hud.verified_label.text = "BIKE: %d / %d PASSED" % [passed,checks.size()]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(()=>{let p=document.createElement('pre');p.id='bike-report';p.style='position:fixed;right:16px;top:16px;max-height:65vh;overflow:auto;max-width:460px;padding:16px;background:#152d29;color:#f4e3bb;z-index:10;font:12px monospace';p.textContent=%s;document.body.appendChild(p)})()" % JSON.stringify(JSON.stringify(report,"  ")),true)
	else:
		var file := FileAccess.open("res://docs/evidence/bike-native-report.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
	if "--verify-bike" in OS.get_cmdline_user_args():
		get_tree().quit(0 if passed==checks.size() else 1)
