// Mirror WorldLandforms' compact terrain footprints for the distant horizon.
float landform_envelope(vec2 p, vec2 center, vec2 radii) {
	vec2 d=(p-center)/radii;
	return pow(max(0.0,1.0-dot(d,d)),2.0);
}
float mountain_peak(vec2 p, vec2 center, float height) {
	vec2 d=(p-center)/vec2(850.0,1000.0);
	float angle=dot(d,d)<0.0000001 ? 0.0 : atan(d.y,d.x);
	float rounded=(sqrt(dot(d,d)+0.0025)-0.05)/(sqrt(1.0025)-0.05);
	float ridge=1.0-0.12*smoothstep(0.0,0.25,length(d))*(1.0-cos(angle*5.0));
	return height*pow(max(0.0,1.0-rounded),1.3)*ridge;
}
float landform_offset(vec2 p) {
	float dunes=landform_envelope(p,vec2(6600.0,3000.0),vec2(1500.0,1200.0))*(10.0+9.0*sin((p.x+p.y*0.35)*0.035));
	float valley=-55.0*landform_envelope(p,vec2(-800.0,-6500.0),vec2(450.0,1300.0));
	float mountains=mountain_peak(p,vec2(-1800.0,-8600.0),180.0);
	mountains+=mountain_peak(p,vec2(1100.0,-10300.0),210.0);
	return dunes+valley+mountains;
}
