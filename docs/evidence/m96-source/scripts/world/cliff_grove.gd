class_name CliffGrove
extends RefCounted
## Distant static groves atop the authored limestone; no actor or process cost.
static func build(parent: Node3D, center: Vector3, seed_value: int) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var trunk_color := Color("756047")
	var greens := [Color("4d7160"),Color("657b48"),Color("5d7762")]
	for i in range(5):
		var angle := i*TAU/5+random.randf_range(-0.3,0.3)
		var radius := random.randf_range(1.4,3.1)
		var at := center+Vector3(cos(angle)*radius,0,sin(angle)*radius)
		var height := random.randf_range(2.2,4.6)
		var trunk := BlockoutKit.cylinder(parent,at+Vector3.UP*height*0.42,0.13,height*0.84,trunk_color,0.08,5)
		trunk.rotation.z = random.randf_range(-0.10,0.10)
		for cluster in range(3):
			var branch := cluster*TAU/3+angle
			var spread := height*0.17
			var crown := at+Vector3(cos(branch)*spread,height*(0.73+cluster*0.08),sin(branch)*spread)
			BlockoutKit.sphere(parent,crown,Vector3(height*0.43,height*0.26,height*0.39),greens[(i+cluster)%greens.size()])
