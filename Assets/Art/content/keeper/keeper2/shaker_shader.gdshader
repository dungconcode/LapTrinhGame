shader_type canvas_item;

uniform sampler2D noise;

void fragment() {
	// Get base texture
	vec4 baseTexture = texture(TEXTURE, UV);
	vec4 noiseval = texture(noise, UV);
	vec4 output = noiseval
	COLOR = output;

}