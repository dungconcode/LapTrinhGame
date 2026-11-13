shader_type canvas_item;

uniform sampler2D palette;
const int elements_r = 32;
const int elements_b = 12;
const int elements_step_r = 8;
const int elements_step_b = 20;
const float max_r = float((elements_r)*elements_step_r)/255.0;
const float max_b = float((elements_b)*elements_step_b)/255.0;
const float start_r = 0.5 / float(elements_r);
const float start_b = 0.5 / float(elements_b);

void fragment() {
	vec4 input = texture(TEXTURE, UV);
	highp float c = 0.33333333*(input.r+input.g+input.b);
	input *= smoothstep(2.4, 0.5, (0.6 + abs(sin(-UV.x+TIME*6.0))));

	vec4 output = texture(palette, vec2(start_r + input.r/max_r, start_b+input.b/max_b));
	output.a = input.a;
	COLOR.rgba = output;
}