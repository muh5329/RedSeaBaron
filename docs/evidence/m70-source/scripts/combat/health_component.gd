class_name HealthComponent
extends Node
signal damaged(amount: float)
signal died
signal restored
@export var maximum: float = 100.0
@export var faction: StringName = &"neutral"
var current: float = 100.0
var invulnerable: bool = false

func _ready() -> void:
	current = maximum

func take_damage(amount: float, attacker_faction: StringName) -> bool:
	if amount <= 0 or current <= 0 or invulnerable or attacker_faction == faction:
		return false
	current = maxf(0, current - amount)
	damaged.emit(amount)
	if current <= 0:
		died.emit()
	return true

func restore() -> void:
	current = maximum
	invulnerable = false
	restored.emit()
