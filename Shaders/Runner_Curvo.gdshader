shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// ============================================================================
// SHADER ESTILIZADO + CURVATURA DE HORIZONTE (ESTILO SUBWAY SURFERS)
// Compatible 100% con Godot 4 GL Compatibility (OpenGL 3.3 / GLES3 Android)
// ============================================================================

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool usar_albedo_tex = false;
uniform vec4 albedo_color : source_color = vec4(1.0);

uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool usar_normal_tex = false;
uniform float normal_escala : hint_range(0.0, 2.5) = 0.85;

uniform sampler2D emission_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool usar_emission_tex = false;
uniform vec3 emission_color : source_color = vec3(1.0);
uniform float emission_energia_dia = 0.0;
uniform float emission_energia_noche = 0.0;

uniform vec2 uv_escala = vec2(1.0, 1.0);
uniform vec2 uv_desp = vec2(0.0, 0.0);

uniform float roughness_val : hint_range(0.04, 1.0) = 0.72;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.04;
uniform float estilizado : hint_range(0.0, 1.0) = 0.35;
uniform float rim_fuerza : hint_range(0.0, 1.0) = 0.12;
uniform vec3 rim_color : source_color = vec3(1.0, 0.96, 0.86);
uniform float ao_suelo : hint_range(0.0, 0.65) = 0.0;

// Parámetros dinámicos sincronizados por Runner_Mundo
uniform float curva_x = 0.0;
uniform float curva_y = 0.0022;
uniform float noche_factor = 0.0;

varying float v_world_y;

void vertex() {
	UV = UV * uv_escala + uv_desp;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_y = wp.y;
	float d = max(0.0, -wp.z - 4.0);
	float d2 = d * d;
	vec3 bend_w = vec3(curva_x * d2, -curva_y * d2, 0.0);
	wp += bend_w;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(wp, 1.0)).xyz;
}

void fragment() {
	vec3 col = albedo_color.rgb;
	if (usar_albedo_tex) {
		col *= texture(albedo_tex, UV).rgb;
	}

	// Sutil oclusión ambiental cerca del suelo (asienta trenes, muros y edificios)
	if (ao_suelo > 0.001) {
		float h_ao = clamp(v_world_y / 1.35, 0.0, 1.0);
		col *= mix(1.0 - ao_suelo, 1.0, smoothstep(0.0, 1.0, h_ao));
	}

	ALBEDO = col;
	ROUGHNESS = roughness_val;
	METALLIC = metallic_val;

	if (usar_normal_tex) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
		NORMAL_MAP_DEPTH = normal_escala;
	}

	// Emisión (ventanas nocturnas, faros, flechas de rampa, farolas)
	float em_e = mix(emission_energia_dia, emission_energia_noche, noche_factor);
	vec3 em_total = vec3(0.0);
	if (em_e > 0.001) {
		vec3 em_sample = usar_emission_tex ? texture(emission_tex, UV).rgb : vec3(1.0);
		em_total += em_sample * emission_color * em_e;
	}

	// Fresnel rim suave para siluetas nítidas tipo Subway Surfers
	if (rim_fuerza > 0.001) {
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.4);
		vec3 rc = mix(rim_color, vec3(0.45, 0.62, 0.95), noche_factor);
		em_total += rc * fres * rim_fuerza * mix(0.85, 0.32, noche_factor);
	}

	EMISSION = em_total;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float wrap = clamp((ndl + 0.16) / 1.16, 0.0, 1.0);
	float lit = mix(wrap, smoothstep(0.02, 0.48, ndl), estilizado) * ATTENUATION;
	// Luz direccional cálida con contraste Subway Surfers (sin quemar blancos)
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * (lit * 0.46);

	vec3 H = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, H), 0.0);
	float shininess = mix(96.0, 16.0, ROUGHNESS);
	float spec = pow(ndh, shininess) * (1.0 - ROUGHNESS * 0.85) * (0.28 + 0.72 * METALLIC);
	SPECULAR_LIGHT += LIGHT_COLOR * spec * ATTENUATION * 0.44;
}
