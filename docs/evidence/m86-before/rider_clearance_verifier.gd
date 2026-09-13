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
	seat.enter()
	var beam := BlockoutKit.box(game,Vector3(0,32.20,100),Vector3(3,0.16,0.3),Color("655645"),true)
	await frames(3)
	await press("move_forward",180)
	check("Driving stops before an overhead beam crosses the rider",seat.mounted and bike.position.z>99.8 and bike.position.z<102 and absf(bike.speed)<0.2,"position=%s speed=%.3f"%[bike.position,bike.speed])
	beam.queue_free()
	platform.queue_free()
	await finish_report("rider_clearance","86 seated rider collision",started,"--verify-rider_clearance")
