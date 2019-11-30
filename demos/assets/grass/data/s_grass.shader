shader_type spatial;

render_mode depth_draw_opaque, cull_disabled;

// Texture settings
uniform sampler2D texture_albedo : hint_albedo;
uniform sampler2D texture_gradient : hint_albedo;
uniform sampler2D texture_noise : hint_albedo;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0);
uniform vec4 transmission : hint_color;
uniform vec4 secondary_color : hint_color;
uniform float secondary_attenuation = 0.2;
uniform float grass_height = 1.0;

// Wind settings
uniform vec2 wind_direction = vec2(1, -0.5);
uniform float wind_speed = 1.0;
uniform float wind_strength = 2.0;
uniform float noise_scale = 20.0;

varying float color;
varying float height;

void vertex() {
	height = VERTEX.y;
	float influence = smoothstep(0, 1, height / 2.0);
	vec4 world_pos = WORLD_MATRIX * vec4(VERTEX, 1.0);
	vec2 uv = world_pos.xz / (noise_scale + 1e-2);
	vec2 panning_uv = uv + fract(TIME * wind_direction * wind_speed);
	float wind = texture(texture_noise, panning_uv).r * 2.0 - 0.4;
	color = texture(texture_noise, uv).r;
	
	vec2 wind_offset = -wind_direction * wind_strength * influence * wind;
	world_pos.xz += wind_offset;
	world_pos.y -= wind * influence * smoothstep(0.0, height, wind_strength);
	vec4 local_pos = inverse(WORLD_MATRIX) * world_pos;
	local_pos.x += influence * cos(TIME * 1.0) / 8.0;
	local_pos.z += influence * sin(TIME * 1.5) / 8.0;
	
	VERTEX = local_pos.xyz;
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	vec4 tex = texture(texture_albedo, UV);
	if (tex.a < alpha_scissor_threshold) {
		discard;
	}
	
	TRANSMISSION = transmission.rgb;
	vec4 gradient = texture(texture_gradient, vec2(height / grass_height, 0.0));
	float secondary_weight = smoothstep(0.0, 1.0, color - secondary_attenuation);
	ALBEDO = tex.rbg * gradient.rgb;
	ALBEDO = mix(ALBEDO, secondary_color.rgb, secondary_weight);
}