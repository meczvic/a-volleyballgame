// Sombreamento dos atletas no estilo anime: duas faixas (luz e sombra) com
// a sombra levemente arroxeada, sem estourar pro branco quando a luz da cena
// e forte. A sombra vem de "luz_da_sombra" (emissao), entao o atleta fica
// igual em qualquer estadio; a luz de cada lampada soma ate um limite.
shader_type spatial;
render_mode ambient_light_disabled;

uniform vec4 cor : source_color = vec4(1.0);
uniform sampler2D textura : source_color, hint_default_white;
// Quanto da cor aparece no lado da sombra (0 = preto, 1 = sem sombra).
uniform float luz_da_sombra : hint_range(0.0, 1.0) = 0.72;
// Tom da sombra (multiplica a cor). Um lilas leve, como nos desenhos.
uniform vec4 tom_da_sombra : source_color = vec4(0.86, 0.8, 0.95, 1.0);
// Onde a luz vira sombra (produto escalar normal x luz).
uniform float limiar : hint_range(-1.0, 1.0) = 0.05;
// Brilho na borda do objeto, de frente pra camera.
uniform float brilho_de_borda : hint_range(0.0, 1.0) = 0.12;
// Faixa de brilho (cabelo): intensidade e onde fica.
uniform float faixa_de_brilho : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec3 base = cor.rgb * texture(textura, UV).rgb;
	ALBEDO = base;
	ROUGHNESS = 1.0;
	float frente = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float borda = pow(1.0 - frente, 3.0);
	EMISSION = base * tom_da_sombra.rgb * luz_da_sombra + base * borda * brilho_de_borda;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float banda = smoothstep(limiar - 0.03, limiar + 0.03, ndl);
	banda *= smoothstep(0.35, 0.65, ATTENUATION);
	vec3 cor_da_luz = LIGHT_COLOR / PI;
	float forca = max(cor_da_luz.r, max(cor_da_luz.g, cor_da_luz.b));
	vec3 tom = cor_da_luz / max(forca, 0.001);
	// O lado iluminado chega perto da cor pura (1 - luz da sombra),
	// e cada lampada a mais so soma ate o dobro disso.
	float quanto = (1.0 - luz_da_sombra * 0.85) * min(forca, 1.6);
	DIFFUSE_LIGHT += tom * banda * quanto;
	if (faixa_de_brilho > 0.0) {
		vec3 meio = normalize(LIGHT + VIEW);
		float b = smoothstep(0.86, 0.9, dot(NORMAL, meio));
		SPECULAR_LIGHT += tom * b * faixa_de_brilho * banda;
	}
}
