shader_type canvas_item;

uniform int pixelation_factor = 100;
uniform sampler2D noise : repeat_enable;

uniform sampler2D palette;
const float i_r = 3.5 / float(32);
const float i_b = 2.5 / float(12);

void fragment()
{
	vec2 grid_uv = round(UV * float(pixelation_factor)) / float(pixelation_factor);
	
	vec4 c = texture(TEXTURE, grid_uv);
	vec4 output = c;
	output.r = texture(noise, vec2(grid_uv.x + 0.3 * TIME, grid_uv.y + 0.2 * TIME)).r * c.a;
	vec3 p = texture(palette, vec2(i_r, i_b)).rgb;
	
	COLOR.rgb = p * step(0.98, output.r + output.g + output.b);
	COLOR.a = step(0.05, COLOR.r);
	COLOR.rgb = p;
}