extends "res://tests/cart_verifier.gd"

func walk_to(target: Node3D) -> void:
	if seat.mounted: seat.leave(true)
	player.position = target.position+Vector3(0,0.15,2.5)
	player.velocity = Vector3.ZERO
	await frames(20)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var logi: LogisticsWorld = game.logistics
	var pack: Inventory = game.hitch.backpack
	var cart: CargoCart = game.cart
	var source: ResourceSource = logi.sources[0]
	var saved_player := player.position
	var saved_bike := bike.position
	var saved_cart := cart.position
	var start_stock := source.stock.count("olive")
	var query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	query.shape = capsule
	query.collision_mask = 1
	var accessible := true
	for station: Node3D in logi.sources+logi.stations:
		query.transform.origin = station.position+Vector3.UP*0.95
		accessible = accessible and game.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
	check("All logistics endpoints are outside solid buildings",accessible)
	await walk_to(source)
	await press("use_resource")
	check("Player input gathers from resource",pack.count("olive")==1 and source.stock.count("olive")==start_stock-1)
	pack.add("ore",14)
	pack.add("olive",3)
	check("Full pack rejects gathering without consuming source",not logi.use_station(source) and source.stock.count("olive")==start_stock-1)
	pack.remove("ore",14)
	await walk_to(logi.warehouse)
	await press("use_resource")
	check("Warehouse stores gathered goods",pack.count("olive")==0 and logi.warehouse.inventory.count("olive")==4)
	Input.action_press("sprint")
	await press("use_resource")
	release()
	check("Warehouse withdrawal preserves goods",pack.count("olive")==4 and logi.warehouse.inventory.count("olive")==0)
	await walk_to(logi.market)
	var balance := logi.shop.credits
	await press("use_resource")
	check("Selling delivers stock and credits",pack.count("olive")==0 and logi.market.inventory.count("olive")==4 and logi.shop.credits==balance+16)
	check("Selling absent goods cannot mint money",not logi.shop.sell(pack,"olive",1) and logi.shop.credits==balance+16)
	Input.action_press("sprint")
	await press("use_resource")
	release()
	check("Buying transfers stock and charges money",pack.count("olive")==1 and logi.market.inventory.count("olive")==3 and logi.shop.credits==balance+8)
	check("Unaffordable purchase leaves both sides unchanged",not logi.shop.buy(pack,"olive",999) and logi.shop.credits==balance+8 and pack.count("olive")==1)
	check("Negative trade rejected",not logi.shop.buy(pack,"olive",-1) and not logi.shop.sell(pack,"olive",-1))
	check("Remote station use rejected",not logi.use_station(logi.dispatch))
	# Drive one real route: accept a parcel near the courier desk, hitch, transport, deliver.
	await place(Vector2(12,6))
	var initial_direction := logi.destination.position-bike.position
	bike.rotation.y = atan2(-initial_direction.x,-initial_direction.z)
	cart.rotation.y = bike.rotation.y
	cart.position = bike.position+bike.global_basis.z*3.3+Vector3.UP*0.2
	cart.velocity = Vector3.ZERO
	await frames(20)
	await walk_to(logi.dispatch)
	await press("use_resource")
	check("Accept delivery loads one parcel",logi.contract.state=="IN_TRANSIT" and cart.inventory.count("package")==1)
	check("Duplicate acceptance cannot duplicate parcel",not logi.use_station(logi.dispatch) and cart.inventory.count("package")==1)
	check("Parcel cannot be sold as commodity",not logi.shop.sell(cart.inventory,"package",1) and cart.inventory.count("package")==1)
	player.position = bike.position+Vector3(1.65,0.1,0)
	await frames(15)
	await press("interact")
	await press("hitch_cart")
	check("Delivery vehicle is mounted and hitched",seat.mounted and cart.tow_vehicle==bike)
	var from := bike.position
	var goal := logi.destination.position
	var direction := goal-bike.position
	# Input drives a straight, known open route; braking uses stopping distance.
	var iterations := 0
	while iterations<900:
		direction = goal-bike.position
		direction.y = 0
		if direction.length()<3.5 and absf(bike.speed)<0.5: break
		var angle := wrapf(atan2(-direction.x,-direction.z)-bike.rotation.y,-PI,PI)
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(angle)>0.025 and direction.length()>3.5:
			Input.action_press("move_left" if angle>0 else "move_right")
		var desired_speed := minf(12,maxf(0,(direction.length()-2.5)*1.0))
		if bike.speed>desired_speed or direction.length()<3.5:
			Input.action_release("move_forward")
			Input.action_press("jump")
		else:
			Input.action_release("jump")
			Input.action_press("move_forward")
		await frames(1)
		iterations += 1
	release()
	await press("jump",20)
	check("Cargo route physically traversed",bike.position.distance_to(from)>45 and bike.position.distance_to(logi.destination.position)<4.5,"distance=%.2f to target=%.2f"%[bike.position.distance_to(from),bike.position.distance_to(logi.destination.position)])
	check("Parcel stays in cart during delivery route",cart.inventory.count("package")==1 and cart.position.distance_to(bike.position)<4.6)
	balance = logi.shop.credits
	await press("use_resource")
	check("Arrival unloads parcel and rewards player",logi.contract.state=="COMPLETED" and cart.inventory.count("package")==0 and logi.shop.credits==balance+75)
	check("Repeated delivery cannot duplicate reward",not logi.use_station(logi.destination) and logi.shop.credits==balance+75)
	var other := DeliveryContract.new()
	var full := Inventory.new()
	full.capacity = 0
	check("Full cargo prevents accepting contract",not other.accept(full) and other.state=="AVAILABLE")
	var reentrant := DeliveryContract.new()
	var one := Inventory.new()
	var two := Inventory.new()
	one.changed.connect(func(): reentrant.accept(two))
	check("Contract acceptance resists signal reentrancy",reentrant.accept(one) and one.count("package")==1 and two.count("package")==0)
	game._set_paused(true)
	check("Paused logistics actions rejected",not logi.use_station(logi.destination))
	game._set_paused(false)
	# Stock exhaustion cannot become negative even with competing callers.
	var limited := Inventory.new()
	limited.capacity = 1000
	var remaining := source.stock.count("olive")
	source.gather(limited,remaining)
	check("Depleted source rejects further extraction",not source.gather(pack) and source.stock.count("olive")==0)
	limited.transfer_to(source.stock,"olive",remaining)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		logi.panel.visible = true
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/logistics-native-delivery.jpg")
	game.hitch.toggle()
	seat.leave(true)
	bike.position = saved_bike
	cart.position = saved_cart
	cart.velocity = Vector3.ZERO
	player.position = saved_player
	game.orbit.snap()
	await finish_report("logistics","06 resources and delivery economy",started,"--verify-logistics")
