shader_type canvas_item;

uniform sampler2D palette;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

void fragment() {
	vec4 input = texture(TEXTURE, UV);
	highp float c = 0.33333333*(input.r+input.g+input.b);
	vec4 output = texture(palette, vec2(start_r + input.r, start_b+input.b));
	output.a = input.a;
	output.a *= smoothstep(2.0, 0.8, (1.1 + abs(sin(-UV.x+TIME*5.0))));
	COLOR.rgba = output;
}