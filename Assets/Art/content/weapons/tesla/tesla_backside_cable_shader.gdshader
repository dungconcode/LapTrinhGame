shader_type canvas_item;
render_mode blend_mix;

const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

uniform sampler2D palette;
uniform sampler2D gradient : source_color;
uniform sampler2D gradient_color : source_color;
uniform float fill = 0.5;
uniform float power = 0.5;

void fragment(){
	vec4 tex = texture(TEXTURE, UV);
	float glow = texture(gradient, vec2(fract((tex.g)-TIME-tex.r), 0.0)).r * power;
	glow += smoothstep(fill+0.1, fill, tex.g)*0.6;
	glow = clamp(glow*tex.b, 0.0, 1.0);
	vec4 input = texture(gradient_color, vec2(glow, 0.0));
	vec4 output = texture(palette, vec2(start_r + input.r, start_b+input.b));
	output.a = step(0.01, glow);
	COLOR = output;
}