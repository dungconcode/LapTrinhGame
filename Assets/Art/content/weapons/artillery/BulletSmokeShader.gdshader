shader_type canvas_item;
render_mode blend_mix, unshaded;

const vec3 main_col = vec3(1.0);

uniform sampler2D palette : source_color, filter_nearest;
uniform vec4 input : source_color;
uniform vec2 noise_speed = vec2(1.0, 1.0);
uniform sampler2D gradient_y : source_color;
uniform sampler2D gradient_x : source_color;
uniform sampler2D color_grad : source_color, filter_nearest;
uniform sampler2D noise : source_color, repeat_enable;
uniform float vertex_power = 40.0;
uniform vec2 vertex_noise_scale = vec2(2.0, 2.0);

varying float vertex_offset;
varying flat vec4 MODULATE;

void vertex() {
	MODULATE = COLOR;
	vec2 uv_offset = vec2(MODULATE.r, MODULATE.g);
	vec3 val_y = texture(gradient_x, UV).rgb;
	vec2 tex_position = (VERTEX.xy - vec2(0.5))*vertex_noise_scale;
	float height_x = texture(noise, vec2(0.5)+tex_position+uv_offset+TIME*vec2(0.02, 0.02)).r-0.5;
	float height_y = texture(noise, tex_position+uv_offset+TIME*vec2(0.02, 0.02)).r-0.5;
	VERTEX += vec2(height_x, height_y) * vertex_power * pow(val_y.g, 2.0);
	vertex_offset = clamp((height_x+height_y)*0.5, 0.0, 1.0);
}

void fragment() {
	const float start_r = 0.5 / float(32);
	const float start_b = 0.5 / float(12);
	vec4 output_color = texture(palette, vec2(start_r + input.r, start_b+input.b));
	
	vec3 val_y = texture(gradient_x, UV).rgb;
	val_y.b = MODULATE.b;
	vec2 uv_offset = vec2(MODULATE.r, MODULATE.g);
	vec2 noise_tex1 = texture(noise, uv_offset+SCREEN_UV+vec2(TIME*noise_speed*0.005)).rg-.5 * val_y.g;
	vec2 noise_tex2 = texture(noise, uv_offset+SCREEN_UV+vec2(TIME*noise_speed*0.1)).rg-.5 * val_y.g;
	vec2 noise_tex = mix(noise_tex1, noise_tex2, val_y.g)*val_y.g;
	vec4 tex = texture(gradient_y, noise_tex*0.5 + UV);
	float inv_val_y =  abs(1.0-val_y.g);
	float grad_y = tex.r;
	float alpha = grad_y * val_y.r - (UV.y*val_y.b*2.0) - texture(noise, uv_offset+SCREEN_UV+TIME*(0.01*noise_speed)).r * 0.8 * inv_val_y;
	
	float inv_val_y_b = abs(1.0-val_y.b);
	vec3 col = texture(color_grad, vec2(alpha*inv_val_y_b, 0.0)).rgb;
	col = mix(col*abs(1.0-vertex_offset), col, val_y.r);
	COLOR = vec4(main_col, step(0.02, alpha*inv_val_y_b)*clamp(col.r, 0.0, 1.0)) * output_color;
	COLOR *= 1.0 + pow(val_y.r, 10.0)*2.0;
}