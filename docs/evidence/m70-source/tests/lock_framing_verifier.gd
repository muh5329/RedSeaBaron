extends "res://tests/worker_verifier.gd"
var opponent: EnemyActor

func scenario(kind: String, separation: float = 2.2) -> void:
	release()
	game.combat.target = null
	if is_instance_valid(opponent):
		game.enemies.erase(opponent)
		opponent.queue_free()
	game._set_paused(false)
	game.world.enabled = false
	game.combat.health.restore()
	game.combat.equip("WRENCH")
	player.position = Vector3(-20,CoastalRegion.height_at(-20,80)+0.1,80)
	player.velocity = Vector3.ZERO
	opponent = EnemyActor.new()
	opponent.kind = kind
	opponent.target = player
	opponent.position = Vector3(-20,CoastalRegion.height_at(-20,80-separation)+0.1,80-separation)
	opponent.home = opponent.position
	game.add_child(opponent)
	game.enemies.append(opponent)
	opponent.brain.enabled = false
	await frames(30)
	opponent.set_physics_process(false)
	opponent.face(player.position)
	game.orbit.yaw = 0
	game.orbit.pitch = -0.27
	game.orbit.distance = 6.2
	game.orbit.snap()
	await press("lock_target")
	await frames(70)

func head_point() -> Vector3:
	return opponent.global_position+Vector3.UP*(1.68 if opponent.kind=="Raider" else 1.03)

func head_unobstructed() -> bool:
	var query := PhysicsRayQueryParameters3D.create(game.orbit.camera.global_position,head_point(),2)
	return game.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func framed() -> bool:
	var camera: Camera3D = game.orbit.camera
	var bounds := get_viewport().get_visible_rect()
	var margin := bounds.size*0.08
	var inner := Rect2(bounds.position+margin,bounds.size-margin*2)
	return not camera.is_position_behind(head_point()) and inner.has_point(camera.unproject_position(head_point())) and inner.has_point(camera.unproject_position(player.position+Vector3.UP))

func capture(id: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/lock-framing-%s-native.jpg"%id)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	for kind in ["Raider","Cinder beast"]:
		await scenario(kind)
		check(kind+" lock keeps both combatants in frame",game.combat.target==opponent and framed())
		check(kind+" head remains visible past the player",head_unobstructed())
		await capture(kind.to_lower().replace(" ","-"))
	var difference: Vector3 = opponent.position-player.position
	check("Wrench user faces the locked enemy directly",absf(wrapf(player.visual.rotation.y-atan2(-difference.x,-difference.z),-PI,PI))<0.02)
	game._set_paused(true)
	var pose: Transform3D = game.orbit.camera.global_transform
	await frames(45)
	check("Pause preserves lock framing",game.combat.target==opponent and game.orbit.camera.global_transform.is_equal_approx(pose))
	game._set_paused(false)
	game.world.enabled = false
	opponent.brain.enabled = false
	await press("lock_target")
	await press("look_right",20)
	var yaw: float = game.orbit.yaw
	await frames(30)
	check("Unlock returns independent centered orbit",game.combat.target==null and absf(game.orbit.lateral_offset)<0.01 and absf(game.orbit.yaw-yaw)<0.01)
	await scenario("Cinder beast",8)
	game.combat.equip("RIFLE")
	await frames(60)
	check("Rifle retains shoulder framing with a distant lock",game.combat.target==opponent and framed() and head_unobstructed() and game.orbit.lateral_offset>0.5)
	opponent.position += Vector3(5,0,0)
	await frames(90)
	check("Lock follows a target crossing the view",game.combat.target==opponent and framed())
	var wall := BlockoutKit.box(game,(opponent.position+player.position)*0.5+Vector3.UP,Vector3(8,4,0.3),Color("796957"),true)
	await frames(12)
	check("New cover releases the lock",game.combat.target==null)
	wall.queue_free()
	await scenario("Raider",8)
	opponent.position.z -= 35
	await frames(12)
	check("Leaving lock range releases the camera",game.combat.target==null and absf(game.orbit.lateral_offset)<0.01)
	await scenario("Raider",5)
	opponent.health.take_damage(999,&"player")
	await frames(12)
	check("Dead target releases lock and melee offset",game.combat.target==null and absf(game.orbit.lateral_offset)<0.01)
	await finish_report("lock_framing","37 visible locked combatants",started,"--verify-lock_framing")
