shader_type canvas_item;

uniform sampler2D palette;
const float i_r1 = 1.5 / float(32);
const float i_r2 = 10.5 / float(32);
const float i_b = 5.0 / float(12);

uniform int pixelation_factor = 100;
uniform sampler2D noise;

void fragment()
{
	vec2 grid_uv = round(UV * float(pixelation_factor)) / float(pixelation_factor);
	
	vec3 p1 = texture(palette, vec2(i_r1, i_b)).rgb;
	vec3 p2 = texture(palette, vec2(i_r2, i_b)).rgb;
	
	float offset = TIME + SCREEN_UV.y * SCREEN_UV.x;
	vec4 fill = texture(TEXTURE, grid_uv);
	fill.r = texture(noise, vec2(grid_uv.x + offset * 0.5, grid_uv.y - 0.05 * sin(offset * 6.0))).r * fill.a;
	fill.g = texture(noise, vec2(grid_uv.x * 0.5 + offset * 0.05, grid_uv.y * 0.5 + offset * 0.05)).r * fill.a;
	fill.b = texture(noise, vec2(grid_uv.x * offset * 0.0001, grid_uv.y * offset * 0.0001)).r * fill.a;
	vec3 c1 = p2 * step(1.68, fill.r + fill.g + fill.b);
	vec3 c2 = p1 * step(1.1, fill.r + fill.g + fill.b);
	
	COLOR.rgb = c2 + c1;
	COLOR.a = step(0.05, COLOR.r);
}