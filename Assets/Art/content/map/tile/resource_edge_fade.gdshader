shader_type canvas_item;
//#TODO: CONVERSION, double check
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float top = 0.f;
uniform float right = 0.f;
uniform float bottom = 0.f;
uniform float left = 0.f;
uniform vec2 coord = vec2(0.f);

uniform sampler2D palette;
const float start_r = 0.5 / float(32);
const float start_b = 0.5 / float(12);

void fragment() {
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec2 uv = UV + coord * TEXTURE_PIXEL_SIZE * 4.f;
	vec4 t = texture(TEXTURE, uv);
	
	float mask = 0.f;
	if (UV.y < 0.5) mask += top;
	if (UV.y >= 0.5) mask += bottom;
	if (UV.x < 0.5) mask += left;
	if (UV.x >= 0.5) mask += right;
	mask = clamp(t.a - mask, 0.f, 1.f);
	
	// This is an alternative way to create the mask
	// but it feels too destructive, doesn't let Anne's art show
	//if (UV.y < 0.5) mask += mix(top, 0f, 2f*UV.y);
	//if (UV.y >= 0.5) mask += mix(bottom, 0f, 2f*(1f-UV.y));
	//if (UV.x < 0.5) mask += mix(left, 0f, 2f*UV.x);
	//if (UV.x >= 0.5) mask += mix(right, 0f, 2f*(1f-UV.x));
	//mask = step(0.3, clamp(t.a - mask, 0f, 1f));
	
	vec4 output = texture(palette, vec2(start_r + screen.r, start_b+screen.b));
	COLOR.rgba = output;
	COLOR.a = mask;
	
	// DEBUG
	// COLOR.r = mask;
}