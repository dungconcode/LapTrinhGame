/*
This shader improves the growth rate of the cracks. It adjusts the curve of the gradient in the texture,
extremer curve means longer growth time.
*/
shader_type canvas_item;
render_mode blend_add;

varying vec3 power;

void vertex() {
	power = INSTANCE_CUSTOM.rgb;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = vec4(tex.rgb, pow(tex.a, power.r)*power.g);
}