shader_type spatial;

render_mode depth_draw_opaque, cull_disabled;

// Texture settings
uniform sampler2D texture_albedo : hint_default_white, repeat_disable;
uniform sampler2D texture_gradient : hint_default_white;
uniform sampler2D texture_noise : hint_default_white;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0);
uniform vec4 transmission : source_color;
uniform float total_height = 1.0;

// Wind settings
uniform vec2 wind_direction = vec2(1, -0.5);
uniform float wind_speed = 1.0;
uniform float wind_strength = 2.0;
uniform float noise_scale = 20.0;

varying float color;
varying float height;

void vertex() {
	height = VERTEX.y;
	
	vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	vec2 uv = (world_pos.xz + VERTEX.yy) / (noise_scale + 1e-2) ;
	vec2 panning_uv = uv + fract(TIME * wind_direction * wind_speed);
	float wind = texture(texture_noise, panning_uv).r * 2.0 - 0.4;
	color = texture(texture_noise, uv).r;
	
	float wind_influence = smoothstep(0, 1, 1.0 - UV.y);
	vec2 wind_offset = -wind_direction * wind_strength * wind_influence * wind;
	world_pos.xz += wind_offset;
	world_pos.y -= wind * wind_influence * wind_strength * 0.45;
	
	vec4 local_pos = inverse(MODEL_MATRIX) * world_pos;
	
	VERTEX = local_pos.xyz;
	//NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	vec4 tex = texture(texture_albedo, UV);
	if (tex.a < alpha_scissor_threshold) {
		discard;
	}
	
	BACKLIGHT = transmission.rgb;
	vec4 gradient = texture(texture_gradient, vec2(height / total_height, 0.0));
	ALBEDO = tex.rbg * gradient.rgb;
}
