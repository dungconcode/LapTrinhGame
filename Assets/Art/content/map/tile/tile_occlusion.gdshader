shader_type canvas_item;

uniform sampler2D overlay_left;
uniform sampler2D overlay_right;
uniform sampler2D overlay_top;
uniform sampler2D overlay_bottom;
uniform float overlay_apply_left = 0.0;
uniform float overlay_apply_right = 0.0;
uniform float overlay_apply_top = 0.0;
uniform float overlay_apply_bottom = 0.0;

void fragment() {
	vec4 baseTexture = vec4(1.0, 1.0, 1.0, 0.0);
	vec4 lo = overlay_apply_left * texture(overlay_left, UV);
	vec4 ro = overlay_apply_right * texture(overlay_right, UV);
	vec4 to = overlay_apply_top * texture(overlay_top, UV);
	vec4 bo = overlay_apply_bottom * texture(overlay_bottom, UV);
	lo = mix(baseTexture, lo, lo.a);
	ro = mix(baseTexture, ro, ro.a);
	to = mix(baseTexture, to, to.a);
	bo = mix(baseTexture, bo, bo.a);
//	COLOR = baseTexture;
	COLOR = vec4(min(min(min(lo.rgb, ro.rgb), to.rgb), bo.rgb), max(max(max(lo.a, ro.a), to.a), bo.a));
	
}