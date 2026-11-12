extends SceneTree
## Testes dos ataques novos (Etapa 3A do plano de jogabilidade):
## - regras de JeitosDeAtacar: diagonal, paralela, pipe, ataque rápido do meio;
## - levantamento rápido: segurar o botão de flutuante enquanto levanta;
## - bola de segunda: atacar no 2º toque empurra a bola curta;
## - o ataque rápido/pipe/paralela encolhe a largura do bloqueio.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_ataques.gd

const Jeitos := preload("res://scripts/regras/jeitos_de_atacar.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Qualidade := TempoDoToque.Qualidade
const Rodizio := preload("res://scripts/regras/rodizio.gd")
const Atributos := preload("res://scripts/regras/atributos.gd")
const PASSO := 1.0 / 60.0

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_jeito_da_mira()
	_teste_efeitos()
	_teste_levantamento_rapido_forcado()
	_teste_bola_de_segunda()
	_teste_bloqueio_encolhe()

	if falhas == 0:
		print("OK: todos os testes dos ataques passaram.")
	else:
		print("FALHOU: %d verificação(ões) dos ataques." % falhas)
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


func _teste_jeito_da_mira() -> void:
	_verificar(Jeitos.jeito_da_mira(-3.5, 3.2) == "diagonal", "da ponta esquerda pro lado direito é diagonal")
	_verificar(Jeitos.jeito_da_mira(3.5, -3.2) == "diagonal", "da ponta direita pro lado esquerdo é diagonal")
	_verificar(Jeitos.jeito_da_mira(-3.5, -3.2) == "paralela", "rente à lateral do mesmo lado é paralela")
	_verificar(Jeitos.jeito_da_mira(3.5, 3.0) == "paralela", "paralela também na direita")
	_verificar(Jeitos.jeito_da_mira(-3.5, 0.0) == "", "pro meio da quadra não é diagonal nem paralela")
	_verificar(Jeitos.jeito_da_mira(0.0, 3.2) == "", "o meio não ataca em diagonal nem paralela")
	_verificar(Jeitos.jeito_da_mira(-3.5, -1.0) == "", "no meio do caminho do mesmo lado não é paralela")


func _teste_efeitos() -> void:
	var comum := Jeitos.efeito("Ponta", false, "")
	_verificar(comum["nome"] == "" and is_equal_approx(comum["bloqueio"], 1.0), "cortada comum não muda nada")
	var rapido_meio := Jeitos.efeito("Meio", true, "")
	_verificar(rapido_meio["nome"] == "Ataque rápido!", "levantamento rápido pro meio é o ataque rápido")
	_verificar(rapido_meio["bloqueio"] < 1.0, "o ataque rápido do meio encolhe o bloqueio")
	var rapido_ponta := Jeitos.efeito("Ponta", true, "")
	_verificar(rapido_ponta["bloqueio"] < 1.0 and rapido_ponta["bloqueio"] > rapido_meio["bloqueio"],
		"o rápido de ponta encolhe menos que o do meio")
	var pipe := Jeitos.efeito("Fundo", false, "")
	_verificar(pipe["nome"] == "Pipe!" and pipe["bloqueio"] < 1.0 and pipe["subida_a_menos"] > 0.0,
		"o pipe é mais forte e mais difícil de bloquear")
	var paralela := Jeitos.efeito("Ponta", false, "paralela")
	_verificar(paralela["nome"] == "Paralela!" and paralela["erro_a_mais"] > 0.0, "a paralela arrisca sair")
	var diagonal := Jeitos.efeito("Ponta", false, "diagonal")
	_verificar(diagonal["nome"] == "Diagonal!" and diagonal["erro_a_mais"] < 0.0, "a diagonal é mais segura")
	var pipe_paralelo := Jeitos.efeito("Fundo", false, "paralela")
	_verificar(pipe_paralelo["nome"] == "Pipe!" and pipe_paralelo["bloqueio"] < pipe["bloqueio"],
		"pipe na paralela junta os dois efeitos e mantém o nome Pipe")


## Time 0 com o atleta 1 como controlado, pronto pra levantar.
func _montar_levantamento(partida: Node, passe: Qualidade) -> void:
	partida.toques.registrar(0, 0)
	partida.controlados[0] = partida.atletas[0][1]
	partida.qualidade_do_passe[0] = passe
	var ponto: Vector3 = partida._no_mundo(0, partida.PONTO_DO_LEVANTADOR)
	ponto.y = 2.4
	partida.bola.position = ponto
	partida.bola._comecar_voo(ponto, Vector3.ZERO)


func _teste_levantamento_rapido_forcado() -> void:
	# Sem segurar o botão, passe bom + levantamento bom dá levantamento normal.
	var partida = _nova_partida()
	_montar_levantamento(partida, Qualidade.BOM)
	partida.lances._levantar(0, Qualidade.BOM)
	_verificar(not partida._ultimo_levantamento[0]["rapido"], "sem o botão extra o levantamento não é rápido")
	_fechar(partida)

	# Segurando o botão de flutuante, vira rápido.
	partida = _nova_partida()
	_montar_levantamento(partida, Qualidade.BOM)
	partida._ao_receber_comando(1, "saque_flutuante")
	partida.lances._levantar(0, Qualidade.BOM)
	_verificar(partida._ultimo_levantamento[0]["rapido"], "segurando o botão extra o levantamento é rápido")
	_verificar(partida._ultimo_levantamento[0]["nome"] == "Meio", "sem direção, o rápido vai pro meio")
	# Soltou: o próximo levantamento volta ao normal.
	partida._ao_soltar_botao(1, "saque_flutuante")
	_verificar(not partida._segurando_botao[0].has("saque_flutuante"), "soltar o botão limpa o estado")
	_fechar(partida)

	# Passe ruim não deixa levantar rápido.
	partida = _nova_partida()
	_montar_levantamento(partida, Qualidade.RUIM)
	partida._ao_receber_comando(1, "saque_flutuante")
	partida.lances._levantar(0, Qualidade.BOM)
	_verificar(not partida._ultimo_levantamento[0]["rapido"], "passe ruim não deixa levantar rápido")
	_fechar(partida)


func _teste_bola_de_segunda() -> void:
	var partida = _nova_partida()
	partida.toques.registrar(0, 0)
	var atleta: Node3D = partida.atletas[0][partida.rodizios[0].atleta_na(3)]
	atleta.position = partida._no_mundo(0, Vector2(0.0, 1.5))
	partida.controlados[0] = atleta
	var ponto: Vector3 = partida._no_mundo(0, Vector2(0.3, 1.2))
	ponto.y = 3.3
	partida.bola.position = ponto
	partida.bola._comecar_voo(ponto, Vector3.ZERO)
	partida.lances._comecar_cortada(0)
	_passar(partida, partida.TEMPO_ATE_A_BATIDA + PASSO)
	_verificar(partida.toques.toques == 2, "a bola de segunda é o 2º toque")
	var queda: Vector3 = partida.bola.ponto_previsto
	var fundo := absf(queda.z)
	_verificar(queda.z * partida._lado(1) > 0.0, "a bola de segunda vai pro outro lado")
	_verificar(fundo >= partida.LARGADA_FUNDO_MIN - 0.01 and fundo <= partida.LARGADA_FUNDO_MAX + 0.01,
		"a bola de segunda cai curta, caiu a %.1f m da rede" % fundo)
	_fechar(partida)


## Quanto o bloqueio do time 1 aceita de distância (m) em volta do ponto, com
## o fator do ataque dado: procura o primeiro afastamento em que deixa de devolver.
func _alcance_do_bloqueio(fator: float) -> float:
	var partida = _nova_partida()
	partida._bloqueio_do_ataque = fator
	var lado := signf(partida._no_mundo(1, Vector2(0.0, 1.0)).z)
	var ponto := Vector3(0.0, 2.4, 0.0)
	var alcance := 0.0
	for passo in 40:
		var afastamento := 0.05 * float(passo)
		for i in 6:
			if Rodizio.e_da_rede(partida.rodizios[1].posicao_de(i)):
				var atleta: Node3D = partida.atletas[1][i]
				var lugar: Vector3 = partida._no_mundo(1, Vector2(0.0, 0.6))
				atleta.position = Vector3(afastamento, partida.ALTURA_DO_PULO, lugar.z)
				atleta.set_meta("tempo_do_pulo", partida.DURACAO_DO_PULO / 2.0)
			else:
				partida.atletas[1][i].position = partida._no_mundo(1, Vector2(0.0, 8.0))
		if partida.bloqueios._tipo_do_bloqueio(ponto, lado) == partida.Bloqueio.DEVOLVE:
			alcance = afastamento
	_fechar(partida)
	return alcance


func _teste_bloqueio_encolhe() -> void:
	var normal := _alcance_do_bloqueio(1.0)
	var encolhido := _alcance_do_bloqueio(Jeitos.BLOQUEIO_DO_RAPIDO_DO_MEIO)
	_verificar(normal > 0.0, "o bloqueio devolve quando está bem na frente (alcance %.2f)" % normal)
	_verificar(encolhido < normal, "o bloqueio devolve de menos longe contra o ataque rápido (%.2f < %.2f)" % [encolhido, normal])
