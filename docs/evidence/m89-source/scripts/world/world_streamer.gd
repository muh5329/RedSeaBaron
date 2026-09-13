class_name WorldStreamer
extends Node3D
## A bounded 5×5 window. The authored center has its own higher-resolution terrain.
const HALF_EXTENT: float = 12500.0
const RADIUS: int = 2
var focus: Node3D
var chunks: Dictionary = {}
var pending: Array[Vector2i] = []
var center := Vector2i(99999,99999)
var created: int = 0
var retired: int = 0
var peak_resident: int = 0
var largest_build_ms: float = 0
var enabled: bool = true

static func coordinate(point: Vector3) -> Vector2i:
	return Vector2i(floori((point.x+32)/64),floori((point.z+32)/64))

static func authored(cell: Vector2i) -> bool:
	return cell.x>=-2 and cell.x<=2 and cell.y>=-2 and cell.y<=2

func refresh() -> void:
	if not is_instance_valid(focus): return
	center = coordinate(focus.position)
	pending.clear()
	var desired: Array[Vector2i] = []
	for x in range(-RADIUS,RADIUS+1):
		for z in range(-RADIUS,RADIUS+1):
			var cell := center+Vector2i(x,z)
			if not authored(cell): desired.append(cell)
	for cell: Vector2i in chunks.keys():
		if not desired.has(cell):
			var old: Node = chunks[cell]
			remove_child(old)
			old.queue_free()
			chunks.erase(cell)
			retired += 1
	for cell in desired:
		if not chunks.has(cell): pending.append(cell)
	pending.sort_custom(func(a,b): return Vector2(a-center).length_squared()<Vector2(b-center).length_squared())

func _physics_process(_delta: float) -> void:
	if not enabled or not is_instance_valid(focus): return
	if coordinate(focus.position)!=center: refresh()
	if not pending.is_empty(): _build(pending.pop_front())

func _build(cell: Vector2i) -> void:
	var start := Time.get_ticks_usec()
	var chunk := TerrainChunk.new()
	add_child(chunk)
	chunk.build(cell)
	chunks[cell] = chunk
	created += 1
	peak_resident = maxi(peak_resident,chunks.size())
	largest_build_ms = maxf(largest_build_ms,(Time.get_ticks_usec()-start)/1000.0)

func collision_ready(point: Vector3) -> bool:
	var cell := coordinate(point)
	return authored(cell) or chunks.has(cell)

func prepare_focus_collision() -> void:
	# Recovery may jump to a retired checkpoint. Build its center synchronously;
	# the remaining bounded window continues through the normal streaming queue.
	refresh()
	if not authored(center) and not chunks.has(center):
		pending.erase(center)
		_build(center)
