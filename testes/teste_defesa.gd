extends SceneTree
## Testes da defesa nova (Etapa 3B do plano de jogabilidade):
## - quantos bloqueiam (triplo, dupla ou só um) pela direção;
## - qualidade do bloqueio pelo tempo do botão (ruim não devolve a bola);
## - recepção de cortada perfeita e mergulho arriscado.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_defesa.gd

const Defender := preload("res://scripts/regras/jeitos_de_defender.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const Qualidade := TempoDoToque.Qualidade
const Rodizio := preload("res://scripts/regras/rodizio.gd")
const PASSO := 1.0 / 60.0

var falhas := 0
var cena: PackedScene


func _initialize() -> void:
	cena = load("res://cenas/partida.tscn")
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_quem_bloqueia()
	_teste_tempo_do_bloqueio()
	_teste_recepcao_e_mergulho_nas_regras()
	_teste_quantos_pulam_na_partida()
	_teste_qualidade_do_botao_na_partida()
	_teste_bloqueio_ruim_so_toca()
	_teste_mergulho_no_vazio_demora()

	if falhas == 0:
		print("OK: todos os testes da defesa passaram.")
	else:
		print("FALHOU: %d verificação(ões) da defesa." % falhas)
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


func _teste_quem_bloqueia() -> void:
	var xs := [-3.0, 0.0, 3.0]
	_verificar(Defender.quem_bloqueia(xs, 0.0, 1.0).size() == 3, "direção pra frente: bloqueio triplo")
	var dupla := Defender.quem_bloqueia(xs, 0.0, 0.0)
	_verificar(dupla.size() == 2 and dupla.has(1), "neutro: dupla com o central")
	var dupla_da_direita := Defender.quem_bloqueia(xs, 1.0, 0.0)
	_verificar(dupla_da_direita.has(1) and dupla_da_direita.has(2), "dupla pro lado apertado (direita)")
	var dupla_da_esquerda := Defender.quem_bloqueia(xs, -1.0, 0.0)
	_verificar(dupla_da_esquerda.has(0) and dupla_da_esquerda.has(1), "dupla pro lado apertado (esquerda)")
	var so_um := Defender.quem_bloqueia(xs, 0.0, -1.0)
	_verificar(so_um.size() == 1 and so_um[0] == 1, "direção pra trás: só o do meio")
	_verificar(Defender.quem_bloqueia([2.0], 0.0, 0.0).size() == 1, "com um só na rede, ele bloqueia")


func _teste_tempo_do_bloqueio() -> void:
	var pulo := 0.6
	_verificar(Defender.qualidade_do_bloqueio(Defender.erro_do_bloqueio(0.2, pulo)) == Qualidade.PERFEITO,
		"apertar um pouco depois do pulo do atacante é perfeito")
	_verificar(Defender.qualidade_do_bloqueio(Defender.erro_do_bloqueio(0.0, pulo)) == Qualidade.BOM,
		"apertar um pouco tarde é bom")
	_verificar(Defender.qualidade_do_bloqueio(Defender.erro_do_bloqueio(0.6, pulo)) == Qualidade.RUIM,
		"apertar muito cedo é ruim")
	_verificar(not Defender.pode_devolver(Qualidade.RUIM) and Defender.pode_devolver(Qualidade.BOM),
		"só o bloqueio ruim não devolve")
	_verificar(Defender.forca_do_rebote(Qualidade.PERFEITO) > Defender.forca_do_rebote(Qualidade.BOM),
		"o bloqueio perfeito devolve mais forte")


func _teste_recepcao_e_mergulho_nas_regras() -> void:
	_verificar(Defender.qualidade_da_recepcao(Qualidade.BOM, int(Qualidade.PERFEITO)) == Qualidade.RUIM,
		"cortada perfeita: passe só bom sai ruim")
	_verificar(Defender.qualidade_da_recepcao(Qualidade.PERFEITO, int(Qualidade.PERFEITO)) == Qualidade.PERFEITO,
		"cortada perfeita: passe perfeito continua perfeito")
	_verificar(Defender.qualidade_da_recepcao(Qualidade.BOM, int(Qualidade.BOM)) == Qualidade.BOM,
		"cortada só boa não muda o passe")
	_verificar(Defender.qualidade_da_recepcao(Qualidade.BOM, -1) == Qualidade.BOM, "sem cortada, não muda")
	_verificar(Defender.qualidade_do_mergulho(Qualidade.PERFEITO, true) == Qualidade.BOM,
		"mergulho de longe no tempo salva a bola (bom)")
	_verificar(Defender.qualidade_do_mergulho(Qualidade.BOM, true) == Qualidade.RUIM,
		"mergulho de longe fora do tempo é ruim")
	_verificar(Defender.qualidade_do_mergulho(Qualidade.PERFEITO, false) == Qualidade.BOM,
		"mergulho de perto é no máximo bom")
	_verificar(Defender.tempo_no_chao_do_mergulho(0.8, Qualidade.RUIM, true) > 0.8,
		"mergulho fora do tempo fica mais no chão")
	_verificar(Defender.tempo_no_chao_do_mergulho(0.8, Qualidade.BOM, false) > 0.8,
		"mergulho no vazio fica mais no chão")
	_verificar(is_equal_approx(Defender.tempo_no_chao_do_mergulho(0.8, Qualidade.BOM, true), 0.8),
		"mergulho certeiro e no tempo fica o tempo normal")


## Põe os 3 da rede do time 1 na rede, nos x -3, 0 e 3. Devolve os índices.
func _por_na_rede(partida: Node) -> Array[int]:
	var da_rede: Array[int] = []
	var xs := [-3.0, 0.0, 3.0]
	for i in 6:
		if Rodizio.e_da_rede(partida.rodizios[1].posicao_de(i)):
			var atleta: Node3D = partida.atletas[1][i]
			atleta.position = partida._no_mundo(1, Vector2(xs[da_rede.size()], 0.8))
			da_rede.append(i)
	return da_rede


func _pulando(partida: Node, indices: Array[int]) -> int:
	var total := 0
	for i in indices:
		if partida._esta_pulando(partida.atletas[1][i]):
			total += 1
	return total


func _teste_quantos_pulam_na_partida() -> void:
	# pra_frente = +1 (triplo), 0 (dupla), -1 (só um). A direção da tela depende
	# do lado do time e da câmera.
	for caso in [[1.0, 3], [0.0, 2], [-1.0, 1]]:
		var partida = _nova_partida()
		var da_rede := _por_na_rede(partida)
		var tela_y: float = float(caso[0]) * partida._lado(0) * float(partida._lado_da_camera(1))
		partida.entradas[1].direcao = Vector2(0.0, tela_y)
		partida._bloquear(1)
		_verificar(_pulando(partida, da_rede) == caso[1],
			"direção %.0f: %d pulam (pularam %d)" % [caso[0], caso[1], _pulando(partida, da_rede)])
		_fechar(partida)


func _teste_qualidade_do_botao_na_partida() -> void:
	var partida = _nova_partida()
	_verificar(partida._qualidade_do_botao_do_bloqueio(1) == Qualidade.RUIM, "sem ataque vindo o bloqueio sai ruim")
	var atacante: Node3D = partida.atletas[0][0]
	partida.cortadas[0] = { "atleta": atacante, "tempo": 0.1, "de": Vector2.ZERO }
	_verificar(partida._qualidade_do_botao_do_bloqueio(1) == Qualidade.PERFEITO,
		"apertar logo depois do pulo do atacante é perfeito")
	partida.cortadas[0] = { "atleta": atacante, "tempo": 0.0, "de": Vector2.ZERO }
	_verificar(partida._qualidade_do_botao_do_bloqueio(1) != Qualidade.RUIM, "e junto com o pulo ainda é bom")
	partida.cortadas[0] = {}
	_fechar(partida)


func _teste_bloqueio_ruim_so_toca() -> void:
	var resultados := []
	for qualidade in [Qualidade.BOM, Qualidade.RUIM]:
		var partida = _nova_partida()
		var da_rede := _por_na_rede(partida)
		for i in da_rede:
			var atleta: Node3D = partida.atletas[1][i]
			atleta.position.y = partida.ALTURA_DO_PULO
			atleta.set_meta("tempo_do_pulo", partida.DURACAO_DO_PULO / 2.0)
		partida._qualidade_do_bloqueio[1] = qualidade
		var lado := signf(partida._no_mundo(1, Vector2(0.0, 1.0)).z)
		resultados.append(partida._tipo_do_bloqueio(Vector3(0.0, 2.4, 0.0), lado))
		_fechar(partida)
	_verificar(resultados[0] == 1, "bloqueio bom devolve a bola")
	_verificar(resultados[1] == 2, "bloqueio ruim só raspa (toque)")


func _teste_mergulho_no_vazio_demora() -> void:
	var partida = _nova_partida()
	partida.bola.em_voo = false
	var atleta: Node3D = partida.controlados[0]
	partida._mergulhar(0)
	var demora: float = float(atleta.get_meta("no_chao_ate")) - partida._relogio
	_verificar(demora > partida.TEMPO_NO_CHAO * 1.2, "mergulho no vazio fica mais tempo no chão (%.2f s)" % demora)
	_fechar(partida)
