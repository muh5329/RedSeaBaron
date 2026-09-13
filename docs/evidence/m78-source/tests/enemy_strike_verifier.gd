extends "res://tests/worker_verifier.gd"
var opponent: EnemyActor

func enemy_kind() -> String:
	return "Raider"

func suite_id() -> String:
	return "enemy_strike"

func duel() -> void:
	release()
	if is_instance_valid(opponent):
		game.enemies.erase(opponent)
		opponent.queue_free()
	game._set_paused(false)
	game.world.enabled = false
	game.combat.health.restore()
	player.dodge_remaining = 0
	player.position = Vector3(-20,CoastalRegion.height_at(-20,80)+0.1,80)
	player.velocity = Vector3.ZERO
	opponent = EnemyActor.new()
	opponent.kind = enemy_kind()
	opponent.target = player
	opponent.position = Vector3(-20,CoastalRegion.height_at(-20,78)+0.1,78)
	opponent.home = opponent.position
	game.add_child(opponent)
	game.enemies.append(opponent)
	opponent.brain.enabled = false
	await frames(30)
	opponent.brain.decision_clock = 0
	opponent.brain.machine.change(&"Attack")
	opponent.brain.enabled = true

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await duel()
	await frames(27)
	check("Enemy windup gives time before damage",game.combat.health.current==100 and opponent.brain.machine.current==&"Attack")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		game.orbit.yaw = 0
		game.orbit.pitch = -0.5
		game.orbit.snap()
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/%s-native-windup.jpg"%suite_id())
	await frames(38)
	check("A front-facing strike deals damage only once",game.combat.health.current==100-opponent.brain.damage and opponent.brain.strike_done)
	await duel()
	await frames(27)
	var facing := opponent.model.rotation.y
	player.position = opponent.position+Vector3(0,0.05,-2)
	player.velocity = Vector3.ZERO
	await frames(15)
	check("Enemy commits direction before the strike",absf(wrapf(opponent.model.rotation.y-facing,-PI,PI))<0.1)
	check("Moving behind a committed attack avoids its hit",game.combat.health.current==100)
	await duel()
	await frames(27)
	player.position = opponent.position+Vector3(2,0.05,0)
	player.velocity = Vector3.ZERO
	await frames(15)
	check("A committed forward strike cannot hit a side target",game.combat.health.current==100)
	await duel()
	await frames(27)
	game._set_paused(true)
	var elapsed := opponent.brain.machine.elapsed
	await frames(60)
	check("Pause freezes the attack windup and damage",opponent.brain.machine.elapsed==elapsed and game.combat.health.current==100)
	game._set_paused(false)
	game.world.enabled = false
	await frames(15)
	check("Resuming a windup yields one normal strike",game.combat.health.current==100-opponent.brain.damage)
	await duel()
	await frames(27)
	var wall := BlockoutKit.box(game,(opponent.position+player.position)*0.5+Vector3.UP,Vector3(3,2,0.25),Color("88765c"),true)
	await frames(15)
	check("Cover added during windup blocks the strike",game.combat.health.current==100)
	wall.queue_free()
	await duel()
	await frames(27)
	opponent.health.take_damage(1,&"player")
	await frames(15)
	check("A hit interruption cancels the pending strike",game.combat.health.current==100 and opponent.brain.machine.current==&"Hit")
	await duel()
	await frames(27)
	opponent.health.take_damage(999,&"player")
	await frames(20)
	check("Enemy death cancels a pending strike",game.combat.health.current==100 and opponent.brain.machine.current==&"Dead")
	await finish_report(suite_id(),"34 readable committed enemy strikes / "+enemy_kind(),started,"--verify-"+suite_id())
