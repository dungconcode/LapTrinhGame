shader_type canvas_item;

uniform float power : hint_range(0, 10) = 0.0;
uniform float speed : hint_range(0, 10) = 0.0;

uniform sampler2D palette;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

void fragment() {
	vec2 uv = UV;

	// Pixellate UV
	uv /= TEXTURE_PIXEL_SIZE;
	uv = floor(uv);
	uv *= TEXTURE_PIXEL_SIZE;

	uv.x -= TIME * speed * 2.f;
	uv.y += sin(uv.x * 3.f + TIME * 11.f) * 0.5 * power/30.0;
	uv.y += sin(uv.x * 7.f + TIME * 13.f) * 0.35 * power/30.0;
	uv.y += sin(uv.x * 13.f + TIME * 41.f) * 0.2 * power/30.0;
	vec4 input = texture(TEXTURE, uv);
	vec4 output = texture(palette, vec2(start_r + input.r, start_b+input.b));
	output.a = input.a;
	COLOR.rgba = output;
}