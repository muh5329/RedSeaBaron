class_name StateMachine
extends RefCounted
signal transitioned(previous: StringName, current: StringName)
var current: StringName = &"Idle"
var elapsed: float = 0.0
var handlers: Dictionary = {}

func register(state: StringName, tick: Callable) -> void:
	handlers[state] = tick

func change(next: StringName) -> void:
	if next == current:
		return
	var previous := current
	current = next
	elapsed = 0
	transitioned.emit(previous, current)

func tick(delta: float) -> void:
	elapsed += delta
	if handlers.has(current):
		handlers[current].call(delta)
