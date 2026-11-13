shader_type canvas_item;
render_mode blend_mix;

uniform vec2 base_scale = vec2(1.0, 1.0);
const vec2 crack_tex_size = vec2(288.0);


uniform vec4 ground_color : source_color;
const float start_r = 0.5 / 32.0;
const float start_b = 0.5 / 12.0;
uniform float grad_length = 100.0;
uniform float u_grad_offset = -12.0;

//REMINDER: set_shader_parameter works only on the first 8 samplers with Metal
//be careful about ordering. move static textures to the back.
uniform sampler2D palette;
uniform sampler2D crack_impact : filter_nearest;
uniform sampler2D mask_map : filter_linear;
uniform sampler2D light_map : filter_nearest;
uniform sampler2D rock_falloff_map : filter_linear;
uniform sampler2D damage_map : filter_linear;
uniform sampler2D cracks_tiled_map : repeat_enable, filter_nearest;
uniform sampler2D biome_color_map : filter_nearest;

uniform sampler2D mask_noise_map : repeat_enable;
uniform sampler2D mask_noise_factor_map : repeat_enable, filter_linear;
uniform sampler2D mask_noise_big_map : repeat_enable;

uniform float edge_straightness_factor = 0.5;
uniform float noise_power;
uniform float noise_power_big;

// Main Edge outline (light catcher)
uniform float outline_scale;
uniform float outline_pos = 0.221;
uniform float outline_edge_pos = 0.7;

// Inner Edge (stone color)
uniform float edgecol_scale;
uniform float edgecol_hardness_factor;
uniform float edgecol_edge_pos = 0.7;

// Fog Edge
uniform float shadow_pos = 0.7;
uniform float shadow_pos_small = 0.7;
uniform float shadow_darkness = 0.67;
uniform float falloff_mix_factor = 0.5;
uniform float falloff_mix_factor_2 = 0.5;

uniform vec4 lightblocker_col : source_color;

uniform float temp_damage_step_c = 0.5;
uniform float temp_damage_step_s = 0.5;
uniform float temp_damage_step_a = 0.5;
uniform float temp_damage_mult_a = 0.5;

float make_outline(vec2 s, sampler2D mm, vec2 uv) {
	lowp float outline = texture(mm, uv + vec2(-s.x, 0)).r;
	outline += texture(mm, uv + vec2(s.x, 0)).r;
	outline += texture(mm, uv + vec2(0, s.y)).r;
	outline += texture(mm, uv + vec2(0, -s.y)).r;
	outline += texture(mm, uv + vec2(-s.x, s.y)).r;
	outline += texture(mm, uv + vec2(s.x, s.y)).r;
	outline += texture(mm, uv + vec2(-s.x, -s.y)).r;
	outline += texture(mm, uv + vec2(s.x, -s.y)).r;
	return outline;
}

uniform vec2 pixel_size = vec2(200.0);

