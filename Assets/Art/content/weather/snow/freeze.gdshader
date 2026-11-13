shader_type canvas_item;
//#TODO: CONVERSION, double check
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D normal_tex;
uniform float strength = 0.f;
uniform vec2 scale = vec2(1.0);

vec2 get_pixel_uv(vec2 uv, vec2 texture_pixel_size) {
	uv /= texture_pixel_size;
	uv = floor(uv);
	uv *= texture_pixel_size;
	return uv;
}

void fragment() {
	vec2 suv = SCREEN_UV;
	vec2 uv = UV;
	vec4 c = texture(TEXTURE, uv);
	vec4 n = texture(normal_tex, uv * scale);
	suv.x += (n.r-0.5) * 0.05;
	suv.y += (n.g-0.5) * 0.05;
	vec4 distort = texture(SCREEN_TEXTURE, suv);
	COLOR = clamp(c * 0.4 + distort * smoothstep(1.f-strength, 1.f, c.a), vec4(0.f), vec4(1.f));
}