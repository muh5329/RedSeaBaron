shader_type spatial;
render_mode cull_disabled;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool vertex_colors = false;
varying vec3 instance_center;
void vertex() {
	instance_center = MODEL_MATRIX[3].xyz;
}
void fragment() {
	float visibility = smoothstep(4.0,8.0,distance(instance_center,CAMERA_POSITION_WORLD));
	float stipple = mod(FRAGCOORD.x+2.0*FRAGCOORD.y,4.0)/4.0;
	if (stipple >= visibility) { discard; }
	ALBEDO = vertex_colors ? COLOR.rgb : tint.rgb;
	ROUGHNESS = 1.0;
}
