shader_type canvas_item;

uniform float flash_rate = 0.f;
uniform float flash_magnitude = 0.f;
uniform bool outline = false;

uniform sampler2D palette;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);
const vec2 outline_color_key = vec2(start_r + (8.0/256.0), start_b+(180.0/256.0));

void fragment() {
	// Flash
	vec4 t = texture(TEXTURE, UV);
	vec4 input = texture(palette, vec2(start_r + t.r, start_b+t.b));
	input.a = t.a;
	highp float c = 0.33333333*(input.r+input.g+input.b);
	float flash_freq = TIME*flash_rate*6.2831853;
	float flash_val = flash_magnitude * 0.5*(sin(flash_freq)+0.8);
	input.rgb = input.rgb + vec3(1.0,1.0,1.0) * flash_val;
	
	// Outline
	if (outline && input.a == 0.f) {
		vec2 offset = TEXTURE_PIXEL_SIZE;
		vec4 sample = vec4(0.f);
		sample += texture(TEXTURE, vec2(UV.x+offset.x, UV.y));
		sample += texture(TEXTURE, vec2(UV.x-offset.x, UV.y));
		sample += texture(TEXTURE, vec2(UV.x, UV.y+offset.y));
		sample += texture(TEXTURE, vec2(UV.x, UV.y-offset.y));
		input.rgb = texture(palette, outline_color_key).rgb;
		input.a = 1.f * step(0.9, sample.a);
	}
	
	COLOR = input;
}