extends SceneTree
## Junta várias imagens lado a lado (todas na mesma altura), pra comparar
## antes e depois. Não precisa de janela.
##
##   godot --headless --path . --script res://ferramentas/lado_a_lado.gd -- imagens=antes.png,depois.png saida=comparacao.png
##
## Opções: imagens=<lista separada por vírgula>  saida=<arquivo .png>
## altura=<px de cada imagem, padrão 450>  espaco=<px entre elas, padrão 12>
## Caminhos podem ser res://... ou do computador.


func _initialize() -> void:
	var opcoes := {}
	for arg in OS.get_cmdline_user_args():
		var partes := arg.split("=", true, 1)
		opcoes[partes[0]] = partes[1] if partes.size() > 1 else ""
	var caminhos := str(opcoes.get("imagens", "")).split(",", false)
	var saida := str(opcoes.get("saida", ""))
	var altura := int(opcoes.get("altura", 450))
	var espaco := int(opcoes.get("espaco", 12))
	if caminhos.is_empty() or saida == "":
		print("Use imagens=a.png,b.png saida=c.png")
		quit(1)
		return

	var imagens: Array[Image] = []
	var largura_total := 0
	for caminho in caminhos:
		var imagem := Image.load_from_file(_absoluto(caminho))
		if imagem == null or imagem.is_empty():
			print("Não abriu: ", caminho)
			quit(1)
			return
		imagem.convert(Image.FORMAT_RGBA8)
		var largura := int(round(imagem.get_width() * float(altura) / imagem.get_height()))
		imagem.resize(largura, altura, Image.INTERPOLATE_LANCZOS)
		imagens.append(imagem)
		largura_total += largura
	largura_total += espaco * (imagens.size() - 1)

	var junta := Image.create(largura_total, altura, false, Image.FORMAT_RGBA8)
	junta.fill(Color("#12141A"))
	var x := 0
	for imagem in imagens:
		junta.blit_rect(imagem, Rect2i(Vector2i.ZERO, imagem.get_size()), Vector2i(x, 0))
		x += imagem.get_width() + espaco
	junta.save_png(_absoluto(saida))
	print("Salvo: ", _absoluto(saida))
	quit()


func _absoluto(caminho: String) -> String:
	if caminho.begins_with("res://") or caminho.begins_with("user://"):
		return ProjectSettings.globalize_path(caminho)
	return caminho
