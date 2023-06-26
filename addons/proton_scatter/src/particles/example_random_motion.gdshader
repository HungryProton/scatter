shader_type particles;


uniform mat4 global_transform;


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
	CUSTOM.x = 0.0;
}

void process() {
	uint seed = hash(uint(INDEX) + uint(1) + RANDOM_SEED);
	float random = rand_from_seed(seed);
	float offset = cos(TIME) * random * 0.05;

	TRANSFORM[3].y += offset;
}