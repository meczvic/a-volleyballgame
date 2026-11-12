extends SceneTree
## Testes da Etapa 1 do plano de jogabilidade (sensação): sons feitos pelo
## jogo, seta em cima do atleta controlado e impacto da cortada (zoom,
## faíscas e rastro dourado).
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --path . --script res://testes/teste_sons_e_impacto.gd
##
## Usa _initialize e espera o 1º quadro porque a partida precisa dos
## autoloads e da árvore pronta.

const Sons := preload("res://scripts/audio/sons.gd")
const Estouro := preload("res://scripts/visual/estouro.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Qualidade := TempoDoToque.Qualidade
const PASSO := 1.0 / 60.0

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_todos_os_sons_existem()
	_teste_cortada_perfeita_tem_impacto()
	_teste_cortada_ruim_so_faz_barulho()
	_teste_ponto_tem_apito_e_torcida()
	_teste_bloqueio_faz_barulho_e_faiscas()
	_teste_perfeito_tem_destaque()
	_teste_seta_segue_e_pula_na_troca()
	_teste_botao_sem_bola_faz_som()

	if falhas == 0:
		print("OK: todos os testes de som e impacto passaram.")
	else:
		print("FALHOU: %d verificação(ões) de som e impacto." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _nova_partida() -> Node:
	var partida = cena.instantiate()
	root.add_child(partida)
	partida.placar.quem_saca = 0
	partida._preparar_saque()
	partida.estado = partida.Estado.RALLY
	partida.saque_em_jogo = false
	partida.toques.reiniciar()
	return partida


func _fechar(partida: Node) -> void:
	partida.temporizador_do_ponto.stop()
	Engine.time_scale = 1.0
	root.remove_child(partida)
	partida.free()


func _estouros(partida: Node) -> int:
	var n := 0
	for filho in partida.get_children():
		if filho.get_script() == Estouro:
			n += 1
	return n


func _teste_todos_os_sons_existem() -> void:
	for nome in Sons.nomes():
		var som = Sons.som(nome)
		_verificar(som is AudioStreamWAV, "o som \"%s\" foi montado" % nome)
		if som is AudioStreamWAV:
			var segundos: float = float((som as AudioStreamWAV).data.size()) / 2.0 / Sons.TAXA
			_verificar(segundos > 0.04 and segundos < 3.0, "o som \"%s\" tem um tamanho razoável (%.2f s)" % [nome, segundos])
	_verificar(Sons.som("nao_existe") == null, "som que não existe não quebra nada")
	# Montado uma vez só: pedir de novo devolve o mesmo.
	_verificar(Sons.som("cortada") == Sons.som("cortada"), "os sons ficam guardados depois de montados")


func _teste_cortada_perfeita_tem_impacto() -> void:
	var partida = _nova_partida()
	var atleta: Node3D = partida.atletas[0][partida.rodizios[0].atleta_na(4)]
	partida.controlados[0] = atleta
	partida.bola.position = atleta.position + Vector3(0.0, 3.0, 0.0)
	var desde: int = partida.sons.historico.size()
	var antes := _estouros(partida)
	partida._cortar(0, Qualidade.PERFEITO)
	_verificar(partida.sons.tocou_desde("cortada", desde), "a cortada faz barulho")
	_verificar(partida.impacto.zoom_atual() > 0.0, "a cortada perfeita dá um soco de zoom na câmera")
	_verificar(_estouros(partida) == antes + 1, "e solta faíscas onde a mão bateu")
	_verificar(partida.rastro.destacado(), "e deixa o rastro da bola dourado")
	_fechar(partida)


func _teste_cortada_ruim_so_faz_barulho() -> void:
	var partida = _nova_partida()
	var atleta: Node3D = partida.atletas[0][partida.rodizios[0].atleta_na(4)]
	partida.controlados[0] = atleta
	partida.bola.position = atleta.position + Vector3(0.0, 3.0, 0.0)
	var desde: int = partida.sons.historico.size()
	var antes := _estouros(partida)
	partida._cortar(0, Qualidade.RUIM)
	_verificar(partida.sons.tocou_desde("cortada", desde), "a cortada ruim também faz barulho")
	_verificar(_estouros(partida) == antes, "mas sem faíscas")
	_verificar(partida.impacto.zoom_atual() == 0.0, "e sem zoom")
	_verificar(not partida.rastro.destacado(), "e sem rastro dourado")
	_fechar(partida)


func _teste_ponto_tem_apito_e_torcida() -> void:
	var partida = _nova_partida()
	var desde: int = partida.sons.historico.size()
	partida._ao_bola_tocar_chao(Vector3(1.0, 0.0, -3.0))
	_verificar(partida.sons.tocou_desde("quique", desde), "a bola no chão faz barulho")
	_verificar(partida.sons.tocou_desde("apito", desde), "o juiz apita o ponto")
	_verificar(partida.sons.tocou_desde("torcida", desde), "e a torcida comemora")
	_fechar(partida)


func _teste_bloqueio_faz_barulho_e_faiscas() -> void:
	var partida = _nova_partida()
	partida.ultimo_toque = 0
	var desde: int = partida.sons.historico.size()
	var antes := _estouros(partida)
	partida._ao_bola_ser_bloqueada()
	_verificar(partida.sons.tocou_desde("bloqueio", desde), "o bloqueio faz barulho")
	_verificar(_estouros(partida) == antes + 1, "e solta faíscas na cor de quem bloqueou")
	_verificar(partida.impacto.zoom_atual() > 0.0, "e dá um soco de zoom")
	_fechar(partida)


func _teste_perfeito_tem_destaque() -> void:
	var partida = _nova_partida()
	var atleta: Node3D = partida.atletas[0][0]
	var desde: int = partida.sons.historico.size()
	partida._avisar_qualidade(atleta, Qualidade.PERFEITO)
	_verificar(partida.sons.tocou_desde("perfeito", desde), "Perfeito! toca o sininho")
	var maior := 0
	for filho in partida.get_children():
		if filho is Label3D and filho.text == TempoDoToque.nome(Qualidade.PERFEITO):
			maior = maxi(maior, filho.font_size)
	_verificar(maior == partida.TAMANHO_DO_AVISO_PERFEITO, "o texto do Perfeito! é maior (%d)" % maior)
	desde = partida.sons.historico.size()
	partida._avisar_qualidade(atleta, Qualidade.BOM)
	_verificar(not partida.sons.tocou_desde("perfeito", desde), "Bom não toca o sininho")
	_fechar(partida)


func _teste_seta_segue_e_pula_na_troca() -> void:
	var partida = _nova_partida()
	var seta = partida.setas_do_controlado[0]
	var primeiro: Node3D = partida.atletas[0][0]
	var segundo: Node3D = partida.atletas[0][1]
	partida.controlados[0] = primeiro
	partida._physics_process(PASSO)
	_verificar(seta.atleta_atual == primeiro, "a seta segue o atleta controlado")
	_verificar(seta.position.y > 1.5, "e fica em cima da cabeça (%.2f m)" % seta.position.y)
	_verificar(Vector2(seta.position.x - primeiro.position.x, seta.position.z - primeiro.position.z).length() < 0.01,
		"bem em cima dele")
	seta.scale = Vector3.ONE
	partida.controlados[0] = segundo
	partida._physics_process(PASSO)
	_verificar(seta.atleta_atual == segundo, "trocou o controle: a seta vai pro outro atleta")
	_verificar(seta.pulando(), "e pula pra mostrar a troca")
	_verificar(partida.setas_do_controlado[1].atleta_atual == partida.controlados[1], "o outro time tem a seta dele")
	_fechar(partida)


func _teste_botao_sem_bola_faz_som() -> void:
	var partida = _nova_partida()
	partida.toques.registrar(1, 0)
	partida.ultimo_toque = 1
	var atleta: Node3D = partida.atletas[0][partida.rodizios[0].atleta_na(6)]
	partida.controlados[0] = atleta
	var ponto: Vector3 = atleta.position + Vector3(4.0, 1.0, 0.0)
	partida.bola.position = ponto
	partida.bola._comecar_voo(ponto, Vector3.ZERO)
	var desde: int = partida.sons.historico.size()
	partida._ao_receber_comando(1, "passe")
	for i in int(ceil((partida.TEMPO_DO_PEDIDO + 2.0 * PASSO) / PASSO)):
		partida._physics_process(PASSO)
	_verificar(partida.sons.tocou_desde("falhou", desde), "botão que não deu faz um som curto (além do anel piscar)")
	_fechar(partida)
