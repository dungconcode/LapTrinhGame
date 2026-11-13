shader_type canvas_item;
render_mode blend_add;

uniform sampler2D color_gradient : source_color;
uniform float step_edge = 0.15;
uniform int pixel_grid_size = 40;
uniform float noise_power = 0.1;
uniform float noise_speed = 0.1;
uniform float radius = 0.5;
uniform float edge_width = 0.8;
uniform sampler2D noise_map : source_color, repeat_enable;

varying flat vec4 modulate;

void vertex() {
	modulate = COLOR;
}

float circle(in vec2 uv, in float _radius){
    vec2 dist = uv - vec2(0.5);
	return 1.-smoothstep(_radius-(_radius*edge_width), _radius+(_radius*edge_width), dot(dist,dist)*4.0);
}


void fragment(){
	vec2 grid_uv = round(UV * float(pixel_grid_size)) / float(pixel_grid_size);

	float noise_1 = texture(noise_map, grid_uv + TIME*noise_speed * vec2(+0.15, -0.05)).r - 0.5;
	float noise_2 = texture(noise_map, grid_uv + TIME*noise_speed * vec2(-0.1, 0.15)).g - 0.5;
	float noise_3 = texture(noise_map, grid_uv + TIME*noise_speed * vec2(-0.1, -0.15)).b - 0.5;

	vec2 noised_val = vec2(noise_1*noise_2, noise_1*noise_3);
	vec2 noised_uv = grid_uv + (noised_val * noise_power);
	float radius_f = radius/float(pixel_grid_size/2);
	float circles_mask = circle(noised_uv, pow(radius_f, 2.0));

	COLOR = texture(color_gradient, vec2(circles_mask, 0.0))*modulate;
}