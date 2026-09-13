class_name EnemyAttackCue
extends Node3D
## One reusable ground-sector mesh makes the pending forward strike visible.
var material: StandardMaterial3D

func build(radius: float, arc_degrees: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := deg_to_rad(arc_degrees)*0.5
	for i in range(20):
		var a := lerpf(-half,half,float(i)/20)
		var b := lerpf(-half,half,float(i+1)/20)
		for point in [Vector3.ZERO,Vector3(sin(a),0,-cos(a))*radius,Vector3(sin(b),0,-cos(b))*radius]: surface.add_vertex(point)
	surface.generate_normals()
	var geometry := MeshInstance3D.new()
	geometry.mesh = surface.commit()
	geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	geometry.material_override = material
	add_child(geometry)
	position.y = 0.12
	visible = false

func present(brain: CombatBrain, heading: float) -> void:
	visible = brain.machine.current==&"Attack" and brain.machine.elapsed<brain.windup_seconds+0.2
	if not visible: return
	rotation.y = heading
	var fraction := clampf(brain.machine.elapsed/brain.windup_seconds,0,1)
	material.albedo_color = Color(0.96,0.53 if fraction<0.6 else 0.23,0.16,0.12+fraction*0.23)
