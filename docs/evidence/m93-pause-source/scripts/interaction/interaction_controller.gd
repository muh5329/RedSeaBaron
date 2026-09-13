class_name InteractionController
extends Node
signal prompt_changed(site: SurveySite)
signal interacted(site: SurveySite)
var actor: PlayerController
var sites: Array[SurveySite] = []
var nearest: SurveySite
var enabled: bool = false
var scan_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if not enabled:
		if nearest != null:
			nearest = null
			prompt_changed.emit(null)
		return
	scan_timer -= delta
	if scan_timer <= 0.0:
		scan_timer = 0.1
		var next: SurveySite
		var distance := INF
		for site in sites:
			var d := actor.global_position.distance_to(site.global_position)
			if d < site.interaction_radius and d < distance and site.can_interact(actor) and _visible(site):
				next = site
				distance = d
		if next != nearest:
			nearest = next
			prompt_changed.emit(nearest)
	if Input.is_action_just_pressed("interact") and nearest and _visible(nearest):
		if nearest.interact(actor):
			interacted.emit(nearest)

func _visible(site: SurveySite) -> bool:
	var query := PhysicsRayQueryParameters3D.create(actor.global_position + Vector3.UP, site.global_position + Vector3.UP, 1)
	return actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
