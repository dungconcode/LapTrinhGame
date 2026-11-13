shader_type canvas_item;
uniform float scale = 1.0;
uniform float speed = 1.0;

void vertex() {
	vec2 uv = UV;
	uv.x -= TIME * speed;
	uv *= 1.0/scale;
	UV = uv;
}

uniform sampler2D palette;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

void fragment() {
	vec4 input = texture(TEXTURE, UV);
	vec4 output = texture(palette, vec2(start_r + input.r, start_b+input.b));
	output.a = input.a;
	COLOR.rgba = output;
}
