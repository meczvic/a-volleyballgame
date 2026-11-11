shader_type spatial;
render_mode unshaded;
// Janela inteira num QuadMesh só: o céu do entardecer (rosa em cima, dourado
// embaixo), a silhueta das árvores lá fora e os caixilhos escuros por cima
// (assim a janela não precisa de dezenas de peças). UV de cima pra baixo.

uniform vec3 cima : source_color = vec3(1.0, 0.56, 0.52);
uniform vec3 baixo : source_color = vec3(1.0, 0.84, 0.5);
uniform vec3 arvores : source_color = vec3(0.36, 0.3, 0.2);
uniform vec3 caixilho : source_color = vec3(0.22, 0.15, 0.1);
// Onde as árvores começam (0 = topo, 1 = base) e o deslocamento do desenho.
uniform float linha_das_arvores = 0.72;
uniform float semente = 0.0;
// Vidros por janela e grossura do caixilho (fração da janela).
uniform float colunas = 4.0;
uniform float linhas = 3.0;
uniform float grossura = 0.025;

void fragment() {
	vec3 ceu = mix(cima, baixo, smoothstep(0.0, 1.0, UV.y));
	float copa = linha_das_arvores + 0.06 * sin(UV.x * 18.0 + semente) + 0.03 * sin(UV.x * 47.0 + semente * 2.0);
	float dentro = smoothstep(copa - 0.01, copa + 0.01, UV.y);
	vec3 cor = mix(ceu, arvores, dentro);

	// Caixilhos: borda e divisões entre os vidros.
	vec2 grade = vec2(colunas, linhas);
	vec2 celula = fract(UV * grade);
	vec2 largura = fwidth(UV * grade);
	vec2 meio = vec2(grossura) * grade;
	vec2 perto = min(celula, 1.0 - celula);
	vec2 linha = 1.0 - smoothstep(meio, meio + largura, perto);
	float borda = 1.0 - smoothstep(grossura * 1.5, grossura * 1.5 + fwidth(UV.x), min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	float moldura = max(max(linha.x, linha.y), borda);
	ALBEDO = mix(cor, caixilho, moldura);
}
