// Rosto de anime desenhado direto no shader: olhos (branco, iris com
// degrade, pupila, dois brilhos), cilio de cima grosso com a pontinha pra
// fora, sobrancelha, nariz discreto e boca. Vai numa "mascara" colada na
// frente da cabeca; onde nao tem traco fica transparente e aparece a pele.
// UV = posicao no rosto em raios da cabeca (x pra esquerda do atleta, y pra cima).
shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_opaque, shadows_disabled;

uniform vec4 cor_da_iris : source_color = vec4(0.55, 0.35, 0.15, 1.0);
uniform vec4 cor_do_cilio : source_color = vec4(0.1, 0.07, 0.08, 1.0);
uniform vec4 cor_da_sobrancelha : source_color = vec4(0.2, 0.12, 0.08, 1.0);
uniform vec4 cor_da_pele : source_color = vec4(0.94, 0.76, 0.61, 1.0);
uniform vec4 cor_da_boca : source_color = vec4(0.45, 0.13, 0.15, 1.0);
// Olho: distancia do centro, altura, meia largura e meia altura.
uniform float olho_x = 0.37;
uniform float olho_y = -0.05;
uniform float olho_largura = 0.19;
uniform float olho_altura = 0.17;
// 1 = aberto, menor = palpebra mais baixa.
uniform float abertura = 1.0;
// Positivo = canto de fora mais alto (bravo); negativo = caido.
uniform float inclinacao = 0.0;
uniform float sobrancelha_grossura = 1.0;
// 0 = serio, 0.4 = neutro, 1 = sorriso aberto.
uniform float sorriso = 0.4;
// Bochecha corada (0 = nada).
uniform float corado = 0.0;

float suave(float d, float aa) {
	// 1 dentro (d < 0), 0 fora, com borda suave.
	return 1.0 - smoothstep(-aa, aa, d);
}

