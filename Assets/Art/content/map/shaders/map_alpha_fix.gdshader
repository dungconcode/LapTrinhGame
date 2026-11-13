shader_type canvas_item;
render_mode blend_mix;

varying flat vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec3 color_fix = clamp(color.rgb/color.a, 0., 10.);
	COLOR = modulate * vec4(color_fix,color.a);
}