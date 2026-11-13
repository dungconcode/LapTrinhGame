shader_type canvas_item;
render_mode unshaded;

uniform sampler2D palette : source_color;
uniform sampler2D remap_gradient : source_color;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

uniform sampler2D noise : source_color, repeat_enable;
uniform sampler2D image_texture : source_color;
uniform sampler2D image_multiplier : source_color;
uniform sampler2D image_add : hint_default_black;
uniform sampler2D image_gradient_tint : hint_default_black;
uniform float extra_power = 1.0;

uniform float effect_scale = 1.0;
uniform float effect_repeat = 2.0;
uniform vec2 effect_center = vec2(0.5);
uniform vec2 uv_mod = vec2(1.0);
uniform vec2 scroll_speed = vec2(0.0);

uniform float pulse_rate_1 = 7.0;
uniform float pulse_rate_2 = 12.0;
uniform float pulse_intensity = 0.02;

uniform float noise_scale = 0.06;
uniform float noise_size = 1.0;

void vertex() {
	float pulse_freq_1 = TIME * pulse_rate_1 * TAU;
	float pulse_freq_2 = TIME * pulse_rate_2 * TAU;
	float pulse_val = 0.25*((sin(pulse_freq_1)+1.0)+(sin(pulse_freq_2)+1.0));
	pulse_val *= pulse_val;
	float pulse_size = (pulse_val*pulse_intensity)-pulse_intensity;
	VERTEX *= 1.+pulse_size;
}

vec2 coordinates(vec2 uv, vec2 center, float scale, float repeat) {
	vec2 dir = uv - center;
	float radius = length(dir)*2.0;
	float angle = (atan(dir.x, dir.y) / TAU)+0.5;
	return vec2(angle*repeat, radius*scale);
}

void fragment(){
	float noise_x = (texture(noise, (noise_size*UV)+TIME).r);
	float noise_y = (texture(noise, (noise_size*UV)-TIME).g);
	vec2 noise_v2 = vec2(noise_x-0.5, noise_y-0.5)*noise_scale;
	vec2 uv = uv_mod*coordinates(UV+noise_v2, effect_center, effect_scale, effect_repeat);
	vec4 image_tex = texture(image_texture, mod(uv+(TIME*scroll_speed), 1.0));
	image_tex *= image_tex.a;
	image_tex *= texture(image_multiplier, UV+noise_v2);
	image_tex += texture(image_add, UV+noise_v2);
	vec4 input = textureLod(image_gradient_tint, vec2(clamp(image_tex.r, 0.0, 1.0)*extra_power, 0.0), 1.0)*extra_power;
	input.rgb = texture(remap_gradient, vec2(input.r, 0.0)).rgb;
	COLOR = vec4(texture(palette, vec2(start_r + input.r, start_b+input.b)).rgb, input.a);
}