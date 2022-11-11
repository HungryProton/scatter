shader_type spatial;
render_mode depth_draw_always;


uniform float wave_1_scale = 1.0;
uniform vec2 wave_1_speed = vec2(1.0);
uniform float wave_1_stretch = 1.0;
uniform float wave_1_height = 1.0;

uniform float wave_2_scale = 1.0;
uniform vec2 wave_2_speed = vec2(1.0);
uniform float wave_2_stretch = 1.0;
uniform float wave_2_height = 1.0;

uniform float wave_offset = 0.0;

uniform sampler2D wave_1_height_map;
uniform sampler2D wave_1_normal_map;

uniform sampler2D wave_2_height_map;
uniform sampler2D wave_2_normal_map;
uniform float wave_2_normal_strength = 0.1;

uniform sampler2D water_highlight_map;

uniform vec4 foam_color : source_color;
uniform sampler2D foam_noise;
uniform float foam_noise_tiling = 8.0;
uniform float foam_noise_multiplier = 8.0;
uniform float foam_speed = 0.2;
uniform float foam_ramp : hint_range(0.5, 5.0) = 0.2;
uniform float foam_threshold = 0.2;

uniform sampler2D refraction_map : hint_normal;
uniform float refraction = 0.0;
uniform float refraction_map_scale = 1.0;
uniform float refraction_tolerance : hint_range(-1.0, 1.0) = 0.1;
uniform float refraction_speed = 0.25;

uniform float depth_multiplier = 0.1;
uniform float depth_ramp = 1.0;

uniform sampler2D depth_gradient: hint_default_white;
uniform sampler2D surface_gradient;
uniform float surface_gradient_scale;
uniform float surface_gradient_offset;

uniform float sss_strength = 0.2;

uniform float roughness : hint_range(0.0, 1.0) = 0.285;
uniform float specular : hint_range(0.0, 1.0) = 0.285;
uniform float specular_mutliplier = 1.0;
uniform float specular_width :hint_range(0.0, 1.0) = 0.5;

uniform float glare = 3;
uniform float glare_ramp : hint_range(0.0, 1.0) = 0.5;
uniform float glare_width :hint_range(0.0, 300.0) = 150;

varying float water_height;
varying float fake_sss;


void get_world_uv(in vec2 uv, in mat4 world_matrix, out vec2 uv1, out vec2 uv2) {
	uv = (vec4(uv.x, uv.y, uv.y, 1.0) + world_matrix[3] * 0.25).xz;
	uv1 = uv * wave_1_scale + TIME * wave_1_speed * 0.01;
	uv2 = uv1 * wave_2_scale + TIME * wave_2_speed * 0.01;
}


float get_depth(vec2 uv, sampler2D depth_texture, mat4 inv_projection_matrix) {
	float depth = texture(depth_texture, uv).x;
	vec3 ndc = vec3(uv, depth) * 2.0 - 1.0;
	vec4 view = inv_projection_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;
	
	float lineardepth = -view.z;
	return lineardepth;
}


void vertex() {
	vec2 uv1;
	vec2 uv2;
	get_world_uv(UV, MODEL_MATRIX, uv1, uv2);
	
	vec2 normal_1 = ( texture(wave_1_normal_map, uv1).xy - vec2(0.5, 0.5) ) * wave_1_height;
	vec2 normal_2 = ( texture(wave_2_normal_map, uv2).xy - vec2(0.5, 0.5) ) * wave_2_height;
	
	vec3 wave_1 = vec3(-normal_1.x * wave_1_stretch, (pow( texture(wave_1_height_map, uv1).x, 0.4545) - 0.5) * wave_1_height, normal_1.y * wave_1_stretch);
	vec3 wave_2 = vec3(-normal_2.x * wave_2_stretch, (pow( texture(wave_2_height_map, uv2).x, 0.4545) - 0.5) * wave_2_height, normal_2.y * wave_2_stretch);
	
	VERTEX += wave_1 + wave_2 + wave_offset;
	
	water_height = VERTEX.y * surface_gradient_scale + surface_gradient_offset;
	fake_sss = (wave_1.x + wave_1.z) * 1.0 + (wave_2.x + wave_2.z) * 0.1;
}


void fragment() {
	// NORMAL MAP
	vec2 uv1;
	vec2 uv2;
	get_world_uv(UV, MODEL_MATRIX, uv1, uv2);
	
	vec3 normal_1 = texture(wave_1_normal_map, uv1).xyz;
	vec3 normal_2 = texture(wave_2_normal_map, uv2).xyz * wave_2_normal_strength;

	// LINEAR DEPTH
	vec2 ref_ofs = SCREEN_UV - NORMAL.xy * texture(refraction_map, uv2 * refraction_map_scale).r * refraction;
	float linear_depth = get_depth(ref_ofs, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
	if (linear_depth < -(VERTEX.z + refraction_tolerance)) {
		linear_depth = get_depth(SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX);
	}
	
	// FOAM + REFRACTION
	vec3 height_gerstner = texture(wave_1_height_map, uv1).xyz;
	vec3 height_gerstner_2 = texture(wave_2_height_map, uv2).xyz;
	float height = (height_gerstner.y * 0.5) + (height_gerstner_2.y * 0.02);
	height = pow(height, foam_ramp);
	
	vec3 foam = vec3(0.0);
	float noise = texture(foam_noise, uv2 * foam_noise_tiling).r - 0.5;
	noise *= foam_noise_multiplier;
	
	float depth = clamp(pow((linear_depth + VERTEX.z) * depth_multiplier, depth_ramp), 0.0, 1.0);

	if ((height + noise) > foam_threshold || (depth + noise) < foam_threshold) {
		foam = foam_color.rgb;
	}
	
	// COLOR
	vec2 surface_gradient_uv = vec2(1.0 - water_height, 0.0);
	vec3 surface_color = texture(surface_gradient, surface_gradient_uv).rgb;
	vec3 depth_color = texture(depth_gradient, vec2(clamp(depth, 0.0, 1.0), 0.0)).xyz;
	
	ALBEDO = clamp(mix(surface_color, depth_color, 0.35) + foam, 0.0, 1.0);
	NORMAL = normal_1 + normal_2;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	METALLIC = 0.0;
}


void light() {
	// Highlights
	vec2 uv = (vec4(UV.x, UV.y, UV.y, 1.0) + MODEL_MATRIX[3] * 0.25).xz;
	vec2 uv1 = uv + TIME * 0.051031;
	vec2 uv2 = uv1 + TIME * -0.047854;
	
	float water_highlight_mask_1 = texture(water_highlight_map, fract( uv1 ) ).x;
	float water_highlight_mask_2 = texture(water_highlight_map, fract( uv2) * 2.0 ).x;
	float highlight = smoothstep(glare_ramp, 1.0, water_highlight_mask_1 + water_highlight_mask_2);
	
	// LAMBER DIFFUSE LIGHTING
	float lambert = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float spec = clamp( step(1.0 - specular_width, pow( dot( reflect(LIGHT, NORMAL), -VIEW), 300.0)), 0.0, 1.0) * specular_mutliplier;
	float spec_glare = clamp( pow( dot( reflect(LIGHT, NORMAL), -VIEW), 300.0 - glare_width), 0.0, 1.0) * highlight * glare;
		
	DIFFUSE_LIGHT += (LIGHT_COLOR * ALBEDO * ATTENUATION / PI) * lambert;
	if (ATTENUATION > 0.5) {
		DIFFUSE_LIGHT += LIGHT_COLOR * (ATTENUATION / PI) * (spec + clamp(spec_glare, 0.0, 1.0));
	}
}