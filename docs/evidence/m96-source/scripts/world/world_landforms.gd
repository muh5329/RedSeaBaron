class_name WorldLandforms
extends RefCounted
## Compact footprints leave established settlements and courier routes unchanged.
const DUNES := Vector2(6600,3000)
const VALLEY := Vector2(-800,-6500)
const PEAKS := [Vector3(-1800,180,-8600),Vector3(1100,210,-10300)]

static func envelope(at: Vector2, center: Vector2, radii: Vector2) -> float:
	return pow(maxf(0,1-((at-center)/radii).length_squared()),2)

static func offset(at: Vector2) -> float:
	var dunes := envelope(at,DUNES,Vector2(1500,1200))*(10+9*sin((at.x+at.y*0.35)*0.035))
	var valley := -55*envelope(at,VALLEY,Vector2(450,1300))
	var mountains := 0.0
	for peak: Vector3 in PEAKS:
		var d := (at-Vector2(peak.x,peak.z))/Vector2(850,1000)
		var radius := d.length()
		var ridge := 1-0.12*smoothstep(0,0.25,radius)*(1-cos(atan2(d.y,d.x)*5))
		var rounded := (sqrt(d.length_squared()+0.0025)-0.05)/(sqrt(1.0025)-0.05)
		mountains += peak.y*pow(maxf(0,1-rounded),1.3)*ridge
	return dunes+valley+mountains

static func landmarks() -> Array:
	return [
		["Saffron dunes",DUNES,"Dunes"],
		["Windcut valley",VALLEY,"Valley"],
		["Crown mountains",Vector2(-1800,-8600),"Snowcap"],
		["Whitecap peak",Vector2(1100,-10300),"Snowcap"],
		["Solis beach",Vector2(105,60),"Beach"],
		["Quarry cave",QuarryAdit.CENTER,"Cave"]
	]
