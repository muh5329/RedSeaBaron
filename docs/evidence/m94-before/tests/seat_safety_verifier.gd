extends "res://tests/worker_verifier.gd"

func body_clear(at: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.85
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = at+Vector3.UP*0.95
	query.collision_mask = 8
	query.exclude = [player.get_rid()]
	return game.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await place()
	bike.velocity.y = 6
	await frames(5)
	check("Grounded player cannot board a falling or jumping motorcycle",player.is_on_floor() and not bike.is_on_floor() and not seat.can_mount())
	await place()
	bike.speed = 6
	await frames(2)
	check("Moving motorcycle rejects boarding without changing ownership",not seat.enter() and not seat.mounted and player.visible)
	await place()
	check("Stopped grounded motorcycle still accepts boarding",seat.enter())
	await press("transform_vehicle")
	check("Unfolding wings block voluntary dismount",bike.transformation.mode=="DEPLOYING" and not seat.leave() and seat.mounted)
	# Keep baseline failures independent; normal gameplay never forces this state.
	if not seat.mounted: seat.restore_ownership(true)
	await frames(80)
	var candidate: Variant = seat._exit_point()
	check("Aircraft exit candidate clears its own deployed wing collider",candidate!=null and body_clear(candidate),"candidate=%s"%candidate)
	var exited := seat.leave()
	check("Grounded aircraft permits a clear exit outside the wings",exited and body_clear(player.position) and player.visible and game.combat.enabled)
	await frames(30)
	check("Aircraft dismount settles on ground without overlap correction",player.is_on_floor() and absf(player.position.y-CoastalRegion.height_at(player.position.x,player.position.z))<0.5 and body_clear(player.position))
	# Approach from the nose, mount and verify folding has the same ownership guard.
	player.position = bike.position-bike.global_basis.z*2.2+Vector3.UP*0.1
	player.velocity = Vector3.ZERO
	await frames(25)
	var boarded := seat.enter()
	await press("transform_vehicle")
	check("Folding wings also block voluntary dismount",boarded and bike.transformation.mode=="FOLDING" and not seat.leave() and seat.mounted)
	if not seat.mounted: seat.restore_ownership(true)
	await frames(80)
	check("Completed folding restores normal dismount",bike.transformation.mode=="BIKE" and seat.leave())
	await place()
	seat.enter()
	bike.velocity.y = 6
	await frames(5)
	check("Ground mode dismount waits for real floor contact",not bike.is_on_floor() and not seat.leave() and seat.mounted)
	if not seat.mounted: seat.restore_ownership(true)
	await frames(75)
	check("Settled ground contact restores voluntary exit",bike.is_on_floor() and seat.leave())
	await place()
	seat.enter()
	await press("transform_vehicle")
	var forced := seat.leave(true)
	check("Forced recovery safely cancels an unfinished transformation",forced and not seat.mounted and bike.transformation.mode=="BIKE" and player.visible)
	await finish_report("seat_safety","25 vehicle boarding and wing-safe dismount",started,"--verify-seat_safety")
