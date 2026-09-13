extends "res://tests/worker_verifier.gd"

func triangle_count(mesh: Mesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
	return (indices.size() if not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size())/3

func run(owner_game: Node3D) -> void:
	game = owner_game
	var started := Time.get_ticks_msec()
	var fixture := Node3D.new()
	fixture.position = Vector3(20,5,20)
	fixture.rotation.y = 0.4
	game.add_child(fixture)
	var box := BlockoutKit.box(fixture,Vector3(2,0,0),Vector3.ONE,Color.RED)
	var tank := VehicleMesh.tank(fixture,Vector3(-2,0,0),Color.RED)
	var expected := triangle_count(box.mesh)+triangle_count(tank.mesh)
	check("Fixture mixes indexed and unindexed geometry",box.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()>0 and tank.mesh.surface_get_array_index_len(0)==0)
	var merged := StaticBatcher.combine(fixture)
	var batch: MeshInstance3D
	for child in fixture.get_children():
		if child.name.begins_with("StaticBatch_"): batch=child
	check("Rigid sources become one material batch",merged==2 and batch!=null and not box.visible and not tank.visible)
	check("Batch preserves every source triangle",batch!=null and triangle_count(batch.mesh)==expected,"expected=%d actual=%d"%[expected,triangle_count(batch.mesh) if batch else -1])
	var bounds: AABB = batch.mesh.get_aabb() if batch else AABB()
	check("Batch preserves both separated local mesh bounds",bounds.position.x< -2.3 and bounds.end.x>2.49,"bounds=%s"%bounds)
	var moving := Node3D.new()
	moving.set_meta("animated_part",true)
	fixture.add_child(moving)
	var detail := BlockoutKit.box(moving,Vector3.ZERO,Vector3.ONE,Color.RED)
	var excluded: Array[MeshInstance3D] = []
	StaticBatcher._collect(moving,excluded)
	check("Animated child remains independent",excluded.is_empty() and detail.visible)
	fixture.queue_free()
	await finish_report("batching","30 mixed geometry batching",started,"--verify-batching")
