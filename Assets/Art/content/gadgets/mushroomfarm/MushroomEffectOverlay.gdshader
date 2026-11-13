shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

uniform float intensity = 1;

mat4 brightnessMatrix( float brightness )
{
    return mat4( vec4(1, 0, 0, 0),
                 vec4(0, 1, 0, 0),
                 vec4(0, 0, 1, 0),
                 vec4(brightness, brightness, brightness, 1) );
}

mat4 contrastMatrix( float contrast )
{
	float t = ( 1.0 - contrast ) / 2.0;
    
    return mat4( vec4(contrast, 0, 0, 0),
                 vec4(0, contrast, 0, 0),
                 vec4(0, 0, contrast, 0),
                 vec4(t, t, t, 1 ));

}

mat4 saturationMatrix( float saturation )
{
    vec3 luminance = vec3( 0.3086, 0.6094, 0.0820 );
    
    float oneMinusSat = 1.0 - saturation;
    
    vec3 red = vec3( luminance.x * oneMinusSat );
    red+= vec3( saturation, 0, 0 );
    
    vec3 green = vec3( luminance.y * oneMinusSat );
    green += vec3( 0, saturation, 0 );
    
    vec3 blue = vec3( luminance.z * oneMinusSat );
    blue += vec3( 0, 0, saturation );
    
    return mat4( vec4(red,     0),
                 vec4(green,   0),
                 vec4(blue,    0),
                 vec4(0, 0, 0, 1 ));
}

const float brightness = 0.15;
const float contrast = 1.0;
const float saturation = 1.5;

void fragment() {
	vec2 suv = SCREEN_UV;
	
	//disabled wobble for now to avoid dizzyness until we implement something better
	//suv += cos(TIME*vec2(5.0, 7.0) + suv*10.0)*0.0005 * (intensity -1.0); //dont wobble on first mushroom

	vec4 tex = texture(SCREEN_TEXTURE, suv);
	
	float strength = intensity * 0.05;
	COLOR = saturationMatrix( 1.0 + strength * (sin(TIME*0.5)+1.0)) * tex;
}