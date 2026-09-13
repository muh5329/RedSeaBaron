class_name WorkerRoutineState
extends RefCounted
var active: bool = false
var current_job: bool = false
var step: int = 0
var cycles: int = 0

func snapshot(id: String) -> Dictionary:
	return {"id":id,"active":active,"current_job":current_job,"step":step,"cycles":cycles}

func restore(data: Dictionary) -> void:
	active = data.get("active",false)
	current_job = data.get("current_job",false)
	step = int(data.get("step",0))
	cycles = int(data.get("cycles",0))
