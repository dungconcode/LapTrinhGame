shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable;
uniform vec2 stretch = vec2(1.0);

void fragment() {
	vec2 noise_uv = UV;
	noise_uv.y -= TIME;
	vec4 n = texture(noise_texture, noise_uv);
	
	vec2 uv = UV;
	uv.y += (n.g - 0.5);
	uv.y += sin(TIME) * 0.2;

	float dist = distance(UV * stretch + vec2(0.5), vec2(0.5));
	vec4 c = texture(TEXTURE, uv);
	c.a *= smoothstep(1.0, 0.5, dist);
	
	COLOR.rgb = vec3(0.0);
	COLOR.r = 1.0;
	COLOR.a = 1.0-dist;
	
	COLOR = c;
}