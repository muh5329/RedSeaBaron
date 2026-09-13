shader_type spatial;
#include "res://assets/shaders/terrain_surface.gdshaderinc"
varying vec2 world_point;
varying float world_height;
void vertex() { world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz; world_height=(MODEL_MATRIX*vec4(VERTEX,1.0)).y; }
void fragment() { ALBEDO=terrain_color(world_point,world_height); ROUGHNESS=1.0; }