vec2 girar(vec2 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

// Mistura uma cor por cima (com cobertura "m").
void pintar(inout vec4 cor, vec3 nova, float m) {
	cor.rgb = mix(cor.rgb, nova, m);
	cor.a = max(cor.a, m);
}

void fragment() {
	vec2 p = UV;
	float aa = max(fwidth(p.x), 0.002) * 0.9;
	vec4 saida = vec4(cor_da_pele.rgb, 0.0);

	// Bochechas coradas.
	if (corado > 0.0) {
		for (int i = 0; i < 2; i++) {
			float lado = i == 0 ? 1.0 : -1.0;
			vec2 q = (p - vec2(lado * (olho_x + 0.05), olho_y - 0.26)) / vec2(0.15, 0.06);
			float m = (1.0 - smoothstep(0.3, 1.0, length(q))) * corado * 0.45;
			pintar(saida, vec3(0.95, 0.5, 0.5), m);
		}
	}

	for (int i = 0; i < 2; i++) {
		float lado = i == 0 ? 1.0 : -1.0;
		vec2 centro = vec2(lado * olho_x, olho_y);
		// q: coordenada do olho com o canto de fora em +x (espelhado).
		vec2 q = p - centro;
		q.x *= lado;
		q = girar(q, inclinacao * 0.35);
		float w = olho_largura;
		float h = olho_altura;
		float u = q.x / w;

		// Formato: palpebra de cima arqueada, de baixo mais reta.
		float topo = h * abertura * (1.0 - pow(min(abs(u - 0.12) / 1.12, 1.0), 2.4)) - h * 0.15 * (1.0 - abertura);
		float baixo = -h * 0.72 * (1.0 - pow(min(abs(u + 0.05) / 1.05, 1.0), 2.0));
		float dentro = suave(max(q.y - topo, baixo - q.y), aa) * step(abs(u), 1.0);

		// Branco do olho.
		vec3 cor_olho = vec3(1.0, 0.985, 0.97);
		// Sombra da palpebra no alto do branco.
		cor_olho = mix(cor_olho, vec3(0.82, 0.8, 0.88), smoothstep(topo - h * 0.35, topo, q.y) * 0.6);
		// Iris: oval alta, mais escura em cima.
		vec2 iq = (q - vec2(-0.02 * w, -0.08 * h)) / vec2(0.52 * w, 0.98 * h);
		float iris = suave(length(iq) - 1.0, aa / (0.52 * w));
		vec3 escura = cor_da_iris.rgb * 0.35;
		vec3 clara = mix(cor_da_iris.rgb, vec3(1.0), 0.25);
		vec3 cor_iris = mix(escura, cor_da_iris.rgb, smoothstep(0.55, -0.1, iq.y));
		cor_iris = mix(cor_iris, clara, smoothstep(-0.3, -0.85, iq.y) * 0.8);
		// Anel escuro em volta da iris.
		cor_iris = mix(cor_iris, escura * 0.6, smoothstep(0.82, 0.98, length(iq)));
		cor_olho = mix(cor_olho, cor_iris, iris);
		// Pupila.
		vec2 pq = (q - vec2(-0.02 * w, 0.0)) / vec2(0.22 * w, 0.45 * h);
		cor_olho = mix(cor_olho, cor_da_iris.rgb * 0.12, suave(length(pq) - 1.0, aa / (0.22 * w)));
		// Brilhos (no mesmo lado nos dois olhos).
		vec2 sem_espelho = p - centro;
		float brilho1 = suave(length((sem_espelho - vec2(-0.22 * w, 0.3 * h)) / vec2(0.2 * w, 0.24 * h)) - 1.0, aa / (0.2 * w));
		float brilho2 = suave(length((sem_espelho - vec2(0.2 * w, -0.4 * h)) / vec2(0.09 * w, 0.1 * h)) - 1.0, aa / (0.09 * w));
		cor_olho = mix(cor_olho, vec3(1.0), max(brilho1, brilho2 * 0.9));
		pintar(saida, cor_olho, dentro);

		// Cilio de cima: grosso, mais grosso no canto de fora, com uma
		// pontinha que passa do olho.
		float ul = clamp(u, -1.0, 1.0);
		float linha = h * abertura * (1.0 - pow(min(abs(ul - 0.12) / 1.12, 1.0), 2.4)) - h * 0.15 * (1.0 - abertura);
		if (u > 1.0) {
			linha = mix(linha, linha - h * 0.45, clamp((u - 1.0) / 0.32, 0.0, 1.0));
		}
		float grossura = h * (0.2 + 0.24 * smoothstep(-0.6, 0.9, u));
		grossura *= 1.0 - smoothstep(1.0, 1.32, u);
		grossura *= smoothstep(-1.12, -0.85, u);
		float cilio = suave(abs(q.y - (linha + grossura * 0.45)) - grossura * 0.55, aa);
		cilio *= step(-1.12, u) * step(u, 1.32);
		pintar(saida, cor_do_cilio.rgb, cilio);

		// Traço de baixo, fino, so na metade de fora.
		float baixo_l = -h * 0.72 * (1.0 - pow(min(abs(u + 0.05) / 1.05, 1.0), 2.0));
		float traco = suave(abs(q.y - baixo_l) - h * 0.045, aa) * smoothstep(0.15, 0.45, u) * step(u, 0.98);
		pintar(saida, mix(cor_do_cilio.rgb, cor_da_pele.rgb, 0.35), traco);

		// Sobrancelha: arco acima do olho, mais grossa no começo.
		vec2 sq = p - vec2(lado * (olho_x + 0.01), olho_y + h * abertura + 0.1);
		sq.x *= lado;
		sq = girar(sq, -inclinacao * 0.9);
		float su = sq.x / (w * 1.12);
		float arco = 0.035 * (1.0 - su * su) - 0.012 * su;
		float sg = 0.05 * sobrancelha_grossura * (1.15 - 0.55 * smoothstep(-1.0, 1.0, su));
		float sobr = suave(abs(sq.y - arco) - sg * 0.5, aa) * suave(abs(su) - 1.0, aa / w);
		pintar(saida, cor_da_sobrancelha.rgb, sobr);
	}

	// Nariz: só uma sombrinha pequena.
	vec2 nq = (p - vec2(0.03, -0.36)) / vec2(0.035, 0.014);
	pintar(saida, cor_da_pele.rgb * vec3(0.78, 0.66, 0.66), suave(length(nq) - 1.0, aa / 0.014) * 0.85);

	// Boca.
	vec2 bq = p - vec2(0.0, -0.6);
	if (sorriso > 0.7) {
		// Sorriso aberto: forma de "D" deitado.
		float bw = 0.16;
		float bu = bq.x / bw;
		float cima = 0.012 - 0.02 * bu * bu;
		float fundo = cima - 0.11 * sqrt(max(1.0 - bu * bu, 0.0));
		float boca = suave(max(bq.y - cima, fundo - bq.y), aa) * step(abs(bu), 1.0);
		vec3 dentro_boca = mix(cor_da_boca.rgb, vec3(0.92, 0.45, 0.45), smoothstep(fundo + 0.05, fundo + 0.005, bq.y));
		// Dentes em cima.
		dentro_boca = mix(dentro_boca, vec3(1.0), step(cima - 0.022, bq.y) * 0.95);
		pintar(saida, dentro_boca, boca);
		float contorno_boca = suave(abs(bq.y - cima) - 0.006, aa) * step(abs(bu), 1.05);
		pintar(saida, cor_do_cilio.rgb, contorno_boca);
	} else {
		// Linha: reta (sério) ou com as pontas pra cima (neutro).
		float bw = 0.075 + 0.035 * sorriso;
		float bu = bq.x / bw;
		float curva = 0.022 * sorriso * bu * bu;
		float linha_boca = suave(abs(bq.y - curva) - 0.007, aa) * suave(abs(bu) - 1.0, aa / bw);
		pintar(saida, mix(cor_da_boca.rgb, cor_do_cilio.rgb, 0.4), linha_boca);
	}

	ALBEDO = saida.rgb;
	ALPHA = saida.a;
}
