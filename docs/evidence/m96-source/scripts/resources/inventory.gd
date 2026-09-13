class_name Inventory
extends RefCounted
signal changed
var capacity: float = 60
var _items: Dictionary = {}
var _transaction: bool = false

func count(id: String) -> int:
	return int(_items.get(id,0))

func contents() -> Dictionary:
	return _items.duplicate(true)

func mass() -> float:
	var result := 0.0
	for id: String in _items:
		result += ItemDefinition.get_item(id).mass * count(id)
	return result

func can_add(id: String, amount: int) -> bool:
	var item := ItemDefinition.get_item(id)
	return item != null and amount>0 and mass()+item.mass*amount <= capacity+0.0001

func add(id: String, amount: int) -> bool:
	if _transaction or not can_add(id,amount): return false
	_items[id] = count(id)+amount
	changed.emit()
	return true

func remove(id: String, amount: int) -> bool:
	if _transaction or amount<=0 or count(id)<amount: return false
	_write(id,count(id)-amount)
	changed.emit()
	return true

func _write(id: String, amount: int) -> void:
	if amount==0: _items.erase(id)
	else: _items[id] = amount

func transfer_to(destination: Inventory, id: String, amount: int) -> bool:
	if destination==null or destination==self or _transaction or destination._transaction or amount<=0 or count(id)<amount or not destination.can_add(id,amount):
		return false
	# Commit both sides before notifications; lock callbacks against reentrant transfers.
	_transaction = true
	destination._transaction = true
	_write(id,count(id)-amount)
	destination._write(id,destination.count(id)+amount)
	changed.emit()
	destination.changed.emit()
	_transaction = false
	destination._transaction = false
	return true

func transfer_available(destination: Inventory) -> int:
	var moved := 0
	for id: String in contents():
		var amount := mini(count(id),int(floor((destination.capacity-destination.mass())/ItemDefinition.get_item(id).mass)))
		if amount>0 and transfer_to(destination,id,amount): moved += amount
	return moved

func summary() -> String:
	var lines: PackedStringArray = []
	for id: String in _items:
		lines.append("%s × %d" % [ItemDefinition.get_item(id).title,count(id)])
	return ", ".join(lines) if not lines.is_empty() else "Empty"

static func valid_contents(data: Variant, limit: float) -> bool:
	if not data is Dictionary: return false
	var total := 0.0
	for id in data:
		if not id is String or ItemDefinition.get_item(id)==null: return false
		var amount: Variant = data[id]
		if typeof(amount) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(amount)) or amount<0 or amount!=floor(amount): return false
		total += amount*ItemDefinition.get_item(id).mass
	return total<=limit+0.0001

func restore_contents(data: Dictionary) -> bool:
	if _transaction or not valid_contents(data,capacity): return false
	_items.clear()
	for id: String in data:
		if data[id]>0: _items[id] = int(data[id])
	changed.emit()
	return true
