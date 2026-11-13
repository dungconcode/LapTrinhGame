shader_type canvas_item;

uniform float fade_x : hint_range(-0.5, 1.0) = 0.0f;
uniform float size_x : hint_range(0, 0.5) = 0.05f;
uniform float fade_y : hint_range(-0.5, 1.0) = 0.0f;
uniform float size_y : hint_range(0, 0.5) = 0.05f;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR.rgb = tex.rgb;
	float from_center = abs(0.5 - UV.x);
	float a = clamp(smoothstep(fade_x - size_x, fade_x, from_center), 0.0, tex.a);
	COLOR.a = clamp(min(a, smoothstep(fade_y+size_y, fade_y, UV.y)), 0.0, tex.a);
}