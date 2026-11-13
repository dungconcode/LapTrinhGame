shader_type canvas_item;

uniform float noise_power = 0.08;
uniform float noise_speed = 0.2;
uniform sampler2D noise_map : source_color, repeat_enable;
uniform vec2 world_pos;

void fragment(){
	vec2 uv = world_pos*TEXTURE_PIXEL_SIZE*2.0 + UV*0.5;
	float noise_1 = texture(noise_map, uv + TIME*noise_speed * vec2(+0.15, -0.05)).r - 0.5;
	float noise_2 = texture(noise_map, uv + TIME*noise_speed * vec2(-0.1, 0.15)).g - 0.5;
	float noise_3 = texture(noise_map, uv + TIME*noise_speed * vec2(-0.1, -0.15)).b - 0.5;
	vec2 noised_val = vec2(noise_1*noise_2, noise_1*noise_3);
	vec2 noised_uv = UV + (noised_val * noise_power);
	COLOR = texture(TEXTURE, noised_uv);
}