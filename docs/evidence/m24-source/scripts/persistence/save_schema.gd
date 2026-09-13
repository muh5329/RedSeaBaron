class_name SaveSchema
extends RefCounted
const VERSION: int = 1
const KINDS := ["Gather","Mine","Farm","Transport","Deliver","ShopKeep"]
const STATES := ["Idle","MoveToTask","AcquireResource","PerformTask","DeliverResource","Return","Blocked","Failed"]

static func vector(v: Vector3) -> Array:
	return [v.x,v.y,v.z]

static func decode(a: Array) -> Vector3:
	return Vector3(a[0],a[1],a[2])

static func number(value: Variant, low: float, high: float) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and value>=low and value<=high

static func whole(value: Variant, low: int, high: int) -> bool:
	return number(value,low,high) and value==floor(value)

static func valid_vector(value: Variant) -> bool:
	return value is Array and value.size()==3 and number(value[0],-12500,12500) and number(value[1],-8,500) and number(value[2],-12500,12500)

static func validate(data: Variant, game: Node3D) -> bool:
	if not data is Dictionary or data.get("version")!=VERSION: return false
	if not RegionManager.valid_record(data.get("regions",{})): return false
	if not SpawnManager.valid_records(data.get("encounters",{})): return false
	for field in ["player","bike","cart","economy","worker","stocks"]:
		if not data.get(field) is Dictionary: return false
	if not data.get("camera") is Array or data.camera.size()!=3 or not number(data.camera[0],-100000,100000) or not number(data.camera[1],-1.1,0.35) or not number(data.camera[2],3,9): return false
	var p: Dictionary = data.player
	var b: Dictionary = data.bike
	var c: Dictionary = data.cart
	var e: Dictionary = data.economy
	if not DeliveryRoute.valid_id(e.get("route","south_quay")): return false
	var w: Dictionary = data.worker
	var routine: Variant = w.get("routine",{})
	if not routine is Dictionary or routine.get("id","harvest_market")!="harvest_market" or not routine.get("active",false) is bool or not whole(routine.get("step",0),0,1) or not whole(routine.get("cycles",0),0,1000000): return false
	if not number(p.get("facing"),-100000,100000) or not valid_vector(p.get("position")) or not valid_vector(p.get("checkpoint")) or not number(p.get("health"),1,100) or not number(p.get("stamina"),0,100): return false
	if p.get("weapon") not in ["WRENCH","RIFLE"] or not whole(p.get("ammo"),0,5) or not whole(p.get("reserve"),0,100000): return false
	if not Inventory.valid_contents(p.get("inventory"),60): return false
	if not valid_vector(b.get("position")) or not number(b.get("yaw"),-100000,100000) or b.get("mode") not in ["BIKE","AIRCRAFT"] or not b.get("mounted") is bool: return false
	if not valid_vector(c.get("position")) or not number(c.get("yaw"),-100000,100000) or not c.get("attached") is bool or not Inventory.valid_contents(c.get("inventory"),160): return false
	if c.attached and (b.mode!="BIKE" or decode(c.position).distance_to(decode(b.position))>5): return false
	if not whole(e.get("credits"),0,10000000) or e.get("contract") not in ["AVAILABLE","IN_TRANSIT","COMPLETED"] or not Inventory.valid_contents(e.get("receipt"),60): return false
	if not whole(e.get("sold"),0,10000000) or not whole(e.get("deliveries_completed",0),0,1000000): return false
	for station: Storage in game.logistics.stations:
		if not Inventory.valid_contents(data.stocks.get(station.station_id),station.inventory.capacity): return false
	for source: ResourceSource in game.logistics.sources:
		if not Inventory.valid_contents(data.stocks.get("source_"+source.item_id),source.stock.capacity): return false
	if not valid_vector(w.get("position")) or not Inventory.valid_contents(w.get("inventory"),60) or w.get("state") not in STATES or not whole(w.get("completed"),0,1000000): return false
	if not number(w.get("elapsed"),0,1000000) or not whole(w.get("retries"),0,100000) or not valid_vector(w.get("goal")) or w.get("resume") not in STATES: return false
	if w.get("kind")!="" and w.get("kind") not in KINDS: return false
	if w.state!="Idle" and w.kind=="": return false
	if not w.get("acquired") is bool or not w.get("delivered") is bool: return false
	if w.delivered and not w.acquired: return false
	if not routine.get("current_job",false) is bool: return false
	if routine.get("current_job",false) and (w.delivered or w.state=="Idle"): return false
	if (routine.get("active",false) or routine.get("current_job",false)) and w.state!="Idle":
		var step: int = int(routine.get("step",0))
		if w.delivered: step = (step+1)%2
		if w.kind!=["Farm","ShopKeep"][step]: return false
	if w.kind=="Deliver" and (w.get("contract") not in ["AVAILABLE","IN_TRANSIT","COMPLETED"] or not Inventory.valid_contents(w.get("receipt"),60)): return false
	if not data.get("enemies") is Array or data.enemies.size()!=game.enemies.size(): return false
	for enemy in data.enemies:
		if not enemy is Dictionary or enemy.get("kind") not in ["Raider","Cinder beast"] or not valid_vector(enemy.get("position")) or not valid_vector(enemy.get("home")) or not number(enemy.get("health"),0,140 if enemy.get("kind")=="Cinder beast" else 90): return false
	if not data.get("survey") is Array or data.survey.size()!=game.sites.size() or not data.survey.all(func(v): return v is bool): return false
	return true
