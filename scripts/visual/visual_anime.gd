extends RefCounted
## Cria materiais no estilo anime (cel-shaded com contorno).
##
## Uso: malha.material_override = VisualAnime.material(Color.RED)
##
## Personagens do VRoid (formato .vrm) já vêm com o material MToon, que é
## anime por natureza; este aqui serve pro resto (bola, objetos, cápsulas).

const SHADER_ANIME := preload("res://shaders/anime.gdshader")
const SHADER_CONTORNO := preload("res://shaders/contorno.gdshader")


## Material anime de uma cor, com contorno escuro da espessura dada (metros).
## Espessura 0 = sem contorno.
static func material(cor: Color, espessura_do_contorno: float = 0.03) -> ShaderMaterial:
	var material_anime := ShaderMaterial.new()
	material_anime.shader = SHADER_ANIME
	material_anime.set_shader_parameter("cor", cor)
	if espessura_do_contorno > 0.0:
		material_anime.next_pass = contorno(espessura_do_contorno)
	return material_anime


## Só o contorno, pra colocar como "next_pass" de qualquer outro material.
static func contorno(espessura: float = 0.03, cor: Color = Color(0.06, 0.06, 0.08)) -> ShaderMaterial:
	var material_contorno := ShaderMaterial.new()
	material_contorno.shader = SHADER_CONTORNO
	material_contorno.set_shader_parameter("espessura", espessura)
	material_contorno.set_shader_parameter("cor_do_contorno", cor)
	return material_contorno
