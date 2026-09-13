class_name NavigationController
extends Node3D
## Bounded local navigation, sampled incrementally from world collision.
const CELL: float = 4.0
const ORIGIN := Vector2(-156,-156)
var grid := AStarGrid2D.new()
var ready_for_paths: bool = false
var cursor: int = 0
var query := PhysicsShapeQueryParameters3D.new()
var sampled_cells: int = 0

func _ready() -> void:
	grid.region = Rect2i(0,0,79,79)
	grid.cell_size = Vector2.ONE*CELL
	grid.offset = ORIGIN
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.8,1.5,3.8)
	query.shape = shape
	query.collision_mask = 1

func _physics_process(_delta: float) -> void:
	if ready_for_paths: return
	for i in range(96):
		if cursor>=79*79:
			ready_for_paths = true
			set_physics_process(false)
			return
		_sample(Vector2i(cursor%79,cursor/79))
		cursor += 1

func _sample(cell: Vector2i) -> void:
	var at := ORIGIN+Vector2(cell)*CELL
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
	return Vector2i(roundi((point.x-ORIGIN.x)/CELL),roundi((point.z-ORIGIN.y)/CELL))

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
		var at := ORIGIN+Vector2(cell)*CELL
		result.append(Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+0.1,at.y))
	return result
