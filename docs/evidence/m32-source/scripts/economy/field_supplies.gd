class_name FieldSupplies
extends RefCounted
## Workshop ammunition consumes actual market ore and the player's earnings.
const PRICE: int = 12
const ROUNDS: int = 5
const RESERVE_LIMIT: int = 100
var shop: Shop
var combat: PlayerCombat

func purchase_rounds() -> bool:
	if combat.health.current<=0 or combat.state!="READY" or combat.reserve>RESERVE_LIMIT-ROUNDS or shop.credits<PRICE or shop.stock.count("ore")<1 or not shop.begin_transaction(): return false
	# Commit the balance and recipient before stock notifications can observe the trade.
	shop.credits -= PRICE
	combat.reserve += ROUNDS
	var accepted := shop.stock.remove("ore",1)
	if not accepted:
		shop.credits += PRICE
		combat.reserve -= ROUNDS
	else:
		combat.changed.emit()
	shop.end_transaction()
	return accepted
