shader_type spatial;
uniform vec4 clay : source_color = vec4(0.616, 0.333, 0.259, 1.0);
varying vec3 world_point;
varying vec3 world_normal;
void vertex() {
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec2 tile = world_point.xz * vec2(1.7, 2.4);
	tile.y += mod(floor(tile.x), 2.0) * 0.5;
	vec2 cell = floor(tile);
	vec2 local = fract(tile);
	vec2 width = max(fwidth(tile), vec2(0.001));
	float along = smoothstep(0.0, 0.035 + width.x, local.x);
	float across = smoothstep(0.0, 0.025 + width.y, local.y);
	float variation = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	float rounded = 0.94 + 0.10 * sin(local.y * 3.14159);
	float detail = mix(0.78, rounded * (0.94 + variation * 0.12), along * across);
	float visible_detail = 1.0 - smoothstep(0.18, 0.42, max(width.x, width.y));
	visible_detail *= smoothstep(0.2, 0.55, abs(world_normal.y));
	ALBEDO = clay.rgb * mix(1.0, detail, visible_detail);
	ROUGHNESS = 0.92;
	SPECULAR = 0.12;
}
