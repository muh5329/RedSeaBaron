shader_type spatial;
render_mode cull_disabled;
uniform bool elliptical = false;
uniform float wave_time = 0.0;
varying vec3 world_position;
void vertex() { world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
	if(elliptical && length(UV*2.0-vec2(1.0))>1.0) { discard; }
	// Directional bands stay attached to the world as the camera orbits.
	float broad = sin(dot(world_position.xz,vec2(0.11,0.075))+wave_time*0.35);
	float fine = sin(dot(world_position.xz,vec2(-0.32,0.48))-wave_time*0.8+broad*0.8);
	float ripple = 0.5+broad*0.24+fine*0.10;
	ALBEDO=mix(vec3(0.09,0.29,0.34),vec3(0.15,0.40,0.43),ripple);
	ROUGHNESS=0.4;
	SPECULAR=0.1;
}
