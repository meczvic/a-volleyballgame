extends SceneTree
## Testes do toque no tempo certo dentro da partida (cena partida.tscn):
## a qualidade do toque muda o passe, o levantamento e a cortada.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_tempo_na_partida.gd
##
## Usa _initialize e espera o 1º quadro porque a partida precisa dos
## autoloads e da árvore pronta.

const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Q := TempoDoToque.Qualidade

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_passe_na_hora_e_perfeito()
	_teste_passe_cedo_e_ruim_e_limita_o_levantamento()
	_teste_levantamento_rapido()
	_teste_cortada_ruim_sai_fraca()
	_teste_qualidade_da_cortada_no_botao()
	_teste_anel_aparece_pra_quem_vai_tocar()

	if falhas == 0:
		print("OK: todos os testes do tempo na partida passaram.")
	else:
		print("FALHOU: %d verificação(ões) do tempo na partida." % falhas)
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
	root.remove_child(partida)
	partida.free()


## Atleta do time 0 na posição 6, com a bola em "altura" descendo a "vy" m/s
## logo acima dele.
func _bola_no_atleta(partida: Node, atleta: Node3D, altura: float, vy: float) -> void:
	partida.controlados[0] = atleta
	var ponto := Vector3(atleta.position.x, altura, atleta.position.z)
	partida.bola.position = ponto
	partida.bola._comecar_voo(ponto, Vector3(0.0, vy, 0.0))


func _atleta(partida: Node, posicao: int) -> Node3D:
	return partida.atletas[0][partida.rodizios[0].atleta_na(posicao)]


func _teste_passe_na_hora_e_perfeito() -> void:
	var partida = _nova_partida()
	var atleta := _atleta(partida, 6)
	_bola_no_atleta(partida, atleta, TempoDoToque.ALTURA_IDEAL["passe"], -5.0)
	partida._tentar_tocar(0, false)
	_verificar(partida.qualidade_do_passe[0] == Q.PERFEITO, "passe na altura certa é perfeito")
	var alvo: Vector3 = partida._no_mundo(0, partida.PONTO_DO_LEVANTADOR)
	var queda: Vector3 = partida.bola.ponto_previsto
	var erro := Vector2(queda.x - alvo.x, queda.z - alvo.z).length()
	_verificar(erro <= TempoDoToque.ERRO_DO_PASSE[Q.PERFEITO] + 0.01, "passe perfeito cai no levantador (erro %.2f m)" % erro)
	_fechar(partida)


func _teste_passe_cedo_e_ruim_e_limita_o_levantamento() -> void:
	var partida = _nova_partida()
	var atleta := _atleta(partida, 6)
	# Bola ainda a 2,9 m, caindo devagar: falta muito pra altura do passe.
	_bola_no_atleta(partida, atleta, 2.9, -0.5)
	partida._tentar_tocar(0, false)
	_verificar(partida.qualidade_do_passe[0] == Q.RUIM, "passe muito cedo é ruim")
	# Sem direção, passe ruim faz o levantador mandar na ponta (não no meio).
	var escolhido: int = partida._ataque_escolhido(0, Q.RUIM)
	_verificar(partida.ATAQUES[escolhido]["nome"] == "Ponta", "passe ruim: levantamento na ponta")
	_verificar(partida._ataque_escolhido(0, Q.BOM) == partida.ATAQUE_PADRAO, "passe bom: levantamento no meio")
	_fechar(partida)


func _teste_levantamento_rapido() -> void:
	var partida = _nova_partida()
	var levantador: Node3D = partida.atletas[0][partida.levantadores[0]]
	var passador := _atleta(partida, 6)
	if passador == levantador:
		passador = _atleta(partida, 5)
	partida.ultimo_toque = 0
	partida.toques.registrar(0, partida.atletas[0].find(passador))
	partida.qualidade_do_passe[0] = Q.PERFEITO
	_bola_no_atleta(partida, levantador, TempoDoToque.ALTURA_IDEAL["levantamento"], -4.0)
	partida._tentar_tocar(0, false)
	# A mensagem do levantamento aparece na metade da tela do time que levantou.
	_verificar(partida.rotulos_do_time[0].text.begins_with("Rápido"),
		"passe e levantamento perfeitos dão o rápido (%s)" % partida.rotulos_do_time[0].text)
	_fechar(partida)


func _teste_cortada_ruim_sai_fraca() -> void:
	# A qualidade da cortada é medida no botão (_comecar_cortada) e usada na batida.
	var subidas := {}
	for qualidade in [Q.PERFEITO, Q.RUIM]:
		var partida = _nova_partida()
		var atacante := _atleta(partida, 4)
		atacante.position = partida._no_mundo(0, Vector2(-3.0, 1.2))
		_bola_no_atleta(partida, atacante, TempoDoToque.ALTURA_IDEAL["cortada"], -3.0)
		atacante.set_meta("qualidade_da_cortada", qualidade)
		partida._tentar_tocar(0, true)
		subidas[qualidade] = partida.bola.velocidade_atual().y
		_verificar(not atacante.has_meta("qualidade_da_cortada"), "a qualidade da cortada é usada uma vez só")
		Engine.time_scale = 1.0
		_fechar(partida)
	_verificar(subidas[Q.RUIM] > subidas[Q.PERFEITO],
		"cortada ruim sobe mais (sai fraca): %.1f > %.1f" % [subidas[Q.RUIM], subidas[Q.PERFEITO]])


func _teste_qualidade_da_cortada_no_botao() -> void:
	var partida = _nova_partida()
	var atacante := _atleta(partida, 4)
	atacante.position = partida._no_mundo(0, Vector2(-3.0, 1.2))
	# Bola que vai chegar na altura da cortada daqui a TEMPO_ATE_A_BATIDA: apertar agora é perfeito.
	var t: float = partida.TEMPO_ATE_A_BATIDA
	var vy := -3.0
	var altura: float = TempoDoToque.ALTURA_IDEAL["cortada"] - vy * t + 0.5 * 9.8 * t * t
	_bola_no_atleta(partida, atacante, altura, vy)
	partida._comecar_cortada(0)
	_verificar(atacante.get_meta("qualidade_da_cortada", -1) == Q.PERFEITO, "apertar Ataque na hora certa é perfeito")
	Engine.time_scale = 1.0
	_fechar(partida)


func _teste_anel_aparece_pra_quem_vai_tocar() -> void:
	var partida = _nova_partida()
	var atleta := _atleta(partida, 6)
	partida.toques.registrar(1, 0)
	partida.ultimo_toque = 1
	_bola_no_atleta(partida, atleta, 2.0, -3.0)
	partida.bola.ponto_previsto = atleta.position
	partida._atualizar_anel_de_tempo(0)
	_verificar(partida.aneis_de_tempo[0].visible, "anel aparece pra quem vai receber")
	partida._atualizar_anel_de_tempo(1)
	_verificar(not partida.aneis_de_tempo[1].visible, "o outro time não vê anel")
	_fechar(partida)
