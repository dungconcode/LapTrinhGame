shader_type canvas_item;
render_mode blend_add;

uniform sampler2D color_gradient : source_color;

void fragment(){
	float circles_mask = texture(TEXTURE, UV).r;
	COLOR = texture(color_gradient, vec2(circles_mask, 0.0));
}