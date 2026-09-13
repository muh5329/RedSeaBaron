extends "res://tests/worker_verifier.gd"

func drive_to(at: Vector2, max_frames: int = 1500) -> bool:
	var count := 0
	while count<max_frames:
		var offset := Vector2(at.x-bike.position.x,at.y-bike.position.z)
		if offset.length()<3.7 and absf(bike.speed)<0.5: break
		var heading := wrapf(atan2(-offset.x,-offset.y)-bike.rotation.y,-PI,PI)
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(heading)>0.035 and offset.length()>3.7:
			Input.action_press("move_left" if heading>0 else "move_right")
		var speed_limit := minf(10 if absf(heading)<0.35 else 4.5,maxf(0,offset.length()-2.8))
		if bike.speed>speed_limit or offset.length()<3.7:
			Input.action_release("move_forward")
			Input.action_press("jump")
		else:
			Input.action_release("jump")
			Input.action_press("move_forward")
		await frames(1)
		count += 1
	release()
	await press("jump",20)
	print("INTEGRATION_LEG goal=%s position=%s error=%.2f frames=%d speed=%.2f"%[at,bike.position,Vector2(at.x-bike.position.x,at.y-bike.position.z).length(),count,bike.speed])
	return Vector2(at.x-bike.position.x,at.y-bike.position.z).length()<4.5


func walk_near(target: Node3D, radius: float = 2.4) -> bool:
	var count := 0
	while player.position.distance_to(target.position)>radius and count<600:
		var offset := (target.position-player.position).rotated(Vector3.UP,-game.orbit.yaw)
		for action in ["move_left","move_right","move_forward","move_back"]: Input.action_release(action)
		if absf(offset.x)>0.25: Input.action_press("move_right" if offset.x>0 else "move_left")
		if absf(offset.z)>0.25: Input.action_press("move_back" if offset.z>0 else "move_forward")
		await frames(1)
		count += 1
	release()
	await frames(6)
	return player.position.distance_to(target.position)<3.0

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	worker = game.workers.workers[0]
	var started := Time.get_ticks_msec()
	var logi: LogisticsWorld = game.logistics
	# Only initial fixture placement; every leg after accepting the parcel uses locomotion.
	await place(Vector2(12,6))
	bike.rotation.y = PI
	game.cart.rotation.y = PI
	game.cart.position = bike.position+bike.global_basis.z*3.3+Vector3.UP*0.15
	player.position = logi.dispatch.position+Vector3(0,0.1,2.5)
	await frames(20)
	await press("use_resource")
	check("Integration accepts a real parcel into cart",logi.contract.state=="IN_TRANSIT" and game.cart.inventory.count("package")==1)
	# Walk from desk to motorcycle with camera-relative controls.
	game.orbit.yaw = 0
	var walk_steps := 0
	while player.position.distance_to(bike.position)>2.8 and walk_steps<360:
		var offset := bike.position-player.position
		Input.action_release("move_forward")
		Input.action_release("move_back")
		Input.action_release("move_left")
		Input.action_release("move_right")
		if absf(offset.x)>0.5: Input.action_press("move_right" if offset.x>0 else "move_left")
		if absf(offset.z)>0.5: Input.action_press("move_back" if offset.z>0 else "move_forward")
		await frames(1)
		walk_steps += 1
	release()
	await frames(10)
	await press("interact")
	await press("hitch_cart")
	check("Integration mounts and hitches loaded vehicle",seat.mounted and bike.cart_attached)
	var distance_start := bike.travelled
	var arrived := await drive_to(Vector2(12,43))
	arrived = await drive_to(Vector2(-44,43)) and arrived
	arrived = await drive_to(Vector2(-57,23)) and arrived
	check("Loaded route reaches hostile encounter physically",arrived and bike.travelled-distance_start>85,"position=%s distance=%.1f"%[bike.position,bike.travelled-distance_start])
	await press("interact")
	check("Encounter dismount restores combat controls",not seat.mounted and game.combat.enabled)
	var enemy: EnemyActor = game.enemies[0]
	await press("lock_target")
	check("Player closes to melee range on foot",await walk_near(enemy))
	await frames(35)
	var before_health := enemy.health.current
	await press("attack")
	await frames(40)
	check("Wrench damages encountered hostile",enemy.health.current<before_health and enemy.health.current>0,"enemy HP=%.1f"%enemy.health.current)
	await press("equip_rifle")
	await frames(20)
	await press("attack")
	await frames(45)
	await press("attack")
	await frames(20)
	check("Rifle finishes encounter using real ammunition",enemy.health.current<=0 and game.combat.ammunition<=3 and game.combat.health.current>0)
	check("Parcel survives combat and dismount",game.cart.inventory.count("package")==1 and logi.contract.state=="IN_TRANSIT")
	# Return on foot after the encounter; remount remains range-gated.
	check("Player returns to motorcycle on foot",await walk_near(bike))
	await press("interact")
	check("Remount restores exclusive vehicle ownership",seat.mounted and not game.combat.enabled and game.orbit.follow_target==bike.camera_anchor)
	# Leave the encounter via a broad turnaround, keeping the loaded trailer clear.
	arrived = await drive_to(Vector2(-72,23))
	arrived = await drive_to(Vector2(-72,43)) and arrived
	arrived = await drive_to(Vector2(-44,43)) and arrived
	arrived = await drive_to(Vector2(10,55)) and arrived
	arrived = await drive_to(Vector2(39,67)) and arrived
	check("Return route carries parcel to delivery quay",arrived and game.cart.inventory.count("package")==1,"position=%s"%bike.position)
	var balance := logi.shop.credits
	await press("use_resource")
	check("Integrated trip unloads and pays exactly once",logi.contract.state=="COMPLETED" and logi.shop.credits==balance+75 and game.cart.inventory.count("package")==0)
	await press("workers")
	await press("job_farm")
	check("Player assigns worker after vehicle delivery",worker.executor.job!=null and worker.executor.job.kind=="Farm")
	var done := await until(idle,3000)
	check("Worker harvest completes while player remains at quay",done and logi.warehouse.inventory.count("olive")==5)
	game.workers.order("ShopKeep")
	done = await until(idle,1200)
	check("Harvest reaches economy without micromanagement",done and logi.market.inventory.count("olive")==5 and logi.shop.credits==balance+95)
	check("Integrated session retains one player and valid cargo",seat.mounted and not player.visible and game.cart.inventory.mass()==0 and worker.inventory.mass()==0 and game.combat.health.current>0)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/integration-native-complete.jpg")
	await finish_report("integration","12 combat delivery worker integration",started,"--verify-integration")
