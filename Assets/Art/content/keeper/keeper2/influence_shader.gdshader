shader_type canvas_item;

uniform sampler2D noise_texture;
uniform float scale : hint_range(0, 100.0) = 25.0;

void vertex() {
	vec2 noise_uv = VERTEX * 0.1;
	noise_uv.x += TIME * 0.2;
	vec2 n = texture(noise_texture, noise_uv).rg;
	
	vec2 offset = vec2(0.0);
	offset.y += (n.g-0.5);
	offset.x += (n.r-0.5);
	offset *= scale;
	
	VERTEX = VERTEX + offset;
}
