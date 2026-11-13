shader_type canvas_item;

uniform sampler2D palette : source_color;
uniform sampler2D remap_gradient : source_color;
uniform float multiplier = 1.0;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec3 tex = clamp(color.rgb/color.a, 0., 10.);
	vec4 input = texture(remap_gradient, vec2(clamp(tex.r*multiplier, 0.0, 1.0), 0.0));
	input.a = color.a;
	vec4 output = texture(palette, vec2(start_r + input.r, start_b+input.b));
	output.a = color.a;
	COLOR = output;
}