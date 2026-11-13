shader_type particles;

uniform float emission_sphere_radius;
uniform float lifetime_randomness;
uniform vec3 direction;
uniform float spread;
uniform float scale;
uniform float air_drag;
uniform float mass = 0.1;
uniform float mass_random = 0.1;
uniform float scale_min = 0.1;
uniform float scale_max = 0.15;
uniform float initial_linear_velocity;
uniform float initial_linear_velocity_random;
uniform vec4 color_value : source_color;
uniform vec3 scale_speed_mod = vec3(0.0, 1.0, 0.0);
uniform float scale_speed_mod_min = 0.3;
uniform float scale_speed_mod_max = 4.0;
uniform sampler2D color_ramp;
uniform vec3 gravity;

struct DisplayParameters {
	vec3 scale;
	};

float rand_from_seed(inout uint seed) {
	int k;
	int s = int(seed);
	if (s == 0)
	s = 305420679;
	k = s / 127773;
	s = 16807 * (s - k * 127773) - 2836 * k;
	if (s < 0)
		s += 2147483647;
	seed = uint(s);
	return float(seed % uint(65536)) / 65535.0;
}

float rand_from_seed_m1_p1(inout uint seed) {
	return rand_from_seed(seed) * 2.0 - 1.0;
}

uint hash(uint x) {
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = (x >> uint(16)) ^ x;
	return x;
}

void calculate_initial_display_params(inout DisplayParameters params,inout uint alt_seed){
	float pi = 3.14159;
	float degree_to_rad = pi / 180.0;
   params.scale = vec3(mix(scale_min, scale_max, rand_from_seed(alt_seed)));
   params.scale = sign(params.scale) * max(abs(params.scale), 0.001);
}

void start() {
	uint base_number = NUMBER;
	uint alt_seed = hash(base_number + uint(1) + RANDOM_SEED);
	DisplayParameters params;
	calculate_initial_display_params(params, alt_seed);
	float scale_rand = rand_from_seed(alt_seed);
	float mass_rand = rand_from_seed(alt_seed);
	float degree_to_rad = PI / 180.0;
	bool restart = false;
	float tv = 0.0;
	uint alt_restart_seed = hash(base_number + uint(301184) + RANDOM_SEED);
	float spread_rad = spread * degree_to_rad;
	{
		float angle1_rad = rand_from_seed_m1_p1(alt_restart_seed) * spread_rad;
		angle1_rad += direction.x != 0.0 ? atan(direction.y, direction.x) : sign(direction.y) * (PI / 2.0);
		vec3 rot = vec3(cos(angle1_rad), sin(angle1_rad), 0.0);
		VELOCITY = rot * initial_linear_velocity * pow(mix(1.0, rand_from_seed(alt_restart_seed), initial_linear_velocity_random), 6.0);
	}
	CUSTOM.x = 0.0;
	CUSTOM.y = 0.0;
	CUSTOM.w = pow(1.0 - lifetime_randomness * rand_from_seed(alt_restart_seed), 2.0);
	float s = rand_from_seed(alt_restart_seed) * 2.0 - 1.0;
	float t = rand_from_seed(alt_restart_seed) * 2.0 * PI;
	float radius = emission_sphere_radius * sqrt(1.0 - s * s);
	TRANSFORM[3].xyz = vec3(radius * cos(t), radius * sin(t), emission_sphere_radius * s);
	VELOCITY = (EMISSION_TRANSFORM * vec4(VELOCITY, 0.0)).xyz;
	TRANSFORM = EMISSION_TRANSFORM * TRANSFORM;
	VELOCITY.z = 0.0;
	TRANSFORM[3].z = 0.0;
}

void process() {
	CUSTOM.y += DELTA / LIFETIME;
	float tv = CUSTOM.y / CUSTOM.w;
	vec3 force = gravity;
	vec3 pos = TRANSFORM[3].xyz;
	pos.z = 0.0;
	uint base_number = NUMBER;
	uint alt_seed = hash(base_number + uint(1) + RANDOM_SEED);
	
	DisplayParameters params;
	calculate_initial_display_params(params, alt_seed);
	
	// apply attractor forces
	VELOCITY += force * DELTA;
	if (air_drag > 0.0) {
		vec3 dir = normalize(VELOCITY);
		float v = length(VELOCITY);
		float drag_force = air_drag * v * v;
		float drag_acceleration = drag_force * mass * mix(1.0, 0.0, pow(mass_random, 1.3));
		float damp = drag_acceleration * DELTA;
		v -= damp;
		if (v < 0.0) {
			VELOCITY = vec3(0.0);
		} else {
			VELOCITY = dir * v;
		}
	}
	COLOR = textureLod(color_ramp, vec2(tv, 0.0), 0.0) * color_value;
	
	if (length(VELOCITY) > 0.0) {
		TRANSFORM[1].xyz = normalize(VELOCITY);
	} else {
		TRANSFORM[1].xyz = normalize(TRANSFORM[1].xyz);
	}
	TRANSFORM[0].xyz = normalize(cross(TRANSFORM[1].xyz, TRANSFORM[2].xyz));
	TRANSFORM[2] = vec4(0.0, 0.0, 1.0, 0.0);
	float speed_mod = clamp(length(VELOCITY)*0.01, scale_speed_mod_min, scale_speed_mod_max);
	TRANSFORM[0].xyz *= sign(params.scale.x) * max(abs(params.scale.x) * mix(1.0, speed_mod, scale_speed_mod.x), 0.001);
	TRANSFORM[1].xyz *= sign(params.scale.y) * max(abs(params.scale.y) * mix(1.0, speed_mod, scale_speed_mod.y), 0.001);
	TRANSFORM[2].xyz *= sign(params.scale.z) * max(abs(params.scale.z) * mix(1.0, speed_mod, scale_speed_mod.z), 0.001);
	VELOCITY.z = 0.0;
	TRANSFORM[3].z = 0.0;
	if (CUSTOM.y > CUSTOM.w) {
		ACTIVE = false;
	}
}

