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
	check("Wheel fixture mounts and hitches a loaded cart",seat.enter() and game.hitch.toggle() and bike.cargo_mass==60)
	var forward := await wheel_motion("move_forward",120)
	check("Physical forward towing rolls the expected tire distance",forward.travel.z< -3 and forward.spin< -3 and absf(forward.spin-forward.travel.z/0.44)<0.1,"travel=%s spin=%.3f"%[forward.travel,forward.spin])
	await press("jump",75)
	var reverse := await wheel_motion("move_back",120)
	check("Physical reverse towing reverses cargo wheel spin",reverse.travel.z>1 and reverse.spin>1 and absf(reverse.spin-reverse.travel.z/0.44)<0.1,"travel=%s spin=%.3f"%[reverse.travel,reverse.spin])
	await press("jump",75)
	bike.position = Vector3(0,30.2,110)
	bike.rotation.y = PI/2
	bike.velocity = Vector3.ZERO
	bike.speed = 0
	cart.position = bike.position+bike.global_basis.z*3.3
	cart.rotation.y = PI/2
	cart.velocity = Vector3.ZERO
	await frames(40)
	var west := await wheel_motion("move_forward",120)
	check("Rolling direction follows the turned cart rather than world Z",west.travel.x< -3 and absf(west.travel.z)<1 and west.spin< -3 and absf(west.spin+Vector2(west.travel.x,west.travel.z).length()/0.44)<0.1,"travel=%s spin=%.3f"%[west.travel,west.spin])
	await press("jump",75)
	var ramp := BlockoutKit.box(game,Vector3(0,69.5,110),Vector3(60,1,80),Color("937957"),true)
	ramp.rotation.x = deg_to_rad(15)
	bike.position = Vector3(0,73,110)
	bike.rotation = Vector3.ZERO
	bike.velocity = Vector3.ZERO
	bike.speed = 0
	cart.position = bike.position+Vector3(0,0.1,3.3)
	cart.rotation = Vector3.ZERO
	cart.velocity = Vector3.ZERO
	await frames(100)
	var uphill := await wheel_motion("move_forward",120)
	check("Uphill tire rotation includes the inclined ground distance",bike.is_on_floor() and cart.is_on_floor() and uphill.travel.length()>3 and absf(uphill.spin+uphill.travel.length()/0.44)<0.2,"travel=%s spin=%.3f expected=%.3f"%[uphill.travel,uphill.spin,-uphill.travel.length()/0.44])
	await press("jump",75)
	game.hitch.toggle()
	cart.position = Vector3(12,36,110)
	cart.velocity = Vector3.ZERO
	var fall := await wheel_motion("",100)
	check("Vertical cargo landing does not roll the tires",cart.is_on_floor() and fall.travel.y< -5 and absf(fall.spin)<0.05,"travel=%s spin=%.3f"%[fall.travel,fall.spin])
	var parked := await wheel_motion("",100)
	check("Parked cargo tires do not creep",parked.travel.length()<0.01 and absf(parked.spin)<0.02)
	check("Wheel presentation preserves cargo and detached ownership",cart.inventory.count("ore")==10 and cart.tow_vehicle==null and not bike.cart_attached)
	ramp.queue_free()
	platform.queue_free()
	await finish_report("cart_wheel","83 signed cargo wheel travel",started,"--verify-cart_wheel")
