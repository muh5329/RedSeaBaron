extends "res://tests/worker_verifier.gd"

func run(owner_game: Node3D) -> void:
	game = owner_game
	player = game.player
	bike = game.bike
	seat = game.seat
	var started := Time.get_ticks_msec()
	var center := Vector3(0,200,0)
	var rock: MeshInstance3D = game.region._rock(center,Vector3.ONE*20,Color("c9bd9f"),true)
	await frames(3)
	var arrays := rock.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var outward := 0
	var sides := 0
	for i in range(0,vertices.size(),3):
		if is_equal_approx(vertices[i].y,vertices[i+1].y) and is_equal_approx(vertices[i].y,vertices[i+2].y): continue
		var midpoint := (vertices[i]+vertices[i+1]+vertices[i+2])/3
		var radial := Vector3(midpoint.x,0,midpoint.z)
		sides += 1
		if normals[i].dot(radial)>0: outward += 1
	check("Rock side faces have outward lighting normals",outward==sides and sides>20,"outward=%d / %d"%[outward,sides])
	var space := game.get_world_3d().direct_space_state
	var roof := space.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3.UP*20,center,1))
	check("Rock cap supports an approaching downward ray",not roof.is_empty() and roof.normal.y>0.9 and absf(roof.position.y-210)<0.1)
	var front := space.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3.RIGHT*20,center,1))
	check("Rock wall blocks entry from outside its visible surface",not front.is_empty() and front.normal.x>0.3 and front.position.x>3)
	var underside := space.intersect_ray(PhysicsRayQueryParameters3D.create(center-Vector3.UP*20,center,1))
	check("Rock underside blocks upward entry beneath an arch",not underside.is_empty() and underside.normal.y < -0.9 and absf(underside.position.y-190)<0.1)
	rock.queue_free()
	await finish_report("rock_surface","64 solid outward cliff surfaces",started,"--verify-rock_surface")
