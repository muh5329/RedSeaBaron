class_name TerrainCartography
extends RefCounted
## Cached relief samples use the same height field as playable terrain.
static var sheets: Dictionary = {}

static func color_at(at: Vector2, step: float) -> Color:
	if maxf(absf(at.x),absf(at.y))>12500: return Color("354c49")
	var h := CoastalRegion.height_at(at.x,at.y)
	var water := h< -2.4 and Rect2(-360,-550,1100,1100).has_point(at)
	water = water or (at.distance_to(RegionalLake.CENTER)<RegionalLake.OUTER_RADIUS and h<RegionalLake.LEVEL)
	var channel := RegionalBrook.CENTER.x+RegionalBrook.MEANDER.x*sin((at.y-RegionalBrook.CENTER.y)*RegionalBrook.MEANDER.y)
	water = water or (absf(at.x-channel)<RegionalBrook.OUTER_WIDTH and absf(at.y-RegionalBrook.CENTER.y)<RegionalBrook.HALF_LENGTH+RegionalBrook.END_BLEND and h<6)
	if water: return Color("548f9c")
	var color := TerrainChunk.biome_color(at.x,at.y)
	if at.y< -5000: color = Color("8c978d").lerp(Color("edf0e8"),smoothstep(145,195,h))
	if at.x>70 and maxf(absf(at.x),absf(at.y))<400: color = Color("d6c299")
	var dx := CoastalRegion.height_at(at.x+step,at.y)-h
	var dz := CoastalRegion.height_at(at.x,at.y+step)-h
	var normal := Vector3(-dx,step,-dz).normalized()
	var shade := clampf(0.65+0.4*normal.dot(Vector3(-0.5,0.8,-0.4).normalized()),0.4,1.1)
	if fposmod(h,20)<1.5: shade *= 0.82
	return Color(color.r*shade,color.g*shade,color.b*shade,1)

static func texture(center: Vector2, extent: Vector2, pixels: Vector2i, cached: bool = true) -> Texture2D:
	var key := "%s/%s/%s"%[center,extent,pixels]
	if cached and sheets.has(key): return sheets[key]
	var image := Image.create(pixels.x,pixels.y,false,Image.FORMAT_RGB8)
	var step := extent.x/pixels.x
	for y in range(pixels.y):
		for x in range(pixels.x):
			var at := center+(Vector2(x+0.5,y+0.5)/Vector2(pixels)-Vector2.ONE*0.5)*extent
			image.set_pixel(x,y,color_at(at,step))
	var result := ImageTexture.create_from_image(image)
	if cached:
		if sheets.size()>=4: sheets.erase(sheets.keys()[0])
		sheets[key] = result
	return result
