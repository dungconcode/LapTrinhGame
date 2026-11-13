shader_type canvas_item;

uniform int pixelation_factor = 100;
uniform sampler2D noise : repeat_enable;

uniform sampler2D palette;
const float i_r1 = 5.5 / float(32);
const float i_r2 = 10.5 / float(32);
const float i_b = 5.5 / float(12);

void fragment()
{
	vec2 grid_uv = round(UV * float(pixelation_factor)) / float(pixelation_factor);
	
	vec4 c = texture(TEXTURE, grid_uv);
	vec4 output = c;
	output.r = texture(noise, vec2(grid_uv.x, grid_uv.y + 0.8 * TIME)).r * c.a;
	vec3 p1 = texture(palette, vec2(i_r1, i_b)).rgb;
	vec3 p2 = texture(palette, vec2(i_r2, i_b)).rgb;
	
	vec3 c1 = p2 * step(1.50, output.r + output.g + output.b);
	vec3 c2 = p1 * step(1.39, output.r + output.g + output.b);
	COLOR.rgb = c1+c2;
	COLOR.a = step(0.05, COLOR.r);
}