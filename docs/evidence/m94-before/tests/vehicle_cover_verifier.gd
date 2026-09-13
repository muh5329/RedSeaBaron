extends "res://tests/worker_verifier.gd"
var opponent: EnemyActor

func aim_from(offset: Vector3) -> void:
	game.orbit.camera.global_position = player.position+offset
	game.orbit.camera.look_at(opponent.position+Vector3.UP*1.1)
	game.combat.shot_cooldown = 0

func capture_cover() -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args(): return
	await frames(2)
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/vehicle-cover-m92.jpg")

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	game.world.enabled = false
	BlockoutKit.box(game,Vector3(0,29.5,100),Vector3(30,1,30),Color("aa9c80"),true)
	bike.position = Vector3(0,32,100)
	player.position = Vector3(1.7,32,100)
	await frames(100)
	seat.enter()
	bike.transformation.request_toggle()
	await frames(80)
	seat.leave()
	bike.set_physics_process(false)
	player.position = Vector3(0,30.1,106)
	player.velocity = Vector3.ZERO
	opponent = EnemyActor.new()
	opponent.target = player
	opponent.position = Vector3(0,30.1,97)
	opponent.home = opponent.position
	game.add_child(opponent)
	opponent.set_simulation(false)
	await frames(20)
	opponent.set_physics_process(false)
	game.orbit.set_physics_process(false)
	game.orbit.set_process(false)
	var camera_parent: Node = game.orbit.camera.get_parent()
	var camera_local: Transform3D = game.orbit.camera.transform
	game.orbit.camera.reparent(game)
	game.combat.equip("RIFLE")
	aim_from(Vector3(0,1.35,0.3))
	var cover := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(player.position+Vector3.UP*1.35,opponent.position+Vector3.UP*1.1,8))
	check("Real parked aircraft geometry lies across the shot",not seat.mounted and bike.transformation.mode=="AIRCRAFT" and not cover.is_empty() and cover.collider==bike)
	var ammo: int = game.combat.ammunition
	await press("attack")
	check("Blocked rifle shot still consumes one cartridge",game.combat.ammunition==ammo-1)
	check("Parked aircraft stops rifle damage through its tail",opponent.health.current==90,"enemy health=%.0f"%opponent.health.current)
	bike.position.x = 8
	await frames(3)
	opponent.health.restore()
	aim_from(Vector3(0,1.35,0.3))
	await press("attack")
	check("Removing vehicle cover restores rifle damage",opponent.health.current==42,"enemy health=%.0f"%opponent.health.current)
	bike.position.x = 0
	opponent.health.restore()
	opponent.brain.machine.change(&"Idle")
	await frames(3)
	aim_from(Vector3(5,4.35,0.3))
	var camera_hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(game.orbit.camera.global_position,opponent.position+Vector3.UP*1.1,13))
	var muzzle_hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(player.position+Vector3.UP*1.35,camera_hit.get("position",opponent.position+Vector3.UP),8))
	check("Shoulder camera sees the target while the muzzle is covered",camera_hit.get("collider")==opponent and muzzle_hit.get("collider")==bike)
	ammo = game.combat.ammunition
	await press("attack")
	check("Muzzle cover stops a camera-clear shot",opponent.health.current==90 and game.combat.ammunition==ammo-1)
	var tracer_end: Vector3 = game.combat.tracer.global_position-game.combat.tracer.global_basis.z*0.5
	check("Rifle tracer ends at the physical vehicle impact",not muzzle_hit.is_empty() and tracer_end.distance_to(muzzle_hit.get("position",Vector3.ZERO))<0.05,"endpoint=%s impact=%s"%[tracer_end,muzzle_hit.get("position")])
	await capture_cover()
	game.combat.toggle_lock()
	check("Vehicle cover prevents player target lock",game.combat.target==null)
	bike.position.x = 8
	await frames(3)
	game.combat.toggle_lock()
	check("Removing cover makes the same enemy lockable",game.combat.target==opponent)
	bike.position.x = 0
	await frames(8)
	check("New vehicle cover releases an existing player lock",game.combat.target==null)
	bike.transformation.reset()
	player.set_physics_process(false)
	player.position = Vector3(-0.9,30,100)
	player.velocity = Vector3.ZERO
	opponent.position = Vector3(0.9,30,100)
	opponent.health.restore()
	player.visual.rotation.y = -PI/2
	game.combat.equip("WRENCH")
	game.combat.combo_window = 0
	player.stamina = 100
	await frames(3)
	var melee_cover := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(player.position+Vector3.UP*1.2,opponent.position+Vector3.UP,8))
	check("Ground motorcycle separates a real in-range melee pair",bike.transformation.mode=="BIKE" and melee_cover.get("collider")==bike and player.position.distance_to(opponent.position)<game.combat.config.melee_range)
	await press("attack")
	await frames(35)
	check("Wrench cannot hit through the motorcycle chassis",opponent.health.current==90)
	bike.position.x = 8
	game.combat.cancel()
	game.combat.combo_window = 0
	player.stamina = 100
	await frames(3)
	await press("attack")
	await frames(35)
	check("Moving the motorcycle restores the same melee strike",opponent.health.current==64,"enemy health=%.0f"%opponent.health.current)
	game.orbit.camera.reparent(camera_parent,false)
	game.orbit.camera.transform = camera_local
	await finish_report("vehicle_cover","92 player weapons respect vehicle cover",started,"--verify-vehicle_cover")
