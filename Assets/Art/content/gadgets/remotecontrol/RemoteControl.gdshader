shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture,filter_nearest, repeat_disable;

uniform float resolution = 480;
uniform float on_amount = 0.5;
uniform bool active;

float onval(vec2 uv){
	uv = (uv - vec2(0.5,0.5)) * 2.0;
	
	if (on_amount == 0.0)
		return 0.0;
		
	float y = (on_amount)/abs(uv.x);
	if (y <= abs(uv.y)){
		return 0.0;
	}
	
	return 1.0;
}

highp vec2 floor_c(highp vec2 v){
	return vec2(v.x - mod(v.x,1), v.y -mod(v.y,1));
}
	

void fragment() {
	highp vec2 suv = SCREEN_UV;
	if(active){
		highp vec2 factor = vec2(resolution, resolution* SCREEN_PIXEL_SIZE.x/SCREEN_PIXEL_SIZE.y);
		suv = floor(suv *factor) / factor;
	}
	vec4 tex = textureLod (SCREEN_TEXTURE, suv,0.0);

	float v = onval(suv);
	COLOR = tex * vec4(v,v,v,1.0);
}