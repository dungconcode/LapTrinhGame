shader_type canvas_item;

//tr = top right
uniform float hide_tr;
uniform float hide_tl;
uniform float hide_br;
uniform float hide_bl;

uniform vec2 frame_coords;
uniform vec2 sheet_size = vec2(12,12);

uniform sampler2D palette;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

vec2 get_pixel_uv(vec2 uv, vec2 texture_pixel_size) {
	uv /= texture_pixel_size;
	uv = floor(uv);
	uv *= texture_pixel_size;
	return uv;
}

void fragment() {
	vec2 pixel_uv = get_pixel_uv(UV, TEXTURE_PIXEL_SIZE);
	
	vec2 cell_size = vec2(1.f) / sheet_size;
	float cell_radius = sqrt(pow(cell_size.x*0.5, 2) + pow(cell_size.y*0.5, 2));
	vec2 start_uv = cell_size * frame_coords;
	vec2 end_uv = start_uv + cell_size;
	
	vec2 tile_local_uv = pixel_uv - start_uv;
	float tr_distance = length(vec2(cell_size.x, 0.f) - tile_local_uv);
	float tl_distance = length(vec2(0.f, 0.f) - tile_local_uv);
	float br_distance = length(vec2(cell_size.x, cell_size.y) - tile_local_uv);
	float bl_distance = length(vec2(0.f, cell_size.y) - tile_local_uv);
	
	float damage_mask = step(tr_distance, cell_radius - cell_radius * hide_tr)
						+ step(tl_distance, cell_radius - cell_radius * hide_tl)
						+ step(br_distance, cell_radius - cell_radius * hide_br)
						+ step(bl_distance, cell_radius -cell_radius * hide_bl);
	damage_mask = clamp(damage_mask, 0, 1);
	
	vec4 baseTexture = texture(TEXTURE, UV);
	vec4 output = texture(palette, vec2(start_r + baseTexture.r, start_b+baseTexture.b));
	COLOR = vec4(output.rgb, damage_mask * baseTexture.a);
}