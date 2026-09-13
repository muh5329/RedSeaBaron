class_name ConsumableUse
extends Node
## A food transaction joins the resource loop to player recovery.
signal message(text: String)
const HEALING: float = 25.0
var actor: PlayerController
var combat: PlayerCombat
var seat: VehicleSeat
var pack: Inventory
var pending: bool = false
var busy: bool = false
var last_rejection: String = ""
var meals: int = 0
var enabled: bool = false:
	set(value):
		enabled = value
		if not value: pending=false

func _ready() -> void:
	process_physics_priority = 10

func _input(event: InputEvent) -> void:
	if enabled and not event.is_echo() and event.is_action_pressed("eat_food"):
		pending = true

func _physics_process(_delta: float) -> void:
	if not pending: return
	pending = false
	if not consume(): message.emit(last_rejection)

func reject(reason: String) -> bool:
	last_rejection = reason
	return false

func consume() -> bool:
	if busy or not enabled or seat.mounted or combat.health.current<=0 or combat.state!="READY" or actor.dodge_remaining>0 or not actor.is_on_floor() or Vector2(actor.velocity.x,actor.velocity.z).length()>0.2:
		return reject("Stop on foot and finish your action before eating.")
	if combat.health.current>=combat.health.maximum:
		return reject("Health is full. Olive kept in your pack.")
	if pack.count("olive")<1:
		return reject("No olives in your pack. Gather, buy or unload one first.")
	busy = true
	var before := combat.health.current
	# Inventory notifications observe both the removed food and restored health.
	combat.health.current = minf(combat.health.maximum,before+HEALING)
	var restored := combat.health.current-before
	var accepted := pack.remove("olive",1)
	if not accepted:
		combat.health.current = before
		last_rejection = "Your pack is busy. Olive and health kept unchanged."
	else:
		meals += 1
		last_rejection = ""
		combat.changed.emit()
		message.emit("Ate an olive · recovered %.0f HP."%restored)
	busy = false
	return accepted
