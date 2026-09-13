extends "res://tests/integration_verifier.gd"

func visit_quarry() -> void:
	release()
	player.position = Vector3(4800,CoastalRegion.height_at(4800,1255)+4,1255)
	player.velocity = Vector3.ZERO
	game.orbit.yaw = 0
	game.orbit.snap()
	await frames(120)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var manager: SpawnManager = game.encounters
	check("Town keeps regional encounter actors unloaded",manager.active.is_empty() and manager.navigation.is_empty())
	await visit_quarry()
	var actors: Array = manager.active.get("red_mesa",[])
	check("Quarry streams human and monster hostiles",actors.size()==2 and actors[0].kind=="Raider" and actors[1].kind=="Cinder beast")
	if actors.size()!=2:
		await finish_report("encounter","19 persistent regional encounters",started,"--verify-encounter")
		return
	var nav: NavigationController = manager.navigation["red_mesa"]
	check("Encounter uses bounded navigation at world coordinates",nav.ready_for_paths and nav.side_cells==31 and nav.grid.region.size==Vector2i(31,31) and nav.origin.x>4000)
	check("Core hostiles remain inactive during regional combat",game.enemies.all(func(e): return not is_instance_valid(e) or not e.simulation_enabled))
	var enemy: EnemyActor = actors[0]
	check("Player approaches regional hostile through locomotion",await walk_near(enemy))
	await press("equip_rifle")
	await press("lock_target")
	await frames(30)
	await press("attack")
	await frames(8)
	check("Rifle damages regional hostile using actual ammunition",enemy.health.current==42 and game.combat.ammunition==4,"health=%.0f ammo=%d"%[enemy.health.current,game.combat.ammunition])
	var wounded: Dictionary = game.saves.snapshot()
	check("Wounded regional state validates for saving",SaveSchema.validate(wounded,game))
	await frames(40)
	await press("attack")
	await frames(6)
	check("Regional kill updates persistent record",enemy.health.current==0 and manager.records["red_mesa_0"].health==0)
	var retired: WeakRef = weakref(enemy)
	player.recover()
	await frames(30)
	check("Leaving retires actors and local navigation",retired.get_ref()==null and manager.active.is_empty() and manager.navigation.is_empty())
	await visit_quarry()
	actors = manager.active.get("red_mesa",[])
	check("Killed enemy stays dead after returning",actors.size()==1 and actors[0].kind=="Cinder beast" and actors[0].is_on_floor())
	var loaded: bool = await game.saves.restore(wounded)
	await frames(90)
	actors = manager.active.get("red_mesa",[])
	var found := false
	for actor: EnemyActor in actors:
		if actor.kind=="Raider":
			enemy = actor
			found = actor.health.current==42 and actor.is_on_floor()
	check("Loading wounded save restores health without healing",loaded and found and actors.size()==2)
	game._set_paused(true)
	var before := enemy.position
	await frames(30)
	check("Pause freezes regional hostile physics and decisions",not enemy.simulation_enabled and enemy.position.distance_to(before)<0.001)
	game._set_paused(false)
	var bad: Dictionary = wounded.duplicate(true)
	bad.encounters.red_mesa_0.health = 999
	check("Impossible regional health rejects before restore",not await game.saves.restore(bad) and enemy.health.current==42)
	bad = wounded.duplicate(true)
	bad.encounters.red_mesa_0.position = [0,2,0]
	check("Out-of-region saved hostile position is rejected",not SaveSchema.validate(bad,game))
	var legacy: Dictionary = wounded.duplicate(true)
	legacy.erase("encounters")
	check("Earlier saves without encounters remain compatible",SaveSchema.validate(legacy,game))
	check("Only nearby encounter actors and records are resident",manager.active.size()==1 and manager.navigation.size()==1 and manager.records.size()==2)
	player.recover()
	await frames(30)
	await finish_report("encounter","19 persistent regional encounters",started,"--verify-encounter")
