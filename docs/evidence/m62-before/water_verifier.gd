extends "res://tests/worker_verifier.gd"
var recoveries := [0,0]

func on_foot(at: Vector2) -> void:
	release()
	if seat.mounted: seat.leave(true)
	player.position = Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+0.15,at.y)
	player.velocity = Vector3.ZERO
	game.orbit.yaw = 0
	await frames(20)

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var cart: CargoCart = game.cart
	var garage := cart.position
	player.recovered.connect(func(): recoveries[0]+=1)
	bike.recovered.connect(func(): recoveries[1]+=1)
	game.hitch.backpack.add("wood",5)
	await on_foot(Vector2(0,80))
	Input.action_press("move_forward")
	await frames(40)
	check("Dry traversal keeps normal walking speed",Vector2(player.velocity.x,player.velocity.z).length()>4.3 and player.surface_speed_multiplier==1)
	await on_foot(Vector2(101,7.5))
	Input.action_press("move_forward")
	await frames(30)
	check("Shallow coastal water permits slower wading",player.surface_speed_multiplier<1 and Vector2(player.velocity.x,player.velocity.z).length()>1.8 and Vector2(player.velocity.x,player.velocity.z).length()<3.3,"speed=%.2f y=%.2f"%[player.velocity.length(),player.position.y])
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/water-native-wading.jpg")
	await on_foot(Vector2(106,7.5))
	check("Deep-water recovery state cannot be saved",player.is_on_floor() and not game.saves.can_save())
	game._set_paused(true)
	var paused_at := player.position
	await frames(150)
	check("Pause freezes submerged actor and recovery countdown",recoveries[0]==0 and player.position.distance_to(paused_at)<0.001)
	game._set_paused(false)
	await frames(150)
	check("Deep water returns player to survey checkpoint with pack intact",recoveries[0]==1 and player.position.distance_to(player.spawn_position)<1 and game.hitch.backpack.count("wood")==5)
	check("Dry recovery clears wading slowdown",player.surface_speed_multiplier==1 and player.is_on_floor())
	# Use the real beach gap between coastal rocks at z=0 and z=15.
	await place(Vector2(96,7.5))
	bike.rotation.y = -PI/2
	cart.position = bike.position+bike.global_basis.z*3.3+Vector3.UP*0.2
	cart.position.y = CoastalRegion.height_at(cart.position.x,cart.position.z)+0.2
	cart.rotation.y = bike.rotation.y
	cart.velocity = Vector3.ZERO
	cart.inventory.add("olive",10)
	await frames(30)
	var mounted := seat.enter()
	var hitched: bool = game.hitch.toggle()
	check("Shoreline test begins with a real loaded hitch",mounted and hitched)
	Input.action_press("move_forward")
	var recovered_bike := await until(func(): return recoveries[1]>0,450)
	release()
	await frames(30)
	check("Riding into deep water recovers bike and attached cargo together",recovered_bike and game.water!=null and game.water.bike_recoveries==1 and seat.mounted and bike.position.distance_to(bike.home)<1 and cart.tow_vehicle==bike and cart.inventory.count("olive")==10 and cart.position.distance_to(bike.position)<4.6,"events=%s water=%d mounted=%s bike=%s gap=%.2f speed=%.2f"%[recoveries,game.water.bike_recoveries if game.water else -1,seat.mounted,bike.position,cart.position.distance_to(bike.position),bike.speed])
	if cart.tow_vehicle: game.hitch.toggle()
	if seat.mounted: seat.leave(true)
	cart.position = Vector3(110,CoastalRegion.height_at(110,0)+0.2,0)
	cart.velocity = Vector3.ZERO
	await frames(180)
	check("Detached submerged cart returns to workshop without losing goods",cart.position.distance_to(garage)<1 and cart.inventory.count("olive")==10 and cart.tow_vehicle==null)
	# Only fixture setup; takeoff and subsequent water approach use flight inputs.
	await place(Vector2(60,50))
	bike.rotation.y = -PI/2
	seat.enter()
	await press("transform_vehicle")
	await frames(80)
	Input.action_press("move_forward")
	await frames(110)
	Input.action_press("jump")
	await frames(100)
	var before: int = recoveries[1]
	var water_before: int = game.water.bike_recoveries if game.water else 0
	check("Flying over water does not trigger recovery",bike.flight.airborne and bike.position.x>100 and bike.position.y>5,"position=%s"%bike.position)
	release()
	Input.action_press("move_back")
	Input.action_press("dodge")
	var sea_landing := await until(func(): return recoveries[1]>before,900)
	release()
	await frames(30)
	check("Water landing recovers the same aircraft and preserves parked cargo",sea_landing and game.water!=null and game.water.bike_recoveries==water_before+1 and seat.mounted and bike.transformation.mode=="BIKE" and bike.position.distance_to(bike.home)<1 and cart.inventory.count("olive")==10 and game.hitch.backpack.count("wood")==5,"events=%s water=%d mounted=%s bike=%s mode=%s cargo=%s pack=%s"%[recoveries,game.water.bike_recoveries if game.water else -1,seat.mounted,bike.position,bike.transformation.mode,cart.inventory.summary(),game.hitch.backpack.summary()])
	check("Water volume stays within the displayed coast",WaterBody.new().depth_at(Vector3(13000,-5,0))==0 and WaterBody.new().depth_at(Vector3(0,-5,1000))==0)
	await finish_report("water","26 wading and deep-water recovery",started,"--verify-water")
