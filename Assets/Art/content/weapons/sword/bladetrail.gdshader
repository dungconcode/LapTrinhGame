shader_type canvas_item;

uniform sampler2D palette;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

void fragment() {
	vec2 uv = UV;
	uv.y += sin(uv.x + TIME * 15.0) * 0.03 + sin(uv.x * 3.3 + TIME * 40.0) * 0.012;
	vec4 input = texture(TEXTURE, uv);
	vec4 output = texture(palette, vec2(start_r + input.r, start_b+input.b));
	output.a = input.a;
	COLOR = output;
}