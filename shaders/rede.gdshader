shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
// Malha da rede: linhas escuras em quadradinhos, vazada no meio. De longe, as
// linhas viram um véu escuro e fraco (não desbota quem está atrás, como a
// faixa branca de antes). Use num QuadMesh do tamanho da rede.

uniform vec4 cor : source_color = vec4(0.07, 0.07, 0.09, 1.0);
// Lado de cada quadradinho e grossura do fio (m).
uniform float malha = 0.1;
uniform float fio = 0.012;
// Opacidade mínima do véu de longe.
uniform float veu = 0.1;

varying vec2 local;

void vertex() {
	local = VERTEX.xy;
}

void fragment() {
	vec2 g = local / malha;
	vec2 distancia = abs(fract(g - 0.5) - 0.5);
	vec2 largura = fwidth(g);
	float meio_fio = 0.5 * fio / malha;
	vec2 linha = 1.0 - smoothstep(vec2(meio_fio), vec2(meio_fio) + largura, distancia);
	float cobertura = max(linha.x, linha.y);
	ALBEDO = cor.rgb;
	ROUGHNESS = 0.9;
	ALPHA = max(veu, cobertura) * cor.a;
}
