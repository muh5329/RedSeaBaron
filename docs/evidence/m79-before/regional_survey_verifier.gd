extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	game.encounters.set_enabled(false)
	for region: RegionDefinition in RegionCatalog.all():
		var at := region.center+Vector2(-12,8)
		player.position = Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+0.2,at.y+1.5)
		player.velocity = Vector3.ZERO
		await frames(90)
		await press("interact")
		check(region.title+" can establish a nearby recovery checkpoint",Vector2(player.spawn_position.x-at.x,player.spawn_position.z-at.y).length()<3,"checkpoint=%s"%player.spawn_position)
	await finish_report("regional_survey","79 regional survey checkpoints",started,"--verify-regional_survey")