void fragment() {
	vec2 grid_uv = vec2(floor(UV.x * pixel_size.x) / pixel_size.x, floor(UV.y * pixel_size.y) / pixel_size.y);
	vec2 texture_pixel_size_12 = TEXTURE_PIXEL_SIZE*12.0;

	vec2 SCALED_UV = grid_uv*base_scale;
	// Base noise (small noise) that is used for the inner edge of the tunnel
	lowp float mask_noise = texture(mask_noise_map, SCALED_UV).r-0.5;
	vec2 mask_noise_factor_map_tex = texture(mask_noise_factor_map, grid_uv).rg;
	lowp float edge_straightness = step((mask_noise_factor_map_tex.r * mask_noise_factor_map_tex.r), edge_straightness_factor);
	lowp vec2 displaced_uv = mix(grid_uv, grid_uv+mask_noise, noise_power * edge_straightness);

	// Light Catcher outline
	vec2 line_size = TEXTURE_PIXEL_SIZE * outline_scale;
	lowp float outline = step(outline_edge_pos, make_outline(line_size, mask_map, displaced_uv));

	// Stone Color outline
	float hardness_edge_size = mask_noise_factor_map_tex.g * edgecol_hardness_factor;
	vec2 edge_size = TEXTURE_PIXEL_SIZE * (edgecol_scale + hardness_edge_size);
	lowp float edge_line = step(edgecol_edge_pos, make_outline(edge_size, mask_map, displaced_uv));

	// Main big noise
	lowp float mask_noise_big = texture(mask_noise_big_map, SCALED_UV).r-0.5;
	lowp vec2 displaced_bigger_uv = mix(grid_uv, grid_uv+mask_noise_big, noise_power_big);

	// Stone color based on the Maps biome color setting using the big noise for the transition
	lowp vec3 stone_color = texture(biome_color_map, displaced_bigger_uv).rgb;
	lowp float hardness_map = texture(mask_noise_factor_map, displaced_bigger_uv).g;

	// This falloff is used for the shadow fadeout and rock shape falloff.
	lowp float falloff_map = texture(rock_falloff_map, displaced_bigger_uv).r;
	lowp float falloff_map_x2 = texture(rock_falloff_map, displaced_bigger_uv + texture_pixel_size_12).g;
	lowp float adapted_falloff_mix_factor = mix(falloff_mix_factor, falloff_mix_factor_2, hardness_map);
	lowp float mixed_falloff = mix(falloff_map, falloff_map_x2, adapted_falloff_mix_factor);
	mixed_falloff = max(mixed_falloff, falloff_map);

	// The color of the Lightedge
	lowp vec4 light_px = texture(light_map, grid_uv);
	lowp vec3 light_color = mix(stone_color*1.3, light_px.rgb, light_px.a);
	lowp vec3 color = texture(TEXTURE, UV).rgb;
	lowp float stone_paint = (mixed_falloff > 0.01) ? color.b : 0.0;
	stone_paint += (mixed_falloff > 0.3) ? color.g : 0.0;
	stone_paint += (mixed_falloff > 0.6) ? color.r : 0.0;
	stone_paint = min(stone_paint, 1.0);

	// Tunnel cutout is used to remove the alpha where the tunnel is dug
	lowp float mask = abs(texture(mask_map, displaced_uv).r - 1.0);
	lowp float tunnel_cutout = step(outline_pos, mask);

	// Generate the "shadow" fadeout of the stones.
	lowp float shadow = step(shadow_pos, mixed_falloff);
	lowp float shadow_small = step(shadow_pos_small, mixed_falloff);
	lowp float alpha = clamp((stone_paint + outline + edge_line) * tunnel_cutout, 0.0, 1.0) * shadow;
	// Colors are combined, the lit edge and the main stone color (from biome)
	lowp vec3 stone_color_combined = (mixed_falloff < shadow_pos_small) ? (stone_color.rgb * shadow_darkness) : stone_color.rgb;
	lowp vec3 final_color = (outline < 0.5) ? stone_color_combined : light_color;

	// Putting together the damage map
	lowp vec2 px = texture_pixel_size_12;
	lowp float dc = texture(damage_map, grid_uv).b;
	lowp float dx = texture(damage_map, grid_uv + vec2(px.x, 0.0)).r;
	lowp float dy = texture(damage_map, grid_uv + vec2(0.0, px.y)).g;
	lowp float damage_value = clamp(step(temp_damage_step_c, dc) + step(temp_damage_step_s, dx+dy) - temp_damage_step_a, 0.0, 1.0);

	lowp vec2 cracks_uv = UV*(pixel_size/crack_tex_size);
	damage_value = (texture(cracks_tiled_map, cracks_uv).a < 0.5) ? 0.0 : damage_value;

	lowp vec3 stone_color_inv = mix(mix(stone_color.rgb, stone_color*1.3, shadow_small), stone_color.rgb*0.5, outline+edge_line);
	stone_color_inv = (texture(crack_impact, grid_uv).r < 0.5) ? stone_color_inv : vec3(1.0);

	lowp float visible_area = min(alpha + (damage_value * tunnel_cutout * shadow), 1.0);

	// Background Gradient
	lowp float g_offset = TEXTURE_PIXEL_SIZE.y*u_grad_offset;
	lowp float g_length = TEXTURE_PIXEL_SIZE.y*grad_length;
	lowp vec4 bg_color = texture(palette, vec2(start_r + ground_color.r, start_b + ground_color.b));
	//lowp vec3 grad_color = bg_color.rgb * (1.0 - smoothstep(0.0, 1.5, ((grid_uv.y+g_offset)/g_length) ));


	// avoiding smoothstep
	lowp float gradient_factor = clamp(((grid_uv.y + g_offset) / g_length) / 1.5, 0.0, 1.0);
	lowp vec3 grad_color = bg_color.rgb * (1.0 - gradient_factor);


	COLOR.rgb = mix(grad_color, mix(final_color, stone_color_inv, damage_value), visible_area);
	COLOR.a = tunnel_cutout;

	//debug feature to visualize rock falloff
	//if (toggledebug)
	//{
	//	COLOR.r = texture(rock_falloff_map, UV).r;
    //	COLOR.g = texture(rock_falloff_map, UV+(TEXTURE_PIXEL_SIZE*12.0)).g;
    //	COLOR.a = min(COLOR.a+0.8, 1.0);
	//}
}