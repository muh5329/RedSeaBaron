extends SceneTree

func frames(n: int) -> void:
	for i in range(n): await physics_frame

func _initialize() -> void:
	probe.call_deferred()

func probe() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.verification_session = true
	game._begin()
	game.world.enabled = false
	BlockoutKit.box(game,Vector3(0,29.5,100),Vector3(30,1,30),Color("aa9c80"),true)
	game.bike.position = Vector3(0,32,100)
	game.player.position = Vector3(0.9,32,100)
	await frames(100)
	game.bike.set_physics_process(false)
	game.player.set_physics_process(false)
	game.player.position = Vector3(0.9,30,100)
	var enemy := EnemyActor.new()
	enemy.target = game.player
	enemy.position = Vector3(-0.9,30,100)
	enemy.home = enemy.position
	game.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.brain.enabled = false
	await frames(3)
	var cover := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(enemy.position+Vector3.UP,game.player.position+Vector3.UP,8))
	var checks := []
	checks.append({"test":"Actual motorcycle blocks the eye-level segment","passed":cover.get("collider")==game.bike})
	checks.append({"test":"Enemy cannot see through the motorcycle","passed":not enemy.brain._sees(),"sees":enemy.brain._sees()})
	enemy.brain.enabled = true
	enemy.brain.machine.change(&"Attack")
	await frames(48)
	checks.append({"test":"Committed hostile strike cannot pass through chassis","passed":game.combat.health.current==100,"health":game.combat.health.current})
	enemy.brain.enabled = false
	game.bike.position.x = 8
	game.combat.health.restore()
	enemy.brain.machine.change(&"Idle")
	enemy.brain.machine.change(&"Attack")
	enemy.brain.enabled = true
	await frames(48)
	checks.append({"test":"Removing cover allows the same hostile strike","passed":game.combat.health.current==87,"health":game.combat.health.current})
	var report := {"passed":checks.filter(func(c): return c.passed).size(),"total":checks.size(),"tests":checks}
	var file := FileAccess.open("res://docs/evidence/m93-before/baseline-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report));file.close()
	print("ENEMY_COVER_BASELINE ",JSON.stringify(report))
	game.audio.enabled = false
	await process_frame
	await process_frame
	quit()
