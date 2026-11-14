// Bola de vôlei desenhada por código (sem textura): 18 gomos, em 6 grupos de
// 3 faixas, um grupo em cada "lado" da bola (como um cubo inflado). Faixas do
// meio e de fora alternam amarelo e azul, com costura escura entre elas.
// Luz em faixas (cel-shaded), igual ao resto do jogo.
shader_type spatial;
render_mode diffuse_toon, specular_toon;

uniform vec4 amarelo : source_color = vec4(1.0, 0.8, 0.1, 1.0);
uniform vec4 azul : source_color = vec4(0.08, 0.3, 0.78, 1.0);
uniform vec4 costura : source_color = vec4(0.1, 0.1, 0.14, 1.0);
// Largura da costura (na conta do gomo, de 0 a 1).
uniform float largura_da_costura : hint_range(0.0, 0.2) = 0.05;
uniform float brilho_de_borda : hint_range(0.0, 1.0) = 0.25;

varying vec3 ponto;

void vertex() {
	ponto = VERTEX;
}

void fragment() {
	vec3 q = normalize(ponto);
	vec3 a = abs(q);
	// Em que "lado" o ponto está, onde ele fica na faixa (u, de -1 a 1) e quão
	// perto está da borda do grupo (0 = na borda).
	float u;
	float borda;
	int lado;
	if (a.x >= a.y && a.x >= a.z) {
		u = q.y / a.x;
		borda = 1.0 - max(a.y, a.z) / a.x;
		lado = 0;
	} else if (a.y >= a.z) {
		u = q.z / a.y;
		borda = 1.0 - max(a.x, a.z) / a.y;
		lado = 1;
	} else {
		u = q.x / a.z;
		borda = 1.0 - max(a.x, a.y) / a.z;
		lado = 2;
	}
	bool meio = abs(u) < 1.0 / 3.0;
	vec3 cor;
	if (lado == 1) {
		cor = meio ? azul.rgb : amarelo.rgb;
	} else {
		cor = meio ? amarelo.rgb : azul.rgb;
	}
	float ate_a_costura = min(abs(abs(u) - 1.0 / 3.0), borda * 1.4);
	float suave = fwidth(ate_a_costura) + 0.001;
	float linha = 1.0 - smoothstep(largura_da_costura * 0.5, largura_da_costura * 0.5 + suave, ate_a_costura);
	ALBEDO = mix(cor, costura.rgb, linha * 0.9);
	ROUGHNESS = 0.6;
	SPECULAR = 0.3;
	RIM = brilho_de_borda;
	RIM_TINT = 0.5;
}
