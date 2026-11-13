shader_type particles;
//render_mode disable_velocity;

uniform sampler2D flow;
uniform sampler2D flow_large;
uniform sampler2D scale_texture;
uniform float scale = 1.0;
uniform vec3 wind = vec3(0.0);
uniform float gravity = 9.0;
uniform float spawn_area = 1280.0;


// https://thebookofshaders.com/10/
float random (float n) {
	vec2 st = vec2(TIME, n);
    return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.5453123);
}


void start() {
	CUSTOM.y = 0.0;
	TRANSFORM[3].x = random(float(INDEX)) * spawn_area - spawn_area*0.5;
	TRANSFORM[3].y = EMISSION_TRANSFORM[3].y;
	float rand = random(TRANSFORM[3].x);
	if (rand > 0.9) {
		TRANSFORM[0].x = 1.0 + rand*0.1;
		TRANSFORM[1].y = 1.0 + rand*0.1;
	} else if (rand > 0.8) {
		TRANSFORM[0].x = 0.65 + rand*0.2;
		TRANSFORM[1].y = 0.65 + rand*0.2;
	} else if (rand > 0.65) {
		TRANSFORM[0].x = 0.55 + rand*0.3;
		TRANSFORM[1].y = 0.55 + rand*0.3;
	} else {
		TRANSFORM[0].x = 0.4 + rand*0.2;
		TRANSFORM[1].y = 0.4 + rand*0.2;
	}
	TRANSFORM[0].x *= scale;
	TRANSFORM[1].y *= scale;
	COLOR.a = pow(rand, 0.65);
	TRANSFORM[0].x = clamp(TRANSFORM[0].x, 0.5, 10.0);
	TRANSFORM[1].y = clamp(TRANSFORM[0].x, 0.5, 10.0);
	VELOCITY.y = random(random(float(INDEX))) * 25.0 + gravity;
	VELOCITY.y *= scale;
	VELOCITY.x = 0.0;
}

void process() {
	CUSTOM.y += DELTA / LIFETIME;
	float tv = CUSTOM.y / 1.0;
	
	vec4 f = texture(flow, (vec2(TRANSFORM[3].x, TRANSFORM[3].y)/spawn_area)+TIME*0.01);
	vec4 f_large = texture(flow_large, (vec2(TRANSFORM[3].x, TRANSFORM[3].y)/spawn_area)+TIME*0.01);
	float r = (random(f.r)-0.5);
	float r_large = (random(f_large.r)-0.5);
	VELOCITY += vec3(f.r*2.0, +r_large*0.05, 0.0) + vec3(f.r*3.0, +f_large.g*0.1, 0.0);
	VELOCITY.x = clamp(VELOCITY.x, -10.0, 10.0);
	float size = abs(1.0-TRANSFORM[0].x)*length(wind*0.015);
	VELOCITY += wind * pow((size+1.0) + f_large.r*(0.5 + size*0.5), 3.0);
	float tex_scale = textureLod(scale_texture, vec2(tv, 0.0), 0.0).r;
	TRANSFORM[0].xy *= tex_scale;
	TRANSFORM[1].xy *= tex_scale;
	
	if (TRANSFORM[3].x < spawn_area * -0.5) {
		TRANSFORM[3].x = spawn_area * 0.5;
	}
	if (TRANSFORM[3].x > spawn_area * 0.5) {
		TRANSFORM[3].x = spawn_area * -0.5;
	}
	if (TRANSFORM[3].y > -50.0 + TRANSFORM[0].x*40.0 + f.g*5.0) {
//		TRANSFORM[3].y = 0.0;
		VELOCITY = vec3(0.0);
	}
}

