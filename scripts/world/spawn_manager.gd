class_name SpawnManager
extends Node3D
## Bounded regional encounters; persistent records survive retired actors/navigation.
var actor: PlayerController
var streamer: WorldStreamer
var enabled: bool = false
var active: Dictionary = {}
var navigation: Dictionary = {}
var records: Dictionary = {}
var timer: float = 0

func _ready() -> void:
	process_physics_priority = -30

func _physics_process(_delta: float) -> void:
	if not enabled: return
	# Retire actors before the terrain streamer removes their collision window.
	for region in RegionCatalog.all():
		if active.has(region.id) and Vector2(actor.position.x,actor.position.z).distance_to(region.center)>150:
			_retire(region.id)

static func key_for(region: RegionDefinition, index: int) -> String:
	return region.id+"_"+str(index)

static func home_for(region: RegionDefinition, index: int) -> Vector3:
	var at := region.center+Vector2(20,12)*(1 if index==0 else -1)
	return Vector3(at.x,CoastalRegion.height_at(at.x,at.y)+0.1,at.y)

func set_enabled(value: bool) -> void:
	enabled = value
	for actors: Array in active.values():
		for enemy in actors:
			if is_instance_valid(enemy): enemy.set_simulation(value)

func _process(delta: float) -> void:
	if not enabled: return
	timer -= delta
	if timer>0: return
	timer = 0.25
	for region in RegionCatalog.all():
		if region.hostile_kinds.is_empty(): continue
		var distance := Vector2(actor.position.x,actor.position.z).distance_to(region.center)
		if distance<110 and not active.has(region.id): _spawn(region)
		elif distance>150 and active.has(region.id): _retire(region.id)

func _spawn(region: RegionDefinition) -> void:
	for i in range(region.hostile_kinds.size()):
		if not streamer.collision_ready(home_for(region,i)): return
	var nav := NavigationController.new()
	nav.origin = region.center-Vector2.ONE*60
	nav.side_cells = 31
	add_child(nav)
	navigation[region.id] = nav
	var actors: Array[EnemyActor] = []
	for i in range(region.hostile_kinds.size()):
		var key := key_for(region,i)
		var saved: Dictionary = records.get(key,{})
		if saved.get("health",1)<=0: continue
		var enemy := EnemyActor.new()
		enemy.kind = region.hostile_kinds[i]
		enemy.home = home_for(region,i)
		enemy.position = SaveSchema.decode(saved.position) if saved.has("position") else enemy.home
		enemy.target = actor
		enemy.set_meta("encounter_key",key)
		add_child(enemy)
		enemy.brain.navigation = nav
		if saved.has("health"): enemy.health.current = saved.health
		_record(enemy)
		enemy.health.damaged.connect(func(_amount): _record(enemy))
		actors.append(enemy)
	active[region.id] = actors

func _record(enemy: EnemyActor) -> void:
	records[enemy.get_meta("encounter_key")] = {"health":enemy.health.current,"position":SaveSchema.vector(enemy.position)}

func _retire(id: String) -> void:
	for enemy in active[id]:
		if is_instance_valid(enemy):
			_record(enemy)
			enemy.set_simulation(false)
			enemy.collision_layer = 0
			enemy.queue_free()
	active.erase(id)
	if navigation.has(id):
		navigation[id].queue_free()
		navigation.erase(id)

func snapshot() -> Dictionary:
	for actors: Array in active.values():
		for enemy in actors:
			if is_instance_valid(enemy): _record(enemy)
	return records.duplicate(true)

func restore(saved: Dictionary) -> void:
	for id: String in active.keys(): _retire(id)
	records = saved.duplicate(true)
	timer = 0

static func valid_records(saved: Variant) -> bool:
	if not saved is Dictionary: return false
	var definitions := {}
	for region in RegionCatalog.all():
		for i in range(region.hostile_kinds.size()): definitions[key_for(region,i)] = [region,i]
	for key in saved:
		if not definitions.has(key) or not saved[key] is Dictionary: return false
		var info: Array = definitions[key]
		var region: RegionDefinition = info[0]
		var record: Dictionary = saved[key]
		if not SaveSchema.number(record.get("health"),0,90 if region.hostile_kinds[info[1]]=="Raider" else 140) or not SaveSchema.valid_vector(record.get("position")): return false
		if SaveSchema.decode(record.position).distance_to(home_for(region,info[1]))>35: return false
	return true
