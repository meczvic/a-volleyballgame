// Visual anime (cel-shaded): luz e sombra em faixas "chapadas", sem degrade,
// mais um brilho leve na borda. Usado junto com o contorno (contorno.gdshader).
shader_type spatial;
render_mode diffuse_toon, specular_toon;

// Cor base. Se tiver textura, ela e multiplicada por essa cor.
uniform vec4 cor : source_color = vec4(1.0);
uniform sampler2D textura : source_color, hint_default_white;
// Brilho na borda do objeto (0 = sem brilho).
uniform float brilho_de_borda : hint_range(0.0, 1.0) = 0.25;

void fragment() {
	ALBEDO = cor.rgb * texture(textura, UV).rgb;
	ROUGHNESS = 0.8;
	SPECULAR = 0.2;
	RIM = brilho_de_borda;
	RIM_TINT = 0.5;
}
