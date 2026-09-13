extends "res://tests/bike_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var cart: CargoCart = game.cart
	var hitch: HitchSystem = game.hitch
	var saved_player := player.position
	var saved_bike := bike.position
	var saved_cart := cart.position
	var pack := hitch.backpack
	check("Unknown/negative inventory mutations rejected",not pack.add("fake",1) and not pack.add("ore",-3) and not pack.remove("ore",-1))
	check("Inventory obeys weight limit",pack.add("ore",15) and not pack.add("ore",1) and pack.mass()==60)
	check("Oversized transfer leaves source unchanged",not pack.transfer_to(cart.inventory,"ore",16) and pack.count("ore")==15 and cart.inventory.count("ore")==0)
	check("Self transfer rejected",not pack.transfer_to(pack,"ore",1))
	var view := pack.contents()
	view["ore"] = 999
	check("Inventory snapshots cannot mutate live cargo",pack.count("ore")==15)
	check("Atomic cargo transfer",pack.transfer_to(cart.inventory,"ore",15) and pack.count("ore")==0 and cart.inventory.count("ore")==15)
	cart.inventory.add("ore",25)
	check("Cart capacity enforced",cart.inventory.mass()==160 and not pack.add("package",9) and not cart.inventory.add("olive",1))
	await place()
	cart.position = bike.position+Vector3(0,0.2,3.3)
	cart.velocity = Vector3.ZERO
	cart.rotation = Vector3.ZERO
	await frames(30)
	await press("interact")
	await press("hitch_cart")
	check("Input hitches nearby grounded cart",cart.tow_vehicle==bike and bike.cart_attached)
	check("Loaded mass reaches drive controller",bike.cargo_mass==180)
	check("Hitch prevents unsafe wing deployment",not bike.transformation.request_toggle() and bike.transformation.mode=="BIKE")
	var from := bike.position
	Input.action_press("move_forward")
	await frames(120)
	check("Loaded bike accelerates more slowly",bike.speed>3 and bike.speed<8,"speed=%.2f"%bike.speed)
	check("Loaded cart physically follows",cart.travelled>3 and cart.position.distance_to(bike.position)<4.5 and bike.position.distance_to(from)>4)
	check("Cargo survives movement",cart.inventory.count("ore")==40)
	check("Moving hitch toggle rejected",not hitch.toggle() and cart.tow_vehicle==bike)
	release()
	await press("jump",60)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/cart-native-loaded.jpg")
	check("Stopped cart detaches",hitch.toggle() and cart.tow_vehicle==null and bike.cargo_mass==0)
	from = cart.position
	await press("move_forward",75)
	check("Detached cart remains parked",cart.position.distance_to(from)<0.15 and cart.inventory.count("ore")==40)
	release()
	await press("jump",60)
	check("Remote reattachment rejected",not hitch.toggle())
	bike.position = cart.position-Vector3(0,0,3.3)
	bike.velocity = Vector3.ZERO
	bike.speed = 0
	await frames(15)
	check("Nearby cart reattaches",hitch.toggle())
	check("Unload respects backpack capacity",hitch.move_cargo(true)==15 and pack.mass()==60 and cart.inventory.count("ore")==25)
	check("Total cargo conserved",pack.count("ore")+cart.inventory.count("ore")==40)
	check("Full backpack does not lose cargo",hitch.move_cargo(true)==0 and cart.inventory.count("ore")==25)
	game._set_paused(true)
	from = cart.position
	await frames(20)
	check("Pause freezes cart and transfer controls",cart.position.distance_to(from)<0.001 and not hitch.toggle() and hitch.move_cargo()==0)
	game._set_paused(false)
	bike.recover()
	await frames(10)
	check("Recovery preserves attached cargo",cart.tow_vehicle==bike and cart.position.distance_to(bike.position)<4.5 and cart.inventory.count("ore")==25)
	hitch.toggle()
	seat.leave(true)
	cart.position = Vector3(32,CoastalRegion.height_at(32,20)+0.1,20)
	cart.rotation = Vector3.ZERO
	await frames(20)
	cart.velocity = Vector3(15,0,0)
	await frames(60)
	check("Cart collides with world wall",cart.position.x<35.3,"x=%.2f"%cart.position.x)
	await place()
	cart.position = bike.position+Vector3(0,0.2,3.3)
	cart.rotation = Vector3.ZERO
	cart.velocity = Vector3.ZERO
	await frames(25)
	await press("interact")
	hitch.toggle()
	var barrier := BlockoutKit.box(game,bike.position+Vector3(0,2,1.95),Vector3(5,4,0.3),Color("987e60"),true)
	await frames(5)
	await press("move_forward",140)
	check("Trapped cart stops towing bike without stretching",cart.position.distance_to(bike.position)<5.5 and bike.speed<0.5,"gap=%.2f speed=%.2f"%[cart.position.distance_to(bike.position),bike.speed])
	barrier.queue_free()
	release()
	bike.speed = 0
	hitch.toggle()
	seat.leave(true)
	pack.remove("ore",pack.count("ore"))
	cart.inventory.remove("ore",cart.inventory.count("ore"))
	bike.position = saved_bike
	cart.position = saved_cart
	cart.velocity = Vector3.ZERO
	player.position = saved_player
	game.orbit.snap()
	await finish_report("cart","05 cargo and inventory",started,"--verify-cart")

func finish_report(id: String, milestone: String, started: int, flag: String) -> void:
	var passed := checks.filter(func(c): return c.passed).size()
	var report := {"milestone":milestone,"passed":passed,"total":checks.size(),"platform":OS.get_name(),"elapsed_seconds":(Time.get_ticks_msec()-started)/1000.0,"tests":checks}
	print("RSB_",id.to_upper(),"_REPORT ",JSON.stringify(report))
	game.hud.verified_label.text = "%s: %d / %d PASSED" % [id.to_upper(),passed,checks.size()]
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(()=>{let p=document.createElement('pre');p.id='%s-report';p.style='position:fixed;right:16px;top:16px;max-height:65vh;overflow:auto;max-width:460px;padding:16px;background:#152d29;color:#f4e3bb;z-index:10;font:12px monospace';p.textContent=%s;document.body.appendChild(p)})()" % [id,JSON.stringify(JSON.stringify(report,"  "))],true)
	else:
		var file := FileAccess.open("res://docs/evidence/%s-native-report.json"%id,FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"  "))
	if flag in OS.get_cmdline_user_args(): get_tree().quit(0 if passed==checks.size() else 1)
