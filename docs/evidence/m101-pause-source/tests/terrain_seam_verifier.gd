extends "res://tests/worker_verifier.gd"

func drive(count: int) -> Dictionary:
	var from := bike.position
	var late := from
	var stalled := 0
	Input.action_press("move_forward")
	for i in range(count):
		await frames(1)
		if i==count-60: late = bike.position
		if i>60 and bike.speed<1: stalled += 1
	release()
	return {"distance":from.distance_to(bike.position),"late_distance":late.distance_to(bike.position),"stalled":stalled,"speed":bike.speed}

func setup(at: Vector2, yaw: float) -> bool:
	await place(at)
	bike.rotation.y = yaw
	bike.set_physics_process(true)
	await frames(20)
	return seat.enter()

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await frames(60)
	game.world.enabled = false
	for route in [[Vector2(0.02,108),0.0,"North"],[Vector2(-0.02,80),PI,"South"],[Vector2(-16,88),-PI/2,"East"],[Vector2(16,96),PI/2,"West"]]:
		check(route[2]+" seam fixture mounts normally",await setup(route[0],route[1]))
		var result := await drive(150)
		check(route[2]+" drive crosses multiple real terrain grid lines",result.distance>18 and result.speed>15,"travel=%.3f speed=%.3f"%[result.distance,result.speed])
		check(route[2]+" drive cannot settle into a seam soft lock",result.stalled==0 and result.late_distance>10,"stalled frames=%d last-second travel=%.3f"%[result.stalled,result.late_distance])
		await press("jump",90)
	await setup(Vector2(0,80),PI)
	var cart: CargoCart = game.cart
	cart.position = bike.position+bike.global_basis.z*3.3+Vector3.UP*0.15
	cart.rotation = bike.rotation
	cart.velocity = Vector3.ZERO
	cart.enabled = true
	cart.inventory.add("ore",20)
	await frames(30)
	check("Loaded seam fixture uses the normal hitch",game.hitch.toggle() and bike.cargo_mass==100)
	var loaded := await drive(240)
	check("Loaded cart crosses the seam without a stalled tow vehicle",loaded.distance>18 and loaded.speed>8 and loaded.stalled==0,"travel=%.3f speed=%.3f stalls=%d"%[loaded.distance,loaded.speed,loaded.stalled])
	check("Seam travel preserves cargo and the physical drawbar",cart.inventory.count("ore")==20 and bike.position.distance_to(cart.position)<4.6)
	await press("jump",100)
	game.hitch.toggle()
	check("Real-wall control mounts normally",await setup(Vector2(0,80),PI))
	var floor_y := CoastalRegion.height_at(0,88)
	var wall := BlockoutKit.box(game,Vector3(0,floor_y+2,88),Vector3(8,4,0.3),Color("937957"),true)
	await frames(3)
	await drive(180)
	check("A real wall at the same grid boundary still stops the motorcycle",bike.position.z<86.6 and absf(bike.speed)<0.2,"position=%s speed=%.3f"%[bike.position,bike.speed])
	check("Collision recovery cannot climb the real wall",bike.position.y<floor_y+0.5)
	wall.queue_free()
	await finish_report("terrain_seam","76 terrain seams and real obstacle distinction",started,"--verify-terrain_seam")
