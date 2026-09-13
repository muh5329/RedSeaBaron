extends "res://tests/worker_verifier.gd"
var opponent: EnemyActor

func aim_from(offset: Vector3) -> void:
	game.orbit.camera.global_position = player.position+offset
	game.orbit.camera.look_at(opponent.position+Vector3.UP*1.1)
	game.combat.shot_cooldown = 0

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
	game.orbit.camera.reparent(camera_parent,false)
	game.orbit.camera.transform = camera_local
	await finish_report("vehicle_cover","92 player weapons respect vehicle cover",started,"--verify-vehicle_cover")
