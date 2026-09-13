class_name NavigationController
extends Node3D
## Bounded local navigation, sampled incrementally from world collision.
const CELL: float = 4.0
const ORIGIN := Vector2(-156,-156)
var origin: Vector2 = ORIGIN
var side_cells: int = 79
var grid := AStarGrid2D.new()
var ready_for_paths: bool = false
var cursor: int = 0
var query := PhysicsShapeQueryParameters3D.new()
var sampled_cells: int = 0
var dynamic_enabled: bool = true
var obstacle_states: Dictionary = {}
var obstacle_clock: float = 0
var dynamic_samples: int = 0
var maximum_dynamic_batch: int = 0
var largest_dynamic_ms: float = 0

func _ready() -> void:
	add_to_group("navigation_grids")
	for body: Node3D in get_tree().get_nodes_in_group("navigation_obstacles"):
		obstacle_states[body.get_instance_id()] = {"at":body.global_position,"signature":[]}
	grid.region = Rect2i(0,0,side_cells,side_cells)
	grid.cell_size = Vector2.ONE*CELL
	grid.offset = origin
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.8,1.5,3.8)
	query.shape = shape
	query.collision_mask = 9

func _physics_process(_delta: float) -> void:
	if ready_for_paths: return
	for i in range(96):
		if cursor>=side_cells*side_cells:
			ready_for_paths = true
			set_physics_process(false)
			return
		_sample(Vector2i(cursor%side_cells,cursor/side_cells))
		cursor += 1

func _sample(cell: Vector2i) -> void:
	var at := origin+Vector2(cell)*CELL
	var y := CoastalRegion.height_at(at.x,at.y)
	query.transform.origin = Vector3(at.x,y+1.4,at.y)
	var blocked := y < -1.8 or not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
	grid.set_point_solid(cell,blocked)
	sampled_cells += 1

func refresh_near(point: Vector3) -> void:
	var center := coordinate(point)
	for dx in range(-4,5):
		for dz in range(-4,5):
			var cell := center+Vector2i(dx,dz)
			if grid.is_in_boundsv(cell): _sample(cell)

func coordinate(point: Vector3) -> Vector2i:
	return Vector2i(roundi((point.x-origin.x)/CELL),roundi((point.z-origin.y)/CELL))

func nearest_open(cell: Vector2i) -> Vector2i:
	for radius in range(5):
		for dx in range(-radius,radius+1):
			for dz in range(-radius,radius+1):
				var candidate := cell+Vector2i(dx,dz)
				if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate): return candidate
	return Vector2i(-1,-1)

func route(from: Vector3, destination: Vector3) -> PackedVector3Array:
	var result := PackedVector3Array()
	if not ready_for_paths: return result
	var start := nearest_open(coordinate(from))
	var end := nearest_open(coordinate(destination))
	if start.x<0 or end.x<0: return result
	for cell in grid.get_id_path(start,end):
		var at := origin+Vector2(cell)*CELL
		result.append(Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+0.1,at.y))
	return result

func _process(delta: float) -> void:
	if not ready_for_paths or not dynamic_enabled: return
	obstacle_clock += delta
	if obstacle_clock<0.25: return
	obstacle_clock = 0
	refresh_obstacles()

func refresh_obstacles() -> void:
	if not ready_for_paths: return
	var started := Time.get_ticks_usec()
	var next_states: Dictionary = {}
	var dirty: Dictionary = {}
	for body: Node3D in get_tree().get_nodes_in_group("navigation_obstacles"):
		if not body is CollisionObject3D or body.collision_layer & 9 == 0: continue
		var at := body.global_position
		var above := at.y-CoastalRegion.height_at(at.x,at.z)
		if above>8 or above< -4: continue
		var signature: Array = [body.global_transform,body.collision_layer]
		for shape in body.get_children():
			if not shape is CollisionShape3D: continue
			signature.append_array([shape.transform,shape.disabled,shape.shape.get_rid()])
			if shape.shape is BoxShape3D: signature.append(shape.shape.size)
		var id := body.get_instance_id()
		next_states[id] = {"at":at,"signature":signature}
		if not obstacle_states.has(id) or obstacle_states[id].signature!=signature:
			_dirty_near(at,dirty)
			if obstacle_states.has(id): _dirty_near(obstacle_states[id].at,dirty)
	for id in obstacle_states:
		if not next_states.has(id): _dirty_near(obstacle_states[id].at,dirty)
	obstacle_states = next_states
	for cell: Vector2i in dirty: _sample(cell)
	dynamic_samples += dirty.size()
	maximum_dynamic_batch = maxi(maximum_dynamic_batch,dirty.size())
	largest_dynamic_ms = maxf(largest_dynamic_ms,(Time.get_ticks_usec()-started)/1000.0)

func _dirty_near(at: Vector3, dirty: Dictionary) -> void:
	# A 16 m radius includes every supported bike/wing/cart pose plus cell width.
	var center := coordinate(at)
	for x in range(-4,5):
		for z in range(-4,5):
			var cell := center+Vector2i(x,z)
			if grid.is_in_boundsv(cell): dirty[cell] = true
