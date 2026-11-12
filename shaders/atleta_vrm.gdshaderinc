// Sombreamento anime dos personagens do VRoid: o mesmo de atleta.gdshader
// (duas faixas, sombra lilás, sem estourar pro branco com luz forte), lendo a
// textura do VRoid com a transparência dela (cabelo, cílios, olhos).
// Usado por atleta_vrm_recorte.gdshader e atleta_vrm_transparente.gdshader.

uniform vec4 cor : source_color = vec4(1.0);
uniform sampler2D textura : source_color, hint_default_white, filter_linear_mipmap;
uniform float luz_da_sombra : hint_range(0.0, 1.0) = 0.72;
uniform vec4 tom_da_sombra : source_color = vec4(0.86, 0.8, 0.95, 1.0);
uniform float limiar : hint_range(-1.0, 1.0) = 0.05;
uniform float brilho_de_borda : hint_range(0.0, 1.0) = 0.12;
uniform float corte : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 amostra = cor * texture(textura, UV);
	vec3 base = amostra.rgb;
	ALBEDO = base;
	ROUGHNESS = 1.0;
	float frente = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float borda = pow(1.0 - frente, 3.0);
	EMISSION = base * tom_da_sombra.rgb * luz_da_sombra + base * borda * brilho_de_borda;
#ifdef RECORTE
	ALPHA = amostra.a;
	ALPHA_SCISSOR_THRESHOLD = corte;
#else
	ALPHA = amostra.a;
#endif
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float banda = smoothstep(limiar - 0.03, limiar + 0.03, ndl);
	banda *= smoothstep(0.35, 0.65, ATTENUATION);
	vec3 cor_da_luz = LIGHT_COLOR / PI;
	float forca = max(cor_da_luz.r, max(cor_da_luz.g, cor_da_luz.b));
	vec3 tom = cor_da_luz / max(forca, 0.001);
	float quanto = (1.0 - luz_da_sombra * 0.85) * min(forca, 1.6);
	DIFFUSE_LIGHT += tom * banda * quanto;
}
