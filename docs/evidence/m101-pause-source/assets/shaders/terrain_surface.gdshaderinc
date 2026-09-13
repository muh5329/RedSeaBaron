// Shared near/far surface treatment; colors are authored in sRGB.
uniform vec4 grass_tint : source_color = vec4(0.48,0.55,0.34,1.0);
uniform vec4 coastal_tint : source_color = vec4(0.71,0.62,0.43,1.0);
uniform vec4 forest_tint : source_color = vec4(0.29,0.39,0.30,1.0);
uniform vec4 dry_tint : source_color = vec4(0.67,0.51,0.33,1.0);
uniform vec4 snow_tint : source_color = vec4(0.63,0.69,0.71,1.0);

vec3 terrain_color(vec2 p, float height) {
	vec3 tint=grass_tint.rgb;
	tint=mix(tint,forest_tint.rgb,1.0-smoothstep(-3150.0,-2850.0,p.x));
	tint=mix(tint,dry_tint.rgb,smoothstep(3850.0,4150.0,p.x));
	tint=mix(tint,vec3(0.43,0.47,0.43),1.0-smoothstep(-5150.0,-4850.0,p.y));
	tint=mix(tint,vec3(0.91,0.94,0.93),smoothstep(145.0,195.0,height)*(1.0-smoothstep(-5150.0,-4850.0,p.y)));
	float coast=smoothstep(66.0,112.0,p.x)*(1.0-smoothstep(160.0,650.0,max(abs(p.x),abs(p.y))));
	tint=mix(tint,coastal_tint.rgb,coast);
	float broad=sin(p.x*0.027+sin(p.y*0.013)*2.0)*cos(p.y*0.031);
	float grain=sin(p.x*0.31+sin(p.y*0.29))*sin(p.y*0.43);
	return tint*(0.77+0.16*broad+0.035*grain);
}
