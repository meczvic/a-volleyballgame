shader_type spatial;
// Piso de madeira em tábuas, sem textura: cada tábua tem um tom um pouco
// diferente, as emendas ficam desencontradas e há um veio leve. As tábuas
// correm ao longo do comprimento da quadra (eixo z). Brilho de piso encerado.

uniform vec3 cor : source_color = vec3(0.73, 0.5, 0.29);
uniform float largura_da_tabua = 0.16;
uniform float comprimento_da_tabua = 2.4;
uniform float variacao = 0.18;
uniform float aspereza = 0.32;

varying vec3 posicao_no_mundo;

float acaso(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	posicao_no_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = posicao_no_mundo.xz;
	float coluna = floor(p.x / largura_da_tabua);
	float deslocamento = acaso(vec2(coluna, 3.1)) * comprimento_da_tabua;
	float ao_longo = (p.y + deslocamento) / comprimento_da_tabua;
	float tom = acaso(vec2(coluna, floor(ao_longo)));
	vec3 base = cor * (1.0 - variacao * 0.5 + variacao * tom);

	// Veio da madeira.
	float veio = sin((p.y + deslocamento) * 7.0 + sin(p.x * 37.0 + coluna) * 2.0) * 0.5 + 0.5;
	base *= 0.95 + 0.07 * veio;

	// Emendas entre as tábuas (somem de longe, sem serrilhado).
	float fx = fract(p.x / largura_da_tabua);
	float fz = fract(ao_longo);
	float px = fwidth(p.x / largura_da_tabua);
	float pz = fwidth(ao_longo);
	float junta_x = 1.0 - smoothstep(0.0, px * 1.5 + 0.02, min(fx, 1.0 - fx));
	float junta_z = 1.0 - smoothstep(0.0, pz * 1.5 + 0.003, min(fz, 1.0 - fz));
	base *= 1.0 - 0.22 * max(junta_x, junta_z);

	ALBEDO = base;
	ROUGHNESS = aspereza;
	SPECULAR = 0.6;
}
