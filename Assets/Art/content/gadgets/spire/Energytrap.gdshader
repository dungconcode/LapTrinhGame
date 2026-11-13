shader_type canvas_item;
//#TODO: CONVERSION, double check
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform int pixelation_factor = 100;
uniform sampler2D noise : repeat_enable;
uniform sampler2D distortion : repeat_enable;

void fragment()
{
	vec2 grid_uv = round(UV * float(pixelation_factor)) / float(pixelation_factor);
	
	float offset = TIME + SCREEN_UV.y * SCREEN_UV.x;
	vec4 fill = texture(TEXTURE, grid_uv);
	float alpha = texture(noise, vec2(grid_uv.x + offset * 0.5, grid_uv.y - 0.05 * sin(offset * 6.0))).r * fill.a;
	
	vec2 nuv = UV;
	nuv.y += TIME * 0.2;
	vec4 n = texture(distortion, nuv);
	vec2 suv = SCREEN_UV;
	suv.x += (n.r - 0.5);
	suv.y += (n.g - 0.5);
	vec4 bg = texture(SCREEN_TEXTURE, suv);
	
	COLOR.rgb = bg.rgb * 2.0;
	COLOR.rgb = clamp(COLOR.rgb, vec3(0.0), vec3(1.5));
	COLOR.rgb -= vec3(0.3);
	COLOR.a = step(0.05, alpha);
}