shader_type spatial;
#include "res://assets/shaders/terrain_surface.gdshaderinc"
varying vec2 world_point;
void vertex() { world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xz; }
void fragment() { ALBEDO=terrain_color(world_point); ROUGHNESS=1.0; }
