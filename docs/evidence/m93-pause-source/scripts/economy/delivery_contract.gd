class_name DeliveryContract
extends RefCounted
signal completed(reward: int)
var state: String = "AVAILABLE"
var reward: int = 75
var origin: Storage
var destination: Storage
var receipt := Inventory.new()
var deliveries_completed: int = 0
var _busy: bool = false

func configure(endpoint: Storage, payment: int) -> bool:
	if _busy or state not in ["AVAILABLE","COMPLETED"] or not is_instance_valid(endpoint) or payment<=0: return false
	_busy = true
	destination = endpoint
	reward = payment
	state = "AVAILABLE"
	receipt.restore_contents({})
	_busy = false
	return true

func reissue(container: Inventory) -> bool:
	if _busy or state!="COMPLETED" or not container.can_add("package",1): return false
	_busy = true
	state = "ACCEPTING"
	var accepted := container.add("package",1)
	if accepted:
		receipt.restore_contents({})
		state = "IN_TRANSIT"
	else:
		state = "COMPLETED"
	_busy = false
	return accepted

func accept(container: Inventory) -> bool:
	if _busy or state!="AVAILABLE": return false
	_busy = true
	state = "ACCEPTING"
	if not container.add("package",1):
		state = "AVAILABLE"
		_busy = false
		return false
	state = "IN_TRANSIT"
	_busy = false
	return true

func deliver(container: Inventory) -> bool:
	if _busy or state!="IN_TRANSIT": return false
	_busy = true
	state = "DELIVERING"
	if not container.transfer_to(receipt,"package",1):
		state = "IN_TRANSIT"
		_busy = false
		return false
	state = "COMPLETED"
	deliveries_completed += 1
	completed.emit(reward)
	_busy = false
	return true
