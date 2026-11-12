extends SceneTree
## As 13 cartas do Modo Caos que ganharam efeito em 12/11/2026.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --path . --script res://testes/teste_cartas_novas.gd

const Atributos := preload("res://scripts/regras/atributos.gd")
const Cartas := preload("res://scripts/regras/cartas.gd")
const Dados := preload("res://scripts/comum/dados.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Q := TempoDoToque.Qualidade

const NOVAS := ["leitura_de_jogo", "braco_quente", "salto_alto", "super_saque", "bloqueio_leitor",
	"diagonal_mortal", "defesa_de_ferro", "contra_ataque", "cortada_sinistra", "bola_fantasma",
	"saque_canhao", "muralha_total", "relampago"]

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_todas_tem_efeito()
	_teste_regras_puras()
	_teste_defesa_de_ferro_salva_uma_vez()
	_teste_saque_canhao_derruba_a_recepcao()
	_teste_cortada_sinistra_atravessa()
	_teste_relampago_acaba()
	root.get_node("Configuracao").modo = "rapida"
	if falhas == 0:
		print("OK: todos os testes das cartas novas passaram.")
	else:
		print("FALHOU: %d verificação(ões) das cartas novas." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _nova_partida() -> Node:
	root.get_node("Configuracao").modo = "rapida"
	var partida = cena.instantiate()
	root.add_child(partida)
	return partida


func _fechar(partida: Node) -> void:
	root.remove_child(partida)
	partida.free()


func _teste_todas_tem_efeito() -> void:
	var dados := Dados.cartas()
	for carta in Cartas.todas(dados):
		_verificar(Cartas.IMPLEMENTADAS.has(str(carta["id"])), "a carta %s entra no sorteio" % carta["id"])
	for id in NOVAS:
		var tem_efeito: bool = Cartas.EFEITOS.has(id) or Cartas.CARGAS_AO_PEGAR.has(id)
		_verificar(tem_efeito, "a carta %s faz alguma coisa" % id)


func _teste_regras_puras() -> void:
	var dados := Dados.cartas()
	var time := { "modificadores": Cartas.modificadores(dados, ["super_saque", "salto_alto", "braco_quente"]) }
	_verificar(Atributos.modificador(time, "velocidade_do_saque") > 1.0, "Super Saque deixa o saque mais rápido")
	_verificar(Atributos.soma(time, "alcance_do_bloqueio") > 0.0, "Salto Alto aumenta o alcance do bloqueio")
	_verificar(Atributos.escala_da_janela(time, "cortada") > Atributos.escala_da_janela({}, "cortada"), "Braço Quente aumenta a janela da cortada")
	# Relâmpago: mais rápido enquanto tem carga.
	var normal := Atributos.velocidade(time)
	Atributos.mudar_carga(time, "relampago", 20.0)
	_verificar(Atributos.velocidade(time) > normal, "Relâmpago acelera o time")
	Atributos.mudar_carga(time, "relampago", 0.0)
	_verificar(is_equal_approx(Atributos.velocidade(time), normal), "sem carga, volta ao normal")
	# Usos: gasta até acabar.
	Atributos.mudar_carga(time, "muralha_total", 3.0)
	var usos := 0
	while Atributos.gastar_carga(time, "muralha_total"):
		usos += 1
	_verificar(usos == 3, "Muralha Total vale 3 ataques (%d)" % usos)


## Bola que ia cair na quadra do time 0 é salva uma vez; a segunda vira ponto.
func _teste_defesa_de_ferro_salva_uma_vez() -> void:
	var partida = _nova_partida()
	partida.cartas_dos_times[0] = ["defesa_de_ferro"]
	partida.caos._dar_cargas(0, "defesa_de_ferro")
	partida.estado = partida.Estado.RALLY
	partida.ultimo_toque = 1
	partida.toques.reiniciar()
	var pontos_antes: Array = partida.placar.pontos.duplicate()
	partida._ao_bola_tocar_chao(Vector3(1.0, 0.0, 4.0))
	_verificar(partida.estado == partida.Estado.RALLY, "a Defesa de Ferro salva a bola (o rally continua)")
	_verificar(partida.placar.pontos == pontos_antes, "ninguém pontua na bola salva")
	_verificar(partida.bola.em_voo, "a bola sobe de novo")
	partida.toques.reiniciar()
	partida.ultimo_toque = 1
	partida._ao_bola_tocar_chao(Vector3(1.0, 0.0, 4.0))
	_verificar(partida.estado == partida.Estado.PONTO, "a segunda bola no mesmo set vira ponto")
	_fechar(partida)


func _teste_saque_canhao_derruba_a_recepcao() -> void:
	var partida = _nova_partida()
	partida._saque_canhao = true
	partida.estado = partida.Estado.RALLY
	partida.toques.reiniciar()
	partida.ultimo_toque = 1
	partida.placar.quem_saca = 1
	partida.saque_em_jogo = true
	# Bola ao alcance do controlado do time 0, na altura do passe.
	var atleta: Node3D = partida.controlados[0]
	partida.bola.position = atleta.position + Vector3(0.2, 0.9, 0.0)
	partida.bola.lancar(atleta.position + Vector3(0.0, 0.0, -0.5), 1.0)
	partida.bola.position = atleta.position + Vector3(0.2, 0.9, 0.0)
	var tocou: bool = partida.lances._tentar_tocar(0, false)
	_verificar(tocou, "a recepção acontece")
	_verificar(partida.qualidade_do_passe[0] == Q.RUIM, "o Saque Canhão faz a recepção sair ruim")
	_verificar(not partida._saque_canhao, "o Saque Canhão vale uma vez")
	_fechar(partida)


func _teste_cortada_sinistra_atravessa() -> void:
	var partida = _nova_partida()
	partida._ataque_atravessa = true
	_verificar(partida.bloqueios._tipo_do_bloqueio(Vector3(0.0, 2.6, 0.0), 1.0) == partida.Bloqueio.NENHUM,
		"com a Cortada Sinistra o bloqueio não pega")
	_fechar(partida)


func _teste_relampago_acaba() -> void:
	var partida = _nova_partida()
	Atributos.mudar_carga(partida.times_em_jogo[0], "relampago", 1.0)
	partida._gastar_relampago(0.6)
	_verificar(Atributos.carga(partida.times_em_jogo[0], "relampago") > 0.0, "o Relâmpago ainda vale no meio")
	partida._gastar_relampago(0.6)
	_verificar(Atributos.carga(partida.times_em_jogo[0], "relampago") == 0.0, "o Relâmpago acaba")
	_fechar(partida)
