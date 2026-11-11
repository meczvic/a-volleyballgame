shader_type spatial;
render_mode cull_disabled;
// Guarda-corpo num QuadMesh só: corrimão em cima, barra embaixo e barras
// verticais vazadas. "local" é a posição no QuadMesh (metros, centro = 0).

uniform vec3 cor : source_color = vec3(0.25, 0.2, 0.16);
uniform float altura = 1.0;
uniform float espaco = 0.14;
uniform float barra = 0.025;
uniform float corrimao = 0.07;

varying vec2 local;

void vertex() {
	local = VERTEX.xy;
}

void fragment() {
	float y = local.y + altura * 0.5;
	float em_cima = step(altura - corrimao, y);
	float embaixo = 1.0 - step(corrimao * 0.6, y);
	float meio = step(altura * 0.5 - 0.02, y) * (1.0 - step(altura * 0.5 + 0.02, y));
	float x = local.x / espaco;
	float distancia = abs(fract(x) - 0.5) * espaco;
	float vertical = 1.0 - smoothstep(barra * 0.5, barra * 0.5 + fwidth(local.x), distancia);
	float cheio = max(max(em_cima, embaixo), max(meio, vertical));
	ALBEDO = cor;
	ROUGHNESS = 0.6;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ALPHA = cheio;
}
