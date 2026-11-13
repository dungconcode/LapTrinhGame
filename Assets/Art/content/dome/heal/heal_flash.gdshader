shader_type canvas_item;
//#TODO: CONVERSION, double check
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D flash;
uniform sampler2D noise : repeat_enable;
uniform float t : hint_range(0,1) = 0.0;

void fragment() {
	vec4 n = texture(noise, vec2(UV.x + TIME * 0.02, UV.y) * 0.3);
	vec4 s = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec2 uv = UV;
	uv *= 0.5;
	uv.x -= (t * 3.0 - 2.0) + n.r;
	vec4 m = texture(TEXTURE, UV);
	vec4 f = texture(flash, uv);
	COLOR.rgb = f.rgb * 0.25 + s.rgb * 4.0;
	COLOR.a = step(m.r, 0.9) * f.r * f.a * m.a;
}