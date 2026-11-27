shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// ============================================================================
// SHADER ESTILIZADO PARA EL PERSONAJE 3D (ESTILO SUBWAY SURFERS / SIMS)
// Compatible 100% con Godot 4 GL Compatibility (sin halos negros internos).
// Ofrece rampa cel-shading cálida, luz de borde fresca (Fresnel rim) y brillo
// especular calibrado por rugosidad para piel, tela, pelo y zapatillas.
// ============================================================================

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform bool usar_albedo_tex = false;
uniform vec4 albedo_color : source_color = vec4(1.0);

uniform float roughness_val : hint_range(0.04, 1.0) = 0.78;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.0;
uniform float estilizado : hint_range(0.0, 1.0) = 0.34;
uniform float rim_fuerza : hint_range(0.0, 1.0) = 0.24;
uniform vec3 rim_color : source_color = vec3(0.95, 0.98, 1.0);
uniform vec3 emission_color : source_color = vec3(0.0);
uniform float emission_energia = 0.0;

void fragment() {
	vec3 col = albedo_color.rgb;
	if (usar_albedo_tex) {
		col *= texture(albedo_tex, UV).rgb;
	}

	ALBEDO = col;
	ROUGHNESS = roughness_val;
	METALLIC = metallic_val;

	vec3 em = emission_color * emission_energia;
	if (rim_fuerza > 0.001) {
		float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
		em += rim_color * fres * rim_fuerza;
	}
	EMISSION = em;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float wrap = clamp((ndl + 0.22) / 1.22, 0.0, 1.0);
	float lit = mix(wrap, smoothstep(-0.02, 0.52, ndl), estilizado) * ATTENUATION;
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * (lit * 0.48);

	vec3 H = normalize(VIEW + LIGHT);
	float ndh = max(dot(NORMAL, H), 0.0);
	float shininess = mix(84.0, 14.0, ROUGHNESS);
	float spec = pow(ndh, shininess) * (1.0 - ROUGHNESS * 0.88) * (0.20 + 0.65 * METALLIC);
	SPECULAR_LIGHT += LIGHT_COLOR * spec * ATTENUATION * 0.34;
}
