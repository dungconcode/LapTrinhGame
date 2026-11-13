shader_type canvas_item;

uniform float speed = 20.0;

void vertex() {
	vec2 uv = UV;
	uv.x -= TIME * 0.05 * speed;
	UV = uv;
}
//void fragment() {
//	vec2 uv = UV;
//	uv.x -= TIME * 0.05 * speed;
//	COLOR = texture(TEXTURE, uv) * MODULATE;
//}

uniform sampler2D palette;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

void fragment() {
	vec4 input = texture(TEXTURE, UV);
	vec4 output = texture(palette, vec2(start_r + input.r, start_b+input.b));
	output.a = input.a;
	COLOR.rgba = output;
}