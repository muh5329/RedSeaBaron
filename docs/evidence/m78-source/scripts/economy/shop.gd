class_name Shop
extends RefCounted
var stock: Inventory
var credits: int = 20
var sold_units: int = 0
var _transaction: bool = false

func begin_transaction() -> bool:
	if _transaction: return false
	_transaction = true
	return true

func end_transaction() -> void:
	_transaction = false

func sell(container: Inventory, id: String, amount: int) -> bool:
	var item := ItemDefinition.get_item(id)
	if item==null or item.value<=0 or amount<=0 or not begin_transaction(): return false
	credits += item.value*amount
	sold_units += amount
	var accepted := container.transfer_to(stock,id,amount)
	if not accepted:
		credits -= item.value*amount
		sold_units -= amount
	end_transaction()
	return accepted

func buy(container: Inventory, id: String, amount: int) -> bool:
	var item := ItemDefinition.get_item(id)
	if item==null or item.value<=0 or amount<=0 or credits<item.value*amount*2 or not begin_transaction(): return false
	credits -= item.value*amount*2
	var accepted := stock.transfer_to(container,id,amount)
	if not accepted: credits += item.value*amount*2
	end_transaction()
	return accepted
