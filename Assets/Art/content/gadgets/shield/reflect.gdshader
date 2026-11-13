shader_type canvas_item;

//#TODO: CONVERSION, double check
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_texture;

void fragment() {
	vec2 uv = UV;
	vec2 nuv = UV;
	
	//nuv *= 0.2/(progress + 0.01);
	nuv.y += TIME * 0.1;
	nuv *= 1.0 / (progress * 0.3 + 0.7);
	vec4 n = texture(noise_texture, nuv);
	uv.x += (n.r - 0.5) * 0.001 * (1.0 - progress);
	uv.y += (n.g - 0.5) * 0.02 * (1.0 - progress);

	vec2 suv = SCREEN_UV;
	suv.x += (n.r - 0.5) * 0.01 * (1.0 - progress);
	suv.y += (n.g - 0.5) * 0.1 * (1.0 - progress);
	
	vec4 c = texture(TEXTURE, uv);
	vec4 s = texture(SCREEN_TEXTURE, suv);
	c.xyz *= 0.5;
	s.xyz *= 0.5;
	s.a = c.a;
	
	COLOR = c + s;
}