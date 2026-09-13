shader_type spatial;
render_mode cull_disabled;
uniform bool elliptical = false;
varying vec3 world_position;
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	if(elliptical && length(UV*2.0-vec2(1.0))>1.0) { discard; }
	float ripple=sin(world_position.x*0.24+TIME*0.7)*sin(world_position.z*0.19-TIME*0.5);
	ALBEDO=mix(vec3(0.08,0.24,0.29),vec3(0.15,0.38,0.41),ripple*0.5+0.5);
	ROUGHNESS=0.35;
}
