shader_type particles;

uniform sampler2D flow : repeat_enable;
uniform float width = 1280.0;
uniform float height = 250.0;

float rand_from_seed(in uint seed) {
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

uint hash(uint x) {
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = ((x >> uint(16)) ^ x) * uint(73244475);
  x = (x >> uint(16)) ^ x;
  return x;
}

void start() {
	uint alt_seed1 = hash(NUMBER + uint(27) + RANDOM_SEED);
	uint alt_seed2 = hash(NUMBER + uint(43) + RANDOM_SEED);
	uint alt_seed3 = hash(NUMBER + uint(111) + RANDOM_SEED);
	vec2 position = vec2((rand_from_seed(alt_seed1) - 0.5) * width, (rand_from_seed(alt_seed2) - 0.5) * height);
	CUSTOM.w = 1.0;
	CUSTOM.y = 0.0;
	COLOR.a = 1.0;
	TRANSFORM[0].x = 1.0;
	TRANSFORM[1].y = 1.0;
	TRANSFORM[3].xy = position;
	VELOCITY.x = 0.0;
	VELOCITY.y = -10.0 * rand_from_seed(alt_seed2) - 2.0;
}

void process() {
	uint alt_seed1 = hash(NUMBER + uint(23) + RANDOM_SEED);
	uint alt_seed2 = hash(NUMBER + uint(57) + RANDOM_SEED);
	
	float n = TIME + float(NUMBER);
	float wind1 = sin(n * 0.34) + sin(n * 3.71) + sin(n * 0.00);
	float wind2 = sin(n * 0.72) + sin(n * 2.38) + sin(n * 0.27);

	vec2 uv = vec2(rand_from_seed(alt_seed1), rand_from_seed(alt_seed2));
	vec4 flowc = vec4(1.0);
	
	VELOCITY.x = (flowc.r - 0.5) * 10.0 + (wind2 - 0.5) * 3.0;
	VELOCITY.y = -(flowc.r - 0.2) * 10.0 - wind1 * 3.0;
	
	CUSTOM.y += DELTA / LIFETIME;
	CUSTOM.y = mix(CUSTOM.y, 1.0, INTERPOLATE_TO_END);
	float lifetime_percent = CUSTOM.y / CUSTOM.w;
	if (CUSTOM.y > CUSTOM.w) {
		ACTIVE = false;
	}
	
	COLOR.a = smoothstep(0.0, 1.0, sin(lifetime_percent*PI));
}