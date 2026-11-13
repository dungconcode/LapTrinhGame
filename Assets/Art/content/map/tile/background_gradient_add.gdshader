shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D palette;

uniform vec4 ground_color : source_color;
const float start_r = 0.5 / 32.0;
const float start_b = 0.5 / 12.0;
uniform float grad_length = 100.0;
uniform float u_grad_offset = 10.0;
uniform float background_multiplier = 1.0;

void fragment(){
	float g_offset = TEXTURE_PIXEL_SIZE.y*u_grad_offset;
	float g_length = TEXTURE_PIXEL_SIZE.y*grad_length;
	vec4 bg_color = texture(palette, vec2(start_r + ground_color.r, start_b + ground_color.b));
	vec3 grad_color = bg_color.rgb * (1.0 - smoothstep(0.0, 1.5, ((UV.y+g_offset)/g_length) ));
	
	COLOR.rgb = texture(TEXTURE, UV).rgb + grad_color * background_multiplier;
	COLOR.a = texture(TEXTURE, UV).a;
}