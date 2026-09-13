extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await place(Vector2(0,110))
	game.world.enabled = false
	var platform := BlockoutKit.box(game,Vector3(0,29.5,110),Vector3(80,1,120),Color("937957"),true)
	bike.position = Vector3(0,30.2,110)
	bike.velocity = Vector3.ZERO
	player.position = bike.position+Vector3(1.65,0.1,0)
	player.velocity = Vector3.ZERO
	await frames(60)
	var roof := BlockoutKit.box(game,bike.position+Vector3(0,2.18,0),Vector3(1.0,0.16,1.5),Color("655645"),true)
	await frames(3)
	var mounted := seat.enter()
	check("Mounting rejects a ceiling through the seated rider",not mounted and not seat.mounted)
	if mounted: seat.leave(true)
	roof.queue_free()
	await frames(3)
	check("Clear seat allows normal mounting",seat.enter() and seat.mounted and not player.visible,"hull vertices=%d"%bike.rider_collision.collision.shape.points.size())
	var beam := BlockoutKit.box(game,Vector3(0,32.20,100),Vector3(3,0.16,0.3),Color("655645"),true)
	await frames(3)
	await press("move_forward",180)
	check("Driving stops before an overhead beam crosses the rider",seat.mounted and bike.position.z>99.8 and bike.position.z<102 and absf(bike.speed)<0.2,"position=%s speed=%.3f"%[bike.position,bike.speed])
	beam.queue_free()
	await frames(3)
	var before := bike.position
	await press("move_forward",120)
	check("Removing overhead cover restores driving",bike.position.distance_to(before)>4 and seat.mounted)
	await press("jump",75)
	var saveable: bool = game.saves.can_save()
	var saved: Dictionary = game.saves.snapshot()
	seat.leave(true)
	await frames(15)
	var hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(bike.position+Vector3.UP*3,bike.position+Vector3.UP*1.4,8))
	check("Dismount removes the parked motorcycle's rider collision",not seat.mounted and player.visible and hit.is_empty() and not bike.rider_collision.active)
	var foot_saved: Dictionary = game.saves.snapshot()
	var restored: bool = await game.saves.restore(saved)
	await frames(15)
	hit = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(bike.position+Vector3.UP*3,bike.position+Vector3.UP*1.4,8))
	check("Mounted save restore reinstates physical rider ownership",saveable and restored and seat.mounted and not player.visible and not hit.is_empty() and bike.rider_collision.active)
	game._set_paused(true)
	var frozen := bike.rider_collision.collision.global_transform
	await press("interact")
	check("Pause preserves rider ownership and collision pose",seat.mounted and bike.rider_collision.collision.global_transform.is_equal_approx(frozen))
	game._set_paused(false)
	game.world.enabled = false
	bike.set_physics_process(false)
	bike.position = Vector3(0,70,110)
	bike.rotation = Vector3.ZERO
	bike.visual.transform = Transform3D.IDENTITY
	bike.rider_collision.sync_transform()
	var post := BlockoutKit.box(game,bike.position+Vector3(0.51,1.69,0.12),Vector3(0.025,0.04,0.025),Color("655645"),true)
	await frames(3)
	check("Upper rider corner prevents a turn into a post",VehicleClearance.turn_clear(bike,0,1) and not bike.try_turn(0.25) and absf(bike.rotation.y)<0.001)
	post.queue_free()
	await frames(3)
	check("Removing rider-height obstruction releases steering",bike.try_turn(0.25) and absf(bike.rotation.y-0.25)<0.001)
	bike.rotation = Vector3.ZERO
	post = BlockoutKit.box(game,bike.position+Vector3(-0.45,2.10,0.31),Vector3(0.035,0.06,0.06),Color("655645"),true)
	await frames(3)
	bike.visual.rotation.z = 0.15
	bike.rider_collision.restrict_pose(Transform3D.IDENTITY)
	bike.rider_collision.sync_transform()
	check("Visual bank cannot push the rider through an obstacle",bike.visual.transform.is_equal_approx(Transform3D.IDENTITY) and bike.rider_collision.collision.transform.is_equal_approx(bike.visual.transform))
	post.queue_free()
	await frames(3)
	bike.visual.rotation.z = 0.15
	bike.rider_collision.restrict_pose(Transform3D.IDENTITY)
	bike.rider_collision.sync_transform()
	check("Clear rider resumes matching visual and collision attitude",absf(bike.visual.rotation.z-0.15)<0.001 and bike.rider_collision.collision.transform.is_equal_approx(bike.visual.transform))
	restored = await game.saves.restore(foot_saved)
	await frames(15)
	hit = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(bike.position+Vector3.UP*3,bike.position+Vector3.UP*1.4,8))
	check("On-foot save restore leaves no ghost rider collider",restored and not seat.mounted and player.visible and hit.is_empty() and not bike.rider_collision.active)
	platform.queue_free()
	await finish_report("rider_clearance","86 seated rider collision",started,"--verify-rider_clearance")
