// Contorno escuro em volta do objeto, estilo desenho animado.
// Tecnica "casca invertida": desenha o objeto de novo, um pouco maior,
// so pelo lado de dentro. Usado como "next_pass" do material anime.
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 cor_do_contorno : source_color = vec4(0.06, 0.06, 0.08, 1.0);
// Espessura em metros.
uniform float espessura : hint_range(0.0, 0.1) = 0.03;
// Largura minima na tela, em pixels (0 = so a espessura em metros). Faz o
// contorno continuar aparecendo quando o objeto esta longe da camera.
uniform float largura_minima_px : hint_range(0.0, 4.0) = 0.0;

void vertex() {
	float e = espessura;
	if (largura_minima_px > 0.0) {
		vec4 na_camera = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
		// Tamanho de 1 pixel naquela distancia.
		float pixel = 2.0 * max(-na_camera.z, 0.01) / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
		e = max(e, largura_minima_px * pixel);
	}
	VERTEX += NORMAL * e;
}

void fragment() {
	ALBEDO = cor_do_contorno.rgb;
}
