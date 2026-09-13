extends "res://tests/worker_verifier.gd"
var opponent: EnemyActor

func strike() -> void:
	game.combat.health.restore()
	opponent.brain.machine.change(&"Idle")
	opponent.brain.machine.change(&"Attack")
	opponent.brain.enabled = true
	await frames(48)
	opponent.brain.enabled = false

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	game.world.enabled = false
	BlockoutKit.box(game,Vector3(0,29.5,100),Vector3(30,1,30),Color("aa9c80"),true)
	bike.position = Vector3(0,32,100)
	player.position = Vector3(0.9,32,100)
	await frames(100)
	bike.set_physics_process(false)
	player.set_physics_process(false)
	player.position = Vector3(0.9,30,100)
	opponent = EnemyActor.new()
	opponent.target = player
	opponent.position = Vector3(-0.9,30,100)
	opponent.home = opponent.position
	game.add_child(opponent)
	opponent.set_physics_process(false)
	opponent.brain.enabled = false
	await frames(3)
	var cover := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(opponent.position+Vector3.UP,player.position+Vector3.UP,8))
	check("Real motorcycle blocks hostile eye-level segment",cover.get("collider")==bike)
	check("Hostile cannot see through motorcycle chassis",not opponent.brain._sees())
	await strike()
	check("Committed hostile strike cannot pass through chassis",game.combat.health.current==100)
	bike.position.x = 8
	await frames(3)
	await strike()
	check("Removing chassis cover restores hostile damage",game.combat.health.current==87)
	game.combat.health.restore()
	bike.position.x = 0
	bike.set_physics_process(true)
	player.set_physics_process(true)
	player.position = bike.position+Vector3(1.7,0.1,0)
	await frames(20)
	check("Normal mounting binds the physical rider target",seat.enter() and game.combat.health.aim_anchor==bike.visual.rider_aim_point and game.combat.health.occlusion_receiver==bike.rider_collision.collision)
	await frames(3)
	opponent.position = bike.position+Vector3(0,0.055,-1.9)
	await frames(3)
	var target_point: Vector3 = bike.visual.rider_aim_point.global_position
	var hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(opponent.position+Vector3.UP,target_point,9))
	var receiver: Object = null
	if not hit.is_empty():
		var body: CollisionObject3D = hit.collider
		receiver = body.shape_owner_get_owner(body.shape_find_owner(hit.shape))
	check("Mounted sight terminates on the rider's own collision shape",receiver==bike.rider_collision.collision,"hit=%s target=%s"%[receiver,target_point])
	check("Exposed mounted rider remains visible to hostiles",opponent.brain._sees())
	await strike()
	check("A committed strike damages the occupied rider",seat.mounted and game.combat.health.current==87,"health=%.0f"%game.combat.health.current)
	game.combat.health.restore()
	opponent.position = bike.position+Vector3(0,0.055,-2.3)
	var wall := BlockoutKit.box(game,bike.position+Vector3(0,1.3,-1.65),Vector3(1.3,2.5,0.15),Color("655645"),true)
	await frames(3)
	check("World cover still hides the mounted receiver",not opponent.brain._sees())
	await strike()
	check("World cover stops a committed mounted strike",game.combat.health.current==100)
	wall.queue_free()
	await frames(3)
	check("Removing world cover reveals the rider",opponent.brain._sees())
	var saveable: bool = game.saves.can_save()
	var saved: Dictionary = game.saves.snapshot()
	seat.leave(true)
	await frames(3)
	check("Dismount clears transient combat target ownership",not seat.mounted and game.combat.health.aim_anchor==null and game.combat.health.occlusion_receiver==null)
	var restored: bool = await game.saves.restore(saved)
	await frames(3)
	check("Mounted journey restoration rebinds the receiver",saveable and restored and seat.mounted and game.combat.health.aim_anchor==bike.visual.rider_aim_point and game.combat.health.occlusion_receiver==bike.rider_collision.collision)
	game._set_paused(true)
	var pose: Transform3D = bike.visual.rider_aim_point.global_transform
	await frames(12)
	check("Pause preserves mounted target ownership and pose",seat.mounted and game.combat.health.aim_anchor==bike.visual.rider_aim_point and pose.is_equal_approx(bike.visual.rider_aim_point.global_transform))
	game._set_paused(false)
	game.world.enabled = false
	# Put the sight-test opponent behind the tail before deploying; its former
	# forward position now correctly obstructs the physical nose propeller.
	opponent.position = bike.position+Vector3(0,0.055,4.2)
	await frames(3)
	bike.transformation.request_toggle()
	await frames(80)
	check("Aircraft tail hides rider without ignoring the whole bike",bike.transformation.mode=="AIRCRAFT" and not opponent.brain._sees())
	seat.leave(true)
	check("Forced exit also clears rider targeting",not seat.mounted and game.combat.health.aim_anchor==null and game.combat.health.occlusion_receiver==null)
	await finish_report("hostile_cover","93 hostile cover and rider targeting",started,"--verify-hostile_cover")
