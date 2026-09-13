extends "res://tests/worker_verifier.gd"
var cart: CargoCart

func wheel_motion(action: String, ticks: int) -> Dictionary:
	var start := cart.position
	var previous := cart.wheels[0].rotation.x
	var spin := 0.0
	if not action.is_empty(): Input.action_press(action)
	for i in range(ticks):
		await frames(1)
		var current := cart.wheels[0].rotation.x
		spin += angle_difference(previous,current)
		previous = current
	release()
	return {"spin":spin,"travel":cart.position-start}

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
	await frames(40)
	cart.inventory.add("ore",10)
	seat.enter()
	game.hitch.toggle()
	var forward := await wheel_motion("move_forward",120)
	check("Physical forward towing spins cargo wheels forward",forward.travel.z< -3 and forward.spin< -3,"travel=%s spin=%.3f"%[forward.travel,forward.spin])
	await press("jump",75)
	var reverse := await wheel_motion("move_back",120)
	check("Physical reverse towing reverses cargo wheel spin",reverse.travel.z>1 and reverse.spin>1,"travel=%s spin=%.3f"%[reverse.travel,reverse.spin])
	await press("jump",75)
	game.hitch.toggle()
	cart.position = Vector3(12,36,110)
	cart.velocity = Vector3.ZERO
	var fall := await wheel_motion("",100)
	check("Vertical cargo landing does not roll the tires",cart.is_on_floor() and fall.travel.y< -5 and absf(fall.spin)<0.05,"travel=%s spin=%.3f"%[fall.travel,fall.spin])
	platform.queue_free()
	await finish_report("cart_wheel","83 signed cargo wheel travel",started,"--verify-cart_wheel")
