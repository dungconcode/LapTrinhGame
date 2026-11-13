shader_type canvas_item;

const float max_distance = 1.118; // pythagoras: sqrt(1² + 0.5²)

uniform sampler2D cracks_texture;
uniform int cracks_texture_size = 24;

uniform float top_damage = 0.0;
uniform float right_damage = 0.0;
uniform float bottom_damage = 0.0;
uniform float left_damage = 0.0;

uniform vec2 world_pos = vec2(0,0);
uniform vec4 ground_color : source_color  = vec4(0.07, 0.07, 0.1, 1.0);
uniform vec4 highlight_color : source_color = vec4(vec3(0.f), 1.f);
uniform vec2 frame_coords = vec2(1,0);
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
	vec2 local_uv = pixel_uv - frame_coords / sheet_size;
	
	vec2 dist_uv = local_uv * sheet_size;
	float top_distance = length(dist_uv - vec2(.5f, 0.f)) / max_distance;
	float right_distance = length(dist_uv - vec2(1.f, .5f)) / max_distance;
	float bottom_distance = length(dist_uv - vec2(.5f, 1.f)) / max_distance;
	float left_distance = length(dist_uv - vec2(0.f, .5f)) / max_distance;
	float bottom_left_distance = length(dist_uv - vec2(0.f, 1.f)) / max_distance;
	float bottom_right_distance = length(dist_uv - vec2(1.f, 1.f)) / max_distance;
	float top_left_distance = length(dist_uv - vec2(0.f, 0.f)) / max_distance;
	float top_right_distance = length(dist_uv - vec2(1.f, 0.f)) / max_distance;
	
	float damage_mask = step(top_distance, top_damage*0.8)
						+ step(right_distance, right_damage*0.8)
						+ step(bottom_distance, bottom_damage*0.8)
						+ step(left_distance, left_damage*0.8);
	
//	float damage_mask_l2 = step(top_distance, top_damage*0.5)
//						+ step(right_distance, right_damage*0.5)
//						+ step(bottom_distance, bottom_damage*0.5)
//						+ step(left_distance, left_damage*0.5);
	
	damage_mask = clamp(damage_mask, 0, 1);
	vec4 cracks = texture(cracks_texture, UV+world_pos);
	cracks.a *= damage_mask;
	cracks.rgb = mix(ground_color.rgb, cracks.rgb+highlight_color.rgb, 1);
	
	// Get base texture
	vec4 baseTexture = texture(TEXTURE, UV);
	vec4 output = texture(palette, vec2(start_r + baseTexture.r, start_b+baseTexture.b));
	output.a = baseTexture.a;
	// Version by raffa, matter of taste... this one keeps the "material" uncracked.
	COLOR = vec4(mix(cracks.rgb, output.rgb, output.a), max(output.a, cracks.a));
	
//	COLOR = vec4(mix(baseTexture.rgb, cracks.rgb, cracks.a), max(baseTexture.a, cracks.a));
//	COLOR = cracks;
	
	// DEBUG occlusion_mask
	//COLOR = vec4(mix(vec3(1,0,0), vec3(0,1,0), damage_mask_l2), damage_mask);
	// DEBUG cracks
	//COLOR = vec4(mix(vec3(1,0,0), vec3(0,1,0),texture(cracks_texture, UV+world_pos).a), 1.0);
}