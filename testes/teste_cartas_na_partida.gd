extends SceneTree
## Testes do Modo Caos dentro da partida: tela de escolha, cartas valendo
## e jogo parado enquanto os jogadores escolhem.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_cartas_na_partida.gd
##
## Usa _initialize e espera o 1º quadro porque a partida precisa dos
## autoloads e da árvore pronta.

const Atributos := preload("res://scripts/regras/atributos.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Q := TempoDoToque.Qualidade

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_partida_rapida_nao_abre_escolha()
	_teste_caos_abre_escolha_no_comeco()
	_teste_escolha_vale_e_solta_o_jogo()
	_teste_escolha_a_cada_3_pontos()
	_teste_levantador_preciso()
	_teste_trocar_cartas()
	root.get_node("Configuracao").modo = "rapida"

	if falhas == 0:
		print("OK: todos os testes do Modo Caos na partida passaram.")
	else:
		print("FALHOU: %d verificação(ões) do Modo Caos na partida." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _nova_partida(modo: String) -> Node:
	root.get_node("Configuracao").modo = modo
	var partida = cena.instantiate()
	root.add_child(partida)
	return partida


func _fechar(partida: Node) -> void:
	root.remove_child(partida)
	partida.free()


func _teste_partida_rapida_nao_abre_escolha() -> void:
	var partida = _nova_partida("rapida")
	_verificar(not partida.modo_caos, "partida rápida não é Modo Caos")
	_verificar(not partida._escolhendo_cartas(), "partida rápida não abre escolha de cartas")
	_fechar(partida)


func _teste_caos_abre_escolha_no_comeco() -> void:
	var partida = _nova_partida("caos")
	_verificar(partida.modo_caos, "Modo Caos ligado")
	_verificar(partida._escolhendo_cartas(), "abre a escolha antes do 1º saque")
	# Com a escolha aberta, o botão de saque não faz nada.
	partida._ao_receber_comando(partida.placar.quem_saca + 1, "ataque")
	_verificar(partida.carga_do_saque < 0.0, "botões parados durante a escolha")
	var tempo_antes: float = partida.tempo_no_saque
	partida._physics_process(0.5)
	_verificar(is_equal_approx(partida.tempo_no_saque, tempo_antes), "o relógio do saque não corre durante a escolha")
	_fechar(partida)


func _teste_escolha_vale_e_solta_o_jogo() -> void:
	var partida = _nova_partida("caos")
	var tela = partida.escolha_de_cartas
	# Os dois escolhem: Pés Leves pro time 0 e Muro pro time 1.
	tela.terminou.emit(["pes_leves", "muro"])
	_verificar(not partida._escolhendo_cartas(), "a tela fecha quando os dois escolhem")
	_verificar(partida.cartas_dos_times[0] == ["pes_leves"], "carta do time 0 entrou na mão")
	_verificar(partida.cartas_dos_times[1] == ["muro"], "carta do time 1 entrou na mão")
	_verificar(Atributos.velocidade(partida.times_em_jogo[0]) > 1.1, "Pés Leves vale na partida")
	_verificar(Atributos.largura_do_bloqueio(partida.times_em_jogo[1]) > 1.2, "Muro vale na partida")
	_verificar(Atributos.velocidade(partida.times_em_jogo[1]) < 1.1 + 0.2, "a carta de um time não vale pro outro")
	# Com a tela fechada, o saque volta a funcionar.
	partida._ao_receber_comando(partida.placar.quem_saca + 1, "ataque")
	_verificar(partida.carga_do_saque >= 0.0, "botões voltam depois da escolha")
	tela.free()
	_fechar(partida)


func _teste_escolha_a_cada_3_pontos() -> void:
	var partida = _nova_partida("caos")
	partida.escolha_de_cartas.free()
	partida.escolha_de_cartas = null
	partida.estado = partida.Estado.PONTO
	partida.pontos_jogados = 1
	partida._depois_do_ponto()
	_verificar(not partida._escolhendo_cartas(), "no ponto 2 não abre escolha")
	partida.estado = partida.Estado.PONTO
	partida._depois_do_ponto()
	_verificar(partida._escolhendo_cartas(), "no ponto 3 abre a escolha")
	_verificar(partida.estado == partida.Estado.PONTO, "o saque só é preparado depois da escolha")
	partida.escolha_de_cartas.terminou.emit(["maos_firmes", "tapete_vermelho"])
	_verificar(partida.estado == partida.Estado.SAQUE, "depois da escolha, volta pro saque")
	_fechar(partida)


func _teste_levantador_preciso() -> void:
	var partida = _nova_partida("caos")
	partida.escolha_de_cartas.free()
	partida.escolha_de_cartas = null
	partida.cartas_dos_times[0] = ["levantador_preciso"]
	partida._aplicar_cartas()
	_verificar(partida._qualidade_do_toque("levantamento", 0) == Q.PERFEITO, "Levantador Preciso: levantamento sempre perfeito")
	_verificar(partida.interface.rotulos_de_cartas[0].text.contains("Levantador Preciso"), "o nome da carta aparece na tela")
	_fechar(partida)


## Botão TROCAR: cada time começa com as trocas de dados/cartas.json; trocar
## gasta uma e devolve cartas novas; sem troca, devolve nada.
func _teste_trocar_cartas() -> void:
	var partida = _nova_partida("caos")
	var trocas: int = partida.Cartas.trocas_por_partida(partida.dados_das_cartas)
	_verificar(trocas >= 1, "dados dão pelo menos 1 troca")
	_verificar(partida.trocas_restantes == [trocas, trocas], "os dois times começam com %d troca(s)" % trocas)
	var novas: Array = partida._trocar_cartas(0, [])
	_verificar(novas.size() == partida.Cartas.cartas_por_escolha(partida.dados_das_cartas), "troca devolve cartas novas")
	_verificar(partida.trocas_restantes[0] == trocas - 1 and partida.trocas_restantes[1] == trocas, "só o time 0 gastou")
	for i in trocas - 1:
		partida._trocar_cartas(0, [])
	_verificar(partida._trocar_cartas(0, []).is_empty(), "sem troca, não vem carta")
	_verificar(partida.escolha_de_cartas.trocas_restantes(1) == trocas, "a tela recebe as trocas do time")
	partida.escolha_de_cartas.free()
	_fechar(partida)
