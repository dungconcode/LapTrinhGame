shader_type canvas_item;

void vertex() {
	// Pixellate UV
	vec2 grid_uv = UV / TEXTURE_PIXEL_SIZE;
	grid_uv = floor(grid_uv);
	grid_uv *= TEXTURE_PIXEL_SIZE;

	grid_uv.y += TIME * 3.0;
	grid_uv.x -= TIME * 1.0;
	
	UV = grid_uv;
}