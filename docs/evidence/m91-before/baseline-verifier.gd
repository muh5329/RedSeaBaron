extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	await until(func(): return game.workers.navigation.ready_for_paths,300)
	worker = game.workers.worker_by_id("mara")
	var job: JobDefinition = game.workers.make_job("Farm")
	worker.position = job.source.position+Vector3(0,0.3,4)
	worker.velocity = Vector3.ZERO
	player.position = job.source.position+Vector3(4,0.3,4)
	player.velocity = Vector3.ZERO
	await frames(30)
	worker.assign(job)
	var working := await until(func(): return worker.machine.current==&"PerformTask",400)
	var front := 0
	var samples := 0
	var least := INF
	for i in range(30):
		await frames(1)
		if worker.machine.current!=&"PerformTask": continue
		var arm := worker.visual.right_arm
		var hand := arm.to_global(Vector3(0,-0.52,-0.02))
		var direction: Vector3 = job.source.position-arm.global_position
		direction.y = 0
		var reach := (hand-arm.global_position).dot(direction.normalized())
		least = minf(least,reach)
		if reach>0.1: front += 1
		samples += 1
	check("Working farmer reaches toward the resource",working and samples==30 and front==samples,"front=%d/%d least_reach=%.3f"%[front,samples,least])
	await finish_report("worker_reach","91 workers reach toward their task",started,"--verify-worker_reach")
