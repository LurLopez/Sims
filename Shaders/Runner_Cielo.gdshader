shader_type sky;

// ============================================================================
// CIELO ESTILIZADO SUBWAY SURFERS (NUBES PINTADAS, SOL, LUNA Y ESTRELLAS)
// ============================================================================

uniform vec3 cielo_cenit : source_color = vec3(0.08, 0.40, 0.86);
uniform vec3 cielo_medio : source_color = vec3(0.24, 0.66, 0.96);
uniform vec3 cielo_horizonte : source_color = vec3(0.68, 0.91, 1.0);
uniform vec3 suelo_color : source_color = vec3(0.55, 0.74, 0.88);
uniform vec3 nube_luz : source_color = vec3(1.0, 0.99, 0.96);
uniform vec3 nube_sombra : source_color = vec3(0.72, 0.85, 0.98);
uniform vec3 sol_color : source_color = vec3(1.0, 0.95, 0.75);
uniform vec3 sol_dir = vec3(-0.32, 0.36, -0.88);
uniform float noche_factor : hint_range(0.0, 1.0) = 0.0;
uniform float tiempo = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.52;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.07 + vec2(17.1, 9.2);
		a *= 0.48;
	}
	return v;
}

// Función de nube cartoon mullida (múltiples pompones con base plana estilizada)
float cloud_puff(vec2 p, vec2 c, float s) {
	vec2 q = (p - c) / s;
	float d = length((q - vec2(0.0, 0.04)) * vec2(1.0, 1.35)) - 0.16;
	d = min(d, length((q - vec2(-0.15, 0.00)) * vec2(1.0, 1.35)) - 0.125);
	d = min(d, length((q - vec2(0.15, 0.00)) * vec2(1.0, 1.35)) - 0.13);
	d = min(d, length((q - vec2(-0.07, 0.09)) * vec2(1.0, 1.25)) - 0.12);
	d = min(d, length((q - vec2(0.08, 0.08)) * vec2(1.0, 1.25)) - 0.11);
	// Base suavemente aplanada
	d = max(d, -q.y - 0.055);
	return d;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float h = dir.y;

	// Gradiente vibrante de 3 bandas (cielo azul intenso arriba -> turquesa luminoso en el horizonte)
	vec3 col;
	if (h >= 0.0) {
		float t1 = smoothstep(0.0, 0.16, h);
		float t2 = smoothstep(0.12, 0.42, h);
		col = mix(cielo_horizonte, cielo_medio, t1);
		col = mix(col, cielo_cenit, t2);
	} else {
		col = mix(cielo_horizonte, suelo_color, smoothstep(0.0, -0.25, h));
	}

	// Disco solar cálido + halo atmosférico en la zona superior del cielo
	vec3 sdir = normalize(vec3(-0.14, 0.30, -0.94));
	float sdot = max(dot(dir, sdir), 0.0);
	float halo = pow(sdot, 9.0) * 0.34 + pow(sdot, 42.0) * 0.55;
	float disco = smoothstep(0.9970, 0.9986, sdot);
	col += sol_color * (halo + disco * 1.4) * (1.0 - noche_factor);

	// Estrellas brillantes y luna creciente claramente visibles en modo nocturno
	if (noche_factor > 0.05 && h > 0.03 && dir.z < 0.0) {
		// Luna creciente dorada en el cielo nocturno frontal (visible entre edificios!)
		vec3 mdir = normalize(vec3(0.11, 0.27, -0.955));
		float mdot = dot(dir, mdir);
		float moon = smoothstep(0.9978, 0.9986, mdot);
		vec3 mcut = normalize(mdir + vec3(0.024, 0.014, 0.0));
		float cut = smoothstep(0.9976, 0.9984, dot(dir, mcut));
		float crescent = max(0.0, moon - cut * 0.98);
		float mhalo = pow(max(mdot, 0.0), 34.0) * 0.36;

		vec2 suv = vec2(dir.x, dir.y) * 58.0;
		vec2 cell = floor(suv);
		vec2 f = fract(suv) - 0.5;
		float rnd = hash21(cell);
		if (rnd > 0.91) {
			float dist = length(f);
			float twinkle = 0.65 + 0.35 * sin(tiempo * 3.2 + rnd * 60.0);
			float star = smoothstep(0.24, 0.02, dist) * twinkle * smoothstep(0.04, 0.14, h) * (1.0 - moon);
			col += vec3(0.95, 0.98, 1.0) * star * 1.50 * noche_factor;
		}
		col += vec3(1.0, 0.96, 0.80) * (crescent * 1.85 + mhalo) * noche_factor;
	}

	// Nubes cartoon estilizadas estilo Subway Surfers (mullidas, limpias, con sombra inferior azulada)
	if (h > 0.02 && dir.z < -0.2) {
		vec2 sp = vec2(dir.x / max(0.35, -dir.z), dir.y / max(0.35, -dir.z));
		float drift = mod(tiempo * 0.010, 1.6);
		float d1 = cloud_puff(sp, vec2(mod(-0.18 + drift + 0.8, 1.6) - 0.8, 0.24), 0.72);
		float d2 = cloud_puff(sp, vec2(mod(0.22 + drift * 0.7 + 0.8, 1.6) - 0.8, 0.16), 0.56);
		float d3 = cloud_puff(sp, vec2(mod(-0.04 + drift * 0.5 + 0.8, 1.6) - 0.8, 0.35), 0.60);
		float dc = min(d1, min(d2, d3));
		float cmask = smoothstep(0.015, -0.012, dc);
		// Sombra suave en la barriga de cada nube
		float d_up = min(
			cloud_puff(sp + vec2(0.0, 0.032), vec2(mod(-0.18 + drift + 0.8, 1.6) - 0.8, 0.24), 0.72),
			min(
				cloud_puff(sp + vec2(0.0, 0.032), vec2(mod(0.22 + drift * 0.7 + 0.8, 1.6) - 0.8, 0.16), 0.56),
				cloud_puff(sp + vec2(0.0, 0.032), vec2(mod(-0.04 + drift * 0.5 + 0.8, 1.6) - 0.8, 0.35), 0.60)
			)
		);
		float belly = smoothstep(-0.01, 0.035, d_up - dc);
		vec3 ccol = mix(nube_luz, nube_sombra, (1.0 - belly) * 0.52);
		col = mix(col, ccol, cmask * mix(0.94, 0.24, noche_factor));
	}

	COLOR = col;
}
