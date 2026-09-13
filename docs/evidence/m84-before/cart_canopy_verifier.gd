extends "res://tests/worker_verifier.gd"
var cart: CargoCart

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	cart = game.cart
	var started := Time.get_ticks_msec()
	await place(Vector2(0,110))
	game.world.enabled = false
	var platform := BlockoutKit.box(game,Vector3(0,29.5,110),Vector3(80,1,120),Color("937957"),true)
	bike.position = Vector3(0,30.2,110)
	bike.velocity = Vector3.ZERO
	cart.position = bike.position+Vector3(0,0.1,3.3)
	cart.rotation = Vector3.ZERO
	cart.velocity = Vector3.ZERO
	player.position = bike.position+Vector3(1.65,0.1,0)
	player.velocity = Vector3.ZERO
	await frames(60)
	cart.inventory.add("ore",40)
	for x in [0.0,-0.6,0.6]:
		var top := cart.visual.global_transform*Vector3(x,1.78+0.60*sqrt(1-pow(x/0.86,2)),0)
		var hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(top+Vector3.UP,top-Vector3.UP*2,16))
		check("Curved cart cover has matching physical height at x=%.1f"%x,not hit.is_empty() and hit.position.distance_to(top)<0.04,"hit=%s expected=%s"%[hit.get("position",Vector3.ZERO),top])
	seat.enter()
	game.hitch.toggle()
	# An upper side beam misses the motorcycle chassis but crosses tall cargo/cover.
	var beam := BlockoutKit.box(game,Vector3(0.8,31.85,100),Vector3(0.7,0.6,0.6),Color("655645"),true)
	await frames(3)
	await press("move_forward",360)
	check("Upper cargo obstruction stops the complete towing assembly",cart.position.z>101.2 and cart.position.z<103 and absf(bike.speed)<0.2 and cart.position.distance_to(bike.position)<4.6 and cart.inventory.count("ore")==40,"cart=%s speed=%.3f gap=%.3f"%[cart.position,bike.speed,cart.position.distance_to(bike.position)])
	beam.queue_free()
	platform.queue_free()
	await finish_report("cart_canopy","84 covered expedition cart",started,"--verify-cart_canopy")
