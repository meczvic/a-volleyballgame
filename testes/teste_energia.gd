extends SceneTree
## Testes do medidor de energia e da super cortada (Etapa 4 do plano de
## jogabilidade):
## - regras de Energia: encher, ficar cheia, gastar, ganhos por toque;
## - na partida: ponto enche a barra, barra na tela acompanha, e a cortada
##   com a energia cheia vira super (gasta a energia, encolhe o bloqueio).
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_energia.gd

const Energia := preload("res://scripts/regras/energia.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Qualidade := TempoDoToque.Qualidade
const PASSO := 1.0 / 60.0

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_regras()
	_teste_energia_na_partida()
	_teste_super_cortada()

	if falhas == 0:
		print("OK: todos os testes da energia passaram.")
	else:
		print("FALHOU: %d verificação(ões) da energia." % falhas)
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


func _passar(partida: Node, segundos: float) -> void:
	for i in int(ceil(segundos / PASSO)):
		partida._physics_process(PASSO)
		partida.bola._physics_process(PASSO)


func _fechar(partida: Node) -> void:
	root.remove_child(partida)
	partida.free()


func _teste_regras() -> void:
	var energia := Energia.new()
	_verificar(not energia.cheia() and energia.valor == 0.0, "começa vazia")
	_verificar(not energia.encher(0.4), "encher um pouco não enche tudo")
	_verificar(energia.encher(0.7), "passar de 1 enche e avisa")
	_verificar(energia.cheia() and is_equal_approx(energia.valor, 1.0), "o valor não passa de 1")
	_verificar(not energia.encher(0.2), "já cheia, não avisa de novo")
	energia.gastar()
	_verificar(energia.valor == 0.0 and not energia.cheia(), "gastar zera")
	_verificar(Energia.ganho_do_toque("passe", Qualidade.PERFEITO) > Energia.ganho_do_toque("passe", Qualidade.BOM),
		"passe perfeito enche mais que o bom")
	_verificar(Energia.ganho_do_toque("cortada", Qualidade.RUIM) == 0.0, "toque ruim não enche")
	_verificar(Energia.ganho_do_toque("coisa", Qualidade.PERFEITO) == 0.0, "tipo desconhecido não enche")
	_verificar(Energia.GANHO_DO_BLOQUEIO_QUE_DEVOLVE > Energia.GANHO_DO_PONTO, "bloquear de verdade vale mais que um ponto qualquer")


func _teste_energia_na_partida() -> void:
	var partida = _nova_partida()
	_verificar(partida.energias[0].valor == 0.0, "a partida começa com a energia zerada")
	partida._encerrar_rally(0, "dentro")
	_verificar(is_equal_approx(partida.energias[0].valor, Energia.GANHO_DO_PONTO), "quem faz o ponto ganha energia")
	_verificar(is_equal_approx(partida.energias[1].valor, Energia.GANHO_DO_PONTO_PERDIDO), "quem toma o ponto ganha um pouco")
	_verificar(is_equal_approx(partida.interface.barras_de_energia[0].fracao(), Energia.GANHO_DO_PONTO), "a barra na tela acompanha")
	partida._ganhar_energia(0, 1.0)
	_verificar(partida.energias[0].cheia(), "dá pra encher a energia")
	_verificar(partida.sons.historico.has("perfeito"), "avisa com o sininho quando enche")
	_fechar(partida)


func _teste_super_cortada() -> void:
	var resultados := {}
	for cheia in [false, true]:
		var partida = _nova_partida()
		var atleta: Node3D = partida.atletas[0][partida.rodizios[0].atleta_na(3)]
		var outros: Array[int] = []
		for i in 6:
			if partida.atletas[0][i] != atleta and outros.size() < 2:
				outros.append(i)
		partida.toques.registrar(0, outros[0])
		partida.toques.registrar(0, outros[1])
		atleta.position = partida._no_mundo(0, Vector2(0.0, 1.5))
		partida.controlados[0] = atleta
		var ponto: Vector3 = partida._no_mundo(0, Vector2(0.3, 1.2))
		ponto.y = 3.3
		partida.bola.position = ponto
		partida.bola._comecar_voo(ponto, Vector3.ZERO)
		if cheia:
			partida.energias[0].encher(1.0)
		_verificar(partida._comecar_cortada(0), "a cortada começa")
		atleta.set_meta("qualidade_da_cortada", Qualidade.BOM)
		_passar(partida, partida.TEMPO_ATE_A_BATIDA + PASSO)
		_verificar(partida.toques.toques == 3, "a cortada saiu no 3º toque")
		resultados[cheia] = {
			"bloqueio": partida._bloqueio_do_ataque,
			"energia": partida.energias[0].valor,
			"forca": partida._forca_da_cortada,
			"mensagem": str(partida.interface.rotulos_do_time[0].text),
		}
		_fechar(partida)
	_verificar(resultados[false]["bloqueio"] > Energia.BLOQUEIO_DA_SUPER, "sem energia cheia o bloqueio pega normal")
	_verificar(resultados[true]["bloqueio"] <= Energia.BLOQUEIO_DA_SUPER + 0.0001, "a super cortada encolhe o bloqueio")
	_verificar(resultados[true]["energia"] < 0.5, "a super gasta a energia (sobrou %.2f)" % resultados[true]["energia"])
	_verificar(resultados[true]["forca"] == int(Qualidade.PERFEITO), "a super conta como cortada perfeita na recepção")
	_verificar(resultados[true]["mensagem"].contains("SUPER"), "a tela diz SUPER CORTADA (disse \"%s\")" % resultados[true]["mensagem"])
