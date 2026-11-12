extends SceneTree
## Testes das jogadas e da leitura do bloqueio dentro da partida:
## largada por cima do bloqueio e bloqueio que corre pra onde foi o
## levantamento (e chega atrasado no levantamento rápido).
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_jogadas_na_partida.gd
##
## Usa _initialize e espera o 1º quadro porque a partida precisa dos
## autoloads e da árvore pronta.

const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Rodizio := preload("res://scripts/regras/rodizio.gd")
const PASSO := 1.0 / 60.0

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_largada_cai_curta()
	_teste_largada_passa_por_cima_do_bloqueio()
	_teste_cortada_no_mesmo_lugar_e_bloqueada()
	_teste_bloqueio_le_o_levantamento()
	_teste_bloqueio_tem_tempo_de_reacao()

	if falhas == 0:
		print("OK: todos os testes das jogadas passaram.")
	else:
		print("FALHOU: %d verificação(ões) das jogadas." % falhas)
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


## Atacante do time 0 (posição 3, central) pronto pra cortar uma bola parada
## no ar perto da rede.
func _montar_ataque(partida: Node) -> Node3D:
	var atleta: Node3D = partida.atletas[0][partida.rodizios[0].atleta_na(3)]
	atleta.position = partida._no_mundo(0, Vector2(0.0, 1.5))
	partida.controlados[0] = atleta
	var ponto: Vector3 = partida._no_mundo(0, Vector2(0.3, 1.2))
	ponto.y = 3.3
	partida.bola.position = ponto
	partida.bola._comecar_voo(ponto, Vector3.ZERO)
	return atleta


func _passar(partida: Node, segundos: float) -> void:
	for i in int(ceil(segundos / PASSO)):
		partida._physics_process(PASSO)
		partida.bola._physics_process(PASSO)


func _fechar(partida: Node) -> void:
	root.remove_child(partida)
	partida.free()


## Ponto onde a bola atacada cruza a rede (sem ninguém bloqueando).
func _cruzamento(largada: bool) -> Vector3:
	var partida = _nova_partida()
	_montar_ataque(partida)
	var cruzou := []
	partida.bola.cruzou_a_rede.connect(func(p): cruzou.append(p))
	_atacar(partida, largada)
	_passar(partida, 1.2)
	_fechar(partida)
	return cruzou[0] if not cruzou.is_empty() else Vector3(0, -1, 0)


## Se os 3 da rede do time 1, no alto do pulo e bem na frente da bola,
## bloqueiam a bola que cruza a rede em "ponto".
func _bloqueia(ponto: Vector3) -> bool:
	var partida = _nova_partida()
	for i in 6:
		if Rodizio.e_da_rede(partida.rodizios[1].posicao_de(i)):
			var atleta: Node3D = partida.atletas[1][i]
			var lugar: Vector3 = partida._no_mundo(1, Vector2(0.0, 0.6))
			atleta.position = Vector3(ponto.x, partida.ALTURA_DO_PULO, lugar.z)
			atleta.set_meta("tempo_do_pulo", partida.DURACAO_DO_PULO / 2.0)
	var bloqueou: bool = partida.bloqueios._tem_bloqueio(ponto, signf(partida._no_mundo(1, Vector2(0.0, 1.0)).z))
	_fechar(partida)
	return bloqueou


func _atacar(partida: Node, largada: bool) -> void:
	partida.lances._comecar_cortada(0)
	if largada:
		partida._ao_receber_comando(1, "passe")


func _teste_largada_cai_curta() -> void:
	var partida = _nova_partida()
	_montar_ataque(partida)
	_atacar(partida, true)
	_verificar(partida.toques.toques == 0, "Passe no ar não toca na hora, vira largada")
	_passar(partida, partida.TEMPO_ATE_A_BATIDA + PASSO)
	_verificar(partida.toques.toques == 1, "a largada sai na batida")
	var queda: Vector3 = partida.bola.ponto_previsto
	var fundo := absf(queda.z)
	_verificar(queda.z * partida._lado(1) > 0.0, "largada vai pro outro lado")
	_verificar(fundo >= partida.LARGADA_FUNDO_MIN - 0.01 and fundo <= partida.LARGADA_FUNDO_MAX + 0.01,
		"largada cai curta (entre 1 e 3 m da rede), caiu a %.1f m" % fundo)
	_fechar(partida)


func _teste_largada_passa_por_cima_do_bloqueio() -> void:
	var ponto := _cruzamento(true)
	_verificar(ponto.y > 0.0, "a largada cruza a rede")
	_verificar(not _bloqueia(ponto), "largada passa por cima do bloqueio (cruzou a %.2f m)" % ponto.y)


func _teste_cortada_no_mesmo_lugar_e_bloqueada() -> void:
	var ponto := _cruzamento(false)
	_verificar(ponto.y > 0.0, "a cortada cruza a rede")
	_verificar(_bloqueia(ponto), "a cortada na mesma situação é bloqueada (cruzou a %.2f m)" % ponto.y)


## Índice do atleta do time 1 na rede com essa função.
func _bloqueador(partida: Node, funcao: String) -> int:
	for i in 6:
		if Rodizio.e_da_rede(partida.rodizios[1].posicao_de(i)) and partida.funcoes[1].get(i, "") == funcao:
			return i
	return -1


## Time 0 levanta pra "ataque" (índice de ATAQUES) com essa altura.
func _levantar(partida: Node, ataque: int, altura: float) -> void:
	partida.toques.registrar(0, 0)
	partida.toques.registrar(0, 1)
	var ponto: Vector3 = partida._no_mundo(0, partida.PONTO_DO_LEVANTADOR)
	ponto.y = 2.4
	partida.bola.position = ponto
	partida.bola._comecar_voo(ponto, Vector3.ZERO)
	partida.bola.lancar(partida.alvos_de_ataque[0][ataque], altura)


func _teste_bloqueio_le_o_levantamento() -> void:
	var partida = _nova_partida()
	_levantar(partida, 0, TempoDoToque.ALTURA_DO_LEVANTAMENTO_NORMAL)
	_passar(partida, partida.REACAO_DO_BLOQUEIO + 0.05)
	var ate := TempoDoToque.tempo_ate_altura(partida.bola.position, partida.bola.velocidade_atual(), TempoDoToque.ALTURA_IDEAL["cortada"], partida.bola.gravidade)
	var x_do_levantamento: float = partida.bola.posicao_daqui_a(ate).x
	var central := _bloqueador(partida, "central")
	_verificar(central >= 0, "time 1 tem central na rede")
	var alvo: Vector3 = partida.ia._alvo_da_ia(1, central)
	_verificar(absf(alvo.x - x_do_levantamento) < 0.3, "central corre pra onde foi o levantamento")
	# Um dos da ponta fica longe: só ajuda quem está do lado da bola.
	var longe := 0
	for funcao in ["ponteiro", "oposto"]:
		var i := _bloqueador(partida, funcao)
		if i >= 0 and absf(partida.ia._alvo_da_ia(1, i).x - x_do_levantamento) > 3.0:
			longe += 1
	_verificar(longe == 1, "o bloqueador do outro lado fica no lugar dele")
	_fechar(partida)


## Central do time 1 começando no meio da rede, com o time 0 levantando
## pra ponta nessa altura.
func _montar_leitura(altura: float) -> Array:
	var partida = _nova_partida()
	var atleta: Node3D = partida.atletas[1][_bloqueador(partida, "central")]
	atleta.position = partida._no_mundo(1, Vector2(0.0, 0.7))
	_levantar(partida, 0, altura)
	return [partida, atleta]


## Passa o tempo até a bola descer na altura da cortada.
func _ate_a_cortada(partida: Node) -> void:
	for i in 300:
		_passar(partida, PASSO)
		if partida.bola.velocidade_atual().y < 0.0 and partida.bola.position.y <= TempoDoToque.ALTURA_IDEAL["cortada"]:
			return


func _teste_bloqueio_tem_tempo_de_reacao() -> void:
	# Reação: logo depois do levantamento, o bloqueio ainda está lendo.
	var montado := _montar_leitura(TempoDoToque.ALTURA_DO_LEVANTAMENTO_ALTO)
	var partida = montado[0]
	var atleta: Node3D = montado[1]
	var antes := atleta.position.x
	_passar(partida, partida.REACAO_DO_BLOQUEIO - 0.05)
	_verificar(absf(atleta.position.x - antes) < 0.05, "o bloqueio espera o tempo de reação antes de correr")
	# No levantamento alto, dá tempo de chegar.
	_ate_a_cortada(partida)
	var distancia := absf(atleta.position.x - partida.bola.position.x)
	_verificar(distancia < 0.6, "no levantamento alto o central chega (ficou a %.1f m)" % distancia)
	_fechar(partida)
	# No rápido, sobra bem menos tempo depois da reação pra fechar e pular.
	var rapido := _montar_leitura(TempoDoToque.ALTURA_DO_LEVANTAMENTO_RAPIDO)
	var tempo_rapido := _tempo_ate_a_cortada(rapido[0])
	var alto := _montar_leitura(TempoDoToque.ALTURA_DO_LEVANTAMENTO_ALTO)
	var tempo_alto := _tempo_ate_a_cortada(alto[0])
	var sobra_rapido: float = tempo_rapido - rapido[0].REACAO_DO_BLOQUEIO
	var sobra_alto: float = tempo_alto - alto[0].REACAO_DO_BLOQUEIO
	_verificar(sobra_rapido < 0.45 and sobra_alto > 0.9,
		"no rápido o bloqueio tem pouco tempo (%.2f s x %.2f s no alto)" % [sobra_rapido, sobra_alto])
	_fechar(rapido[0])
	_fechar(alto[0])


func _tempo_ate_a_cortada(partida: Node) -> float:
	var bola = partida.bola
	return TempoDoToque.tempo_ate_altura(bola.position, bola.velocidade_atual(), TempoDoToque.ALTURA_IDEAL["cortada"], bola.gravidade)
