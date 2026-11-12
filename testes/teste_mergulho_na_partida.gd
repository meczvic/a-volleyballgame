extends SceneTree
## Testes do mergulho e dos atributos dos times dentro da partida.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_mergulho_na_partida.gd
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
	_teste_mergulho_alcanca_bola_longe_e_baixa()
	_teste_mergulho_perto_vale_no_maximo_bom()
	_teste_mergulho_no_vazio()
	_teste_bola_alta_nao_da_pra_mergulhar()
	_teste_defesa_aumenta_o_alcance_do_mergulho()
	_teste_velocidade_do_time()
	_teste_bloqueio_do_time()
	_teste_saque_do_time()
	_teste_janela_do_passe_pela_defesa()

	if falhas == 0:
		print("OK: todos os testes do mergulho e dos atributos passaram.")
	else:
		print("FALHOU: %d verificação(ões) do mergulho e dos atributos." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _nova_partida(atributos := {}) -> Node:
	var partida = cena.instantiate()
	root.add_child(partida)
	if not atributos.is_empty():
		for time in 2:
			var dados: Dictionary = partida.times_em_jogo[time].duplicate()
			dados["atributos"] = atributos
			partida.times_em_jogo[time] = dados
	partida.placar.quem_saca = 0
	partida._preparar_saque()
	partida.estado = partida.Estado.RALLY
	partida.saque_em_jogo = false
	partida.toques.reiniciar()
	return partida


func _fechar(partida: Node) -> void:
	root.remove_child(partida)
	partida.free()


## Atleta do time 0 na posição 6 controlado, com a bola "de_lado" metros ao
## lado dele (no eixo x), em "altura", descendo a "vy" m/s.
func _bola_ao_lado(partida: Node, de_lado: float, altura: float, vy := -4.0) -> Node3D:
	var atleta: Node3D = partida.atletas[0][partida.rodizios[0].atleta_na(6)]
	partida.controlados[0] = atleta
	var ponto := Vector3(atleta.position.x + de_lado, altura, atleta.position.z)
	partida.bola.position = ponto
	partida.bola._comecar_voo(ponto, Vector3(0.0, vy, 0.0))
	return atleta


func _teste_mergulho_alcanca_bola_longe_e_baixa() -> void:
	var partida = _nova_partida()
	var atleta := _bola_ao_lado(partida, 2.6, 0.6)
	var x_antes := atleta.position.x
	partida.lances._tentar_tocar(0, false)
	_verificar(partida.toques.toques == 0, "sem mergulho, bola a 2,6 m não é alcançada")
	partida.lances._mergulhar(0)
	_verificar(partida.toques.toques == 1, "mergulho alcança bola a 2,6 m")
	_verificar(partida.qualidade_do_passe[0] == Q.RUIM, "bola de mergulho longe sai ruim")
	_verificar(atleta.position.x > x_antes + 1.5, "atleta se joga na direção da bola")
	_verificar(partida._esta_no_chao(atleta), "atleta fica no chão depois do mergulho")
	# No chão, não se mexe nem mergulha de novo.
	var antes := atleta.position
	partida.ia._mover_ia(atleta, antes + Vector3(3, 0, 0), 0.5)
	_verificar(atleta.position == antes, "atleta no chão não anda")
	partida._relogio += partida.TEMPO_NO_CHAO + 0.01
	_verificar(not partida._esta_no_chao(atleta), "depois de um instante ele levanta")
	_fechar(partida)


func _teste_mergulho_perto_vale_no_maximo_bom() -> void:
	var partida = _nova_partida()
	_bola_ao_lado(partida, 0.5, TempoDoToque.ALTURA_IDEAL["passe"], -5.0)
	partida.lances._mergulhar(0)
	_verificar(partida.toques.toques == 1, "mergulho perto toca na bola")
	_verificar(partida.qualidade_do_passe[0] == Q.BOM, "mergulho na hora certa vale no máximo bom")
	_fechar(partida)


func _teste_mergulho_no_vazio() -> void:
	var partida = _nova_partida()
	var atleta := _bola_ao_lado(partida, 6.0, 0.6)
	var x_antes := atleta.position.x
	partida.lances._mergulhar(0)
	_verificar(partida.toques.toques == 0, "bola longe demais: mergulho não toca")
	_verificar(atleta.position.x > x_antes + 1.0, "mesmo sem tocar, ele se joga")
	_verificar(partida._esta_no_chao(atleta), "e fica no chão")
	_fechar(partida)


func _teste_bola_alta_nao_da_pra_mergulhar() -> void:
	var partida = _nova_partida()
	_bola_ao_lado(partida, 1.0, 2.5)
	partida.lances._mergulhar(0)
	_verificar(partida.toques.toques == 0, "bola alta não se pega de mergulho")
	_fechar(partida)


func _teste_defesa_aumenta_o_alcance_do_mergulho() -> void:
	var forte = _nova_partida({ "defesa": 5 })
	_bola_ao_lado(forte, 3.5, 0.6)
	forte.lances._mergulhar(0)
	_verificar(forte.toques.toques == 1, "defesa 5 alcança bola a 3,5 m")
	_fechar(forte)
	var fraco = _nova_partida({ "defesa": 1 })
	_bola_ao_lado(fraco, 3.5, 0.6)
	fraco.lances._mergulhar(0)
	_verificar(fraco.toques.toques == 0, "defesa 1 não alcança bola a 3,5 m")
	_fechar(fraco)


func _distancia_andada(velocidade: int) -> float:
	var partida = _nova_partida({ "velocidade": velocidade })
	var atleta: Node3D = partida.atletas[0][partida.rodizios[0].atleta_na(6)]
	var antes := atleta.position
	partida.ia._mover(atleta, 0, Vector2(1, 0), 0.1)
	var andou := (atleta.position - antes).length()
	_fechar(partida)
	return andou


func _teste_velocidade_do_time() -> void:
	_verificar(_distancia_andada(5) > _distancia_andada(1), "time mais rápido anda mais")


func _teste_bloqueio_do_time() -> void:
	var forte = _nova_partida({ "bloqueio": 5 })
	var fraco = _nova_partida({ "bloqueio": 1 })
	var largura_forte: float = forte.LARGURA_DO_BLOQUEIO * forte.Atributos.largura_do_bloqueio(forte.times_em_jogo[0])
	var largura_fraca: float = fraco.LARGURA_DO_BLOQUEIO * fraco.Atributos.largura_do_bloqueio(fraco.times_em_jogo[0])
	_verificar(largura_forte > largura_fraca, "bloqueio 5 cobre mais rede")
	_fechar(forte)
	_fechar(fraco)


func _teste_saque_do_time() -> void:
	var forte = _nova_partida({ "saque": 5 })
	var fraco = _nova_partida({ "saque": 1 })
	_verificar(forte._erro_do_saque(0, 0.5) < fraco._erro_do_saque(0, 0.5), "saque 5 erra menos")
	_fechar(forte)
	_fechar(fraco)


func _teste_janela_do_passe_pela_defesa() -> void:
	# Um pouco fora da janela perfeita normal: a defesa boa ainda pega perfeito.
	var erro := TempoDoToque.JANELA_PERFEITA * 1.15
	var forte = _nova_partida({ "defesa": 5 })
	var fraco = _nova_partida({ "defesa": 1 })
	var escala_forte: float = forte.Atributos.escala_da_janela(forte.times_em_jogo[0], "passe")
	var escala_fraca: float = fraco.Atributos.escala_da_janela(fraco.times_em_jogo[0], "passe")
	_verificar(TempoDoToque.qualidade(erro, escala_forte) == Q.PERFEITO, "defesa 5 alarga a janela do passe")
	_verificar(TempoDoToque.qualidade(erro, escala_fraca) == Q.BOM, "defesa 1 estreita a janela do passe")
	_fechar(forte)
	_fechar(fraco)
