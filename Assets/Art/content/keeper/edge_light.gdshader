shader_type canvas_item;
//#TODO: CONVERSION, double check
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float light_threshold = 0.05;
const float color_normalize = 1.0/255.0;

uniform sampler2D palette;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

void fragment() {
	vec4 screen_tex = texture(SCREEN_TEXTURE, SCREEN_UV);
	float color_dist_rock = distance(screen_tex.rgb, vec3(53, 56, 71)*color_normalize);
	float color_dist_yellow = distance(screen_tex.rgb, vec3(64, 54, 46)*color_normalize);
	float color_dist_green = distance(screen_tex.rgb, vec3(48, 59, 66)*color_normalize);
	float color_dist_red = distance(screen_tex.rgb, vec3(64, 50, 68)*color_normalize);
	float color_dist_blue = distance(screen_tex.rgb, vec3(55, 54, 75)*color_normalize);
	
	vec4 input = texture(TEXTURE, UV);
	vec4 output = texture(palette, vec2(start_r + input.r, start_b+input.b));
	
	COLOR.rgb = output.rgb;
	COLOR.a = (step(color_dist_rock, light_threshold) + step(color_dist_yellow, light_threshold) + step(color_dist_green, light_threshold) + step(color_dist_red, light_threshold) + step(color_dist_blue, light_threshold)) * input.a;
}