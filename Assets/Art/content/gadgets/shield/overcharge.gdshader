shader_type canvas_item;
//#TODO: CONVERSION, double check
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform sampler2D noise_texture : repeat_enable;
uniform sampler2D palette;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

void fragment() {
	vec2 uv = UV;
	vec2 nuv = UV;
	
	nuv.y += TIME * 0.1;
	vec4 n = texture(noise_texture, nuv);
	uv.x += (n.r - 0.5) * 0.3;
	uv.y += (n.g - 0.5) * 0.3;

	vec2 suv = SCREEN_UV;
	suv.x += (n.r - 0.5) * 0.1;
	suv.y += (n.g - 0.5) * 0.1;
	
	vec4 c = texture(TEXTURE, uv);
	vec4 s = texture(SCREEN_TEXTURE, suv);
	c.xyz *= 0.5;
	s.xyz *= 0.5;
	s.a = c.a;

	vec4 output = texture(palette, vec2(start_r + c.r, start_b+c.b));
	output.a = c.a;
	
	COLOR = output * 0.8 + s * 0.6;
}