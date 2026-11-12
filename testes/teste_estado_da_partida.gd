extends SceneTree
## Fase D: estados da partida e nomes dos lances.
##   godot --headless --path . --script res://testes/teste_estado_da_partida.gd

const EstadoDaPartida := preload("res://scripts/regras/estado_da_partida.gd")
const Lance := preload("res://scripts/regras/lance.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Teclas := preload("res://scripts/entrada/teclas.gd")

var falhas := 0


func _initialize() -> void:
	var E := EstadoDaPartida.Estado
	_verificar(EstadoDaPartida.pode_mudar(E.SAQUE, E.RALLY), "saque -> rally vale")
	_verificar(EstadoDaPartida.pode_mudar(E.SAQUE, E.PONTO), "saque -> ponto vale (posição errada no saque)")
	_verificar(EstadoDaPartida.pode_mudar(E.RALLY, E.PONTO), "rally -> ponto vale")
	_verificar(EstadoDaPartida.pode_mudar(E.PONTO, E.SAQUE), "ponto -> saque vale")
	_verificar(EstadoDaPartida.pode_mudar(E.PONTO, E.FIM), "ponto -> fim vale")
	_verificar(not EstadoDaPartida.pode_mudar(E.RALLY, E.SAQUE), "rally -> saque não vale (tem que passar pelo ponto)")
	_verificar(not EstadoDaPartida.pode_mudar(E.FIM, E.RALLY), "depois do fim não volta")
	_verificar(EstadoDaPartida.nome(E.RALLY) == "RALLY", "nome do estado")
	# Os nomes dos lances batem com as tabelas que usam eles como chave.
	for tipo in [Lance.PASSE, Lance.LEVANTAMENTO, Lance.CORTADA]:
		_verificar(TempoDoToque.ALTURA_IDEAL.has(tipo), "TempoDoToque conhece o toque %s" % tipo)
	for botao in [Lance.BOTAO_PASSE, Lance.BOTAO_ATAQUE, Lance.BOTAO_FLUTUANTE, Lance.BOTAO_BLOQUEIO, Lance.BOTAO_MERGULHO]:
		_verificar(Teclas.ACOES.has(botao), "o botão %s existe nas teclas" % botao)
	if falhas == 0:
		print("OK: todos os testes do estado da partida passaram.")
		quit(0)
	else:
		print("FALHOU: %d verificação(ões) do estado da partida." % falhas)
		quit(1)


func _verificar(condicao: bool, descricao: String) -> void:
	if not condicao:
		falhas += 1
		print("  falhou: ", descricao)
