extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await until(func(): return game.workers.navigation.ready_for_paths,300)
	player.position = Vector3(0,CoastalRegion.height_at(0,64)+0.1,64)
	player.velocity = Vector3.ZERO
	await frames(20)
	var enemy := EnemyActor.new()
	enemy.position = Vector3(0,CoastalRegion.height_at(0,50)+0.1,50)
	enemy.home = enemy.position
	enemy.target = player
	game.add_child(enemy)
	enemy.brain.navigation = game.workers.navigation
	await frames(30)
	check("Hostile detects target before cover appears",enemy.brain.machine.current==&"Pursue")
	var memory := enemy.brain.last_seen
	var wall := BlockoutKit.box(game,Vector3(0,CoastalRegion.height_at(0,57)+2,57),Vector3(8,4,0.5),Color("917955"),true)
	player.position.x = 3
	await frames(45)
	check("Occluded hostile follows last sighting, not hidden player coordinates",enemy.brain.last_seen.distance_to(memory)<0.15 and not enemy.brain._sees())
	check("Enemy cannot damage through new wall",game.combat.health.current==100)
	var detour := 0.0
	var count := 0
	while game.combat.health.current==100 and count<1200:
		await frames(3)
		detour = maxf(detour,absf(enemy.position.x))
		count += 3
	check("Hostile navigates around cover and attacks",game.combat.health.current<100 and detour>4.3 and enemy.brain.route_requests>0,"detour=%.2f routes=%d state=%s"%[detour,enemy.brain.route_requests,enemy.brain.machine.current])
	check("Path requests are throttled",enemy.brain.route_requests<=22)
	player.position = Vector3(60,CoastalRegion.height_at(60,80)+0.1,80)
	player.velocity = Vector3.ZERO
	await frames(20)
	check("Leaving leash sends hostile home",enemy.brain.machine.current==&"Return")
	var returned := await until(func(): return enemy.brain.machine.current==&"Idle" and enemy.position.distance_to(enemy.home)<1.5,1500)
	check("Return path also avoids cover",returned,"position=%s"%enemy.position)
	wall.queue_free()
	await frames(3)
	game.combat.health.restore()
	enemy.position = enemy.home
	enemy.velocity = Vector3.ZERO
	player.position = Vector3(3,CoastalRegion.height_at(3,64)+0.1,64)
	player.velocity = Vector3.ZERO
	wall = BlockoutKit.box(game,Vector3(0,CoastalRegion.height_at(0,57)+0.425,57),Vector3(8,0.85,0.5),Color("917955"),true)
	await frames(20)
	check("Low barrier preserves visual detection",enemy.brain._sees())
	detour = 0
	count = 0
	while game.combat.health.current==100 and count<900:
		await frames(3)
		detour = maxf(detour,absf(enemy.position.x))
		count += 3
	check("Visible target beyond low barrier remains reachable",game.combat.health.current<100 and detour>4.3,"position=%s detour=%.2f"%[enemy.position,detour])
	enemy.health.take_damage(999,&"player")
	check("Death cancels navigation movement",enemy.brain.machine.current==&"Dead" and enemy.desired_velocity==Vector3.ZERO)
	wall.queue_free()
	enemy.queue_free()
	game.combat.health.restore()
	player.recover()
	await finish_report("ai","14 navigation-aware hostile pursuit",started,"--verify-ai")
