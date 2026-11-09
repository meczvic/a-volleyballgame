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
	_verificar(partida.rotulo_mensagem.text.begins_with("Levantamento rápido"),
		"passe e levantamento perfeitos dão o rápido (%s)" % partida.rotulo_mensagem.text)
	_fechar(partida)


func _teste_cortada_ruim_sai_fraca() -> void:
	var forte = _nova_partida()
	var atacante := _atleta(forte, 4)
	atacante.position = forte._no_mundo(0, Vector2(-3.0, 1.2))
	_bola_no_atleta(forte, atacante, TempoDoToque.ALTURA_IDEAL["cortada"], -3.0)
	forte._tentar_tocar(0, true)
	var subida_forte: float = forte.bola.velocidade_atual().y
	_fechar(forte)

	var fraca = _nova_partida()
	atacante = _atleta(fraca, 4)
	atacante.position = fraca._no_mundo(0, Vector2(-3.0, 1.2))
	# Bola subindo devagar a 1,8 m: muito cedo pra cortada.
	_bola_no_atleta(fraca, atacante, 1.8, 0.5)
	fraca._tentar_tocar(0, true)
	var subida_fraca: float = fraca.bola.velocidade_atual().y
	_verificar(subida_fraca > subida_forte, "cortada ruim sobe mais (sai fraca): %.1f > %.1f" % [subida_fraca, subida_forte])
	Engine.time_scale = 1.0
	_fechar(fraca)


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
