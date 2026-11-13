shader_type canvas_item;

uniform sampler2D palette;
uniform float speed : hint_range(0, 100) = 50.0;
uniform float fade : hint_range(0, 100) = 50.0;
uniform sampler2D noise : repeat_enable;
uniform vec2 direction = vec2(1.0, 0.0);

varying flat vec4 modulate;
void vertex() {
    modulate = COLOR;
}

void fragment() {
	vec2 uv = UV;
	vec2 noiseuv = UV;
	
	// Pixellate UV
	uv /= TEXTURE_PIXEL_SIZE;
	uv = floor(uv);
	uv *= TEXTURE_PIXEL_SIZE;
	
	// Palette swap
	vec4 c = texture(palette, uv);

	float real_speed = speed * 10.0;
	
	// Layer 1
	uv.x -= (TIME * 0.02) * real_speed * direction.x * TEXTURE_PIXEL_SIZE.x;
	uv.y += (TIME * 0.02) * real_speed * -direction.y * TEXTURE_PIXEL_SIZE.y;
	c.a = texture(TEXTURE, uv).a * 1.2;
	
	// Layer 2
	uv.x -= (TIME * 0.03) * real_speed * direction.x * TEXTURE_PIXEL_SIZE.x + 0.5;
	uv.y += (TIME * 0.03) * real_speed * -direction.y * TEXTURE_PIXEL_SIZE.y + 0.5;
	c.a -= texture(TEXTURE, uv).a * 0.60;
	
	// Layer 1

	// Fades at the edges
	c.a *= smoothstep(fade/100.0*0.0, fade/100.0 - 0.1, UV.y);
	c.a *= smoothstep(fade/100.0*0.0, fade/100.0 - 0.1, 1.0-UV.y);
	c.a *= smoothstep(fade/100.0*0.0, fade/100.0 - 0.4, UV.x);
	c.a *= smoothstep(fade/100.0*0.0, fade/100.0 - 0.4, 1.0-UV.x);
	
	// Return the new color
	COLOR = c*modulate;
}