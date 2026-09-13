extends "res://tests/worker_verifier.gd"

func reach_to(source: Node3D) -> float:
	var arm := worker.visual.right_arm
	var hand := arm.to_global(Vector3(0,-0.52,-0.02))
	var direction := source.global_position-arm.global_position
	direction.y = 0
	return (hand-arm.global_position).dot(direction.normalized())

func capture_work() -> void:
	if DisplayServer.get_name()=="headless" or "--capture" not in OS.get_cmdline_user_args(): return
	game.hud.menu.visible = false
	game.hud.verified_label.visible = false
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.position = worker.position+worker.visual.global_basis.x*3-worker.visual.global_basis.z*1.5+Vector3.UP*2.2
	camera.look_at(worker.position+Vector3.UP*1.2-worker.visual.global_basis.z*0.3)
	camera.current = true
	await frames(2)
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_jpg("res://docs/evidence/worker-reach-m91.jpg")
	game.orbit.camera.current = true
	camera.queue_free()
	game.hud.menu.visible = true

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await until(func(): return game.workers.navigation.ready_for_paths,300)
	worker = game.workers.worker_by_id("mara")
	var job: JobDefinition = game.workers.make_job("Farm")
	var source: ResourceSource = job.source
	var stock := source.stock.count(job.item_id)
	var stored := job.destination.inventory.count(job.item_id)
	worker.position = job.source.position+Vector3(0,0.3,4)
	worker.velocity = Vector3.ZERO
	player.position = job.source.position+Vector3(4,0.3,4)
	player.velocity = Vector3.ZERO
	await frames(30)
	var assigned := worker.assign(job)
	var working := await until(func(): return worker.machine.current==&"PerformTask",400)
	check("Actual farmer job reaches visible work after acquiring goods",assigned and working and worker.executor.acquired and worker.inventory.count(job.item_id)==job.amount)
	var front := 0
	var samples := 0
	var least := INF
	for i in range(30):
		await frames(1)
		if worker.machine.current!=&"PerformTask": continue
		if i==10 and DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
			game._set_paused(true)
			await capture_work()
			game._set_paused(false)
		var reach := reach_to(source)
		least = minf(least,reach)
		if reach>0.1: front += 1
		samples += 1
	check("Working farmer reaches toward the resource",working and samples==30 and front==samples,"front=%d/%d least_reach=%.3f"%[front,samples,least])
	game._set_paused(true)
	var paused_arm := worker.visual.right_arm.transform
	var paused_clock := worker.machine.elapsed
	await frames(30)
	check("Pause freezes the work gesture and task clock",worker.visual.right_arm.transform==paused_arm and worker.machine.elapsed==paused_clock)
	game._set_paused(false)
	worker.visual.rotation.y += PI
	await frames(18)
	check("Task pose turns back toward its actual source",worker.machine.current==&"PerformTask" and reach_to(source)>0.1,"reach=%.3f"%reach_to(source))
	var removed_source := Node3D.new()
	game.add_child(removed_source)
	job.source = removed_source
	removed_source.free()
	await frames(3)
	check("Removed source reference cannot break an acquired work gesture",worker.machine.current==&"PerformTask" and is_finite(worker.visual.right_arm.rotation.x) and worker.inventory.count(job.item_id)==job.amount)
	job.source = source
	var completed := await until(func(): return worker.machine.current==&"Idle",1800)
	check("Pose changes preserve exact harvest and delivery",completed and worker.completed_jobs==1 and source.stock.count(job.item_id)==stock-job.amount and job.destination.inventory.count(job.item_id)==stored+job.amount and worker.inventory.mass()==0)
	await frames(15)
	check("Idle releases the working arm to its resting pose",worker.machine.current==&"Idle" and absf(worker.visual.right_arm.rotation.x)<0.01)
	await finish_report("worker_reach","91 workers reach toward their task",started,"--verify-worker_reach")
