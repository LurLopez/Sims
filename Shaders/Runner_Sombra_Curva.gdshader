shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

// Sombra de contacto curva (sigue la curvatura del mundo de Runner_Curvo)

uniform sampler2D sombra_tex : source_color, filter_linear_mipmap;
uniform float opacidad : hint_range(0.0, 1.0) = 0.78;
uniform float curva_x = 0.0;
uniform float curva_y = 0.0022;

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float d = max(0.0, -wp.z - 4.0);
	float d2 = d * d;
	wp += vec3(curva_x * d2, -curva_y * d2, 0.0);
	VERTEX = (inverse(MODEL_MATRIX) * vec4(wp, 1.0)).xyz;
}

void fragment() {
	vec4 s = texture(sombra_tex, UV);
	ALBEDO = s.rgb;
	ALPHA = s.a * opacidad;
}
