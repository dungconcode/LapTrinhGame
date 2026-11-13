shader_type canvas_item;

void vertex() {
	// Pixellate UV
	vec2 grid_uv = UV / TEXTURE_PIXEL_SIZE;
	grid_uv = floor(grid_uv);
	grid_uv *= TEXTURE_PIXEL_SIZE;

	grid_uv.y += sin(TIME * 7.3 + VERTEX.x) * 0.03;
	grid_uv.y += sin(TIME * 77.3 + VERTEX.x) * 0.01;
	
	UV = grid_uv;
}