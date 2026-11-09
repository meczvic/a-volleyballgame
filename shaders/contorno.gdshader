// Contorno escuro em volta do objeto, estilo desenho animado.
// Tecnica "casca invertida": desenha o objeto de novo, um pouco maior,
// so pelo lado de dentro. Usado como "next_pass" do material anime.
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 cor_do_contorno : source_color = vec4(0.06, 0.06, 0.08, 1.0);
// Espessura em metros.
uniform float espessura : hint_range(0.0, 0.1) = 0.03;

void vertex() {
	VERTEX += NORMAL * espessura;
}

void fragment() {
	ALBEDO = cor_do_contorno.rgb;
}
