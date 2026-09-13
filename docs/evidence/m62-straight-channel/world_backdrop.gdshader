shader_type spatial;
render_mode cull_disabled;
#include "res://assets/shaders/terrain_surface.gdshaderinc"
varying vec2 world_point;
uniform vec2 focus_point;
uniform vec4 lake_basin;
uniform float lake_bottom;
uniform vec4 brook_channel;
uniform vec3 brook_ends;

// Visual-only approximation of CoastalRegion.height_at; collision stays on streamed chunks.
float terrain_height(vec2 p) {
	float hills=(sin(p.x*0.024)*cos(p.y*0.028)+1.0)*2.0;
	float upland=8.0*exp(-pow((p.x-48.0)/31.0,2.0)-pow((p.y+89.0)/44.0,2.0));
	float local_height=hills+upland-smoothstep(70.0,130.0,p.x)*12.0;
	float blend=smoothstep(160.0,650.0,max(abs(p.x),abs(p.y)));
	float far_height=25.0+sin(p.x*0.002)*cos(p.y*0.0017)*22.0+sin((p.x+p.y)*0.005)*4.0;
	if(p.y < -5000.0) {far_height+=smoothstep(5000.0,8500.0,-p.y)*90.0;}
	float height=mix(local_height,far_height,blend);
	height=mix(lake_bottom,height,smoothstep(lake_basin.z,lake_basin.w,distance(p,lake_basin.xy)));
	vec2 channel_offset=abs(p-brook_channel.xy);
	float across=smoothstep(brook_channel.z,brook_channel.w,channel_offset.x);
	float ends=smoothstep(brook_ends.x-brook_ends.y,brook_ends.x+brook_ends.y,channel_offset.y);
	return mix(brook_ends.z,height,max(across,ends));
}

void vertex() {
	world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz;
	float h=terrain_height(world_point);
	float near_offset=2.0*(1.0-smoothstep(190.0,380.0,length(world_point-focus_point)));
	VERTEX.y=h-near_offset;
	NORMAL=normalize(vec3(h-terrain_height(world_point+vec2(2.0,0.0)),2.0,h-terrain_height(world_point+vec2(0.0,2.0))));
}

void fragment() {
	if(max(abs(world_point.x),abs(world_point.y))>12500.0) {discard;}
	ALBEDO=terrain_color(world_point);
	ROUGHNESS=1.0;
}
