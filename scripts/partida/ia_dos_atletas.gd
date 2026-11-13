extends RefCounted
## Para onde cada atleta anda: o controlado pelo jogador e os companheiros (cobertura, defesa, bloqueio, formação).
##
## Saiu do partida.gd (Fase C do plano de melhorias). "p" é a partida:
## tudo que é dela aparece como p.algo.

const Formacao := preload("res://scripts/regras/formacao.gd")
const Rodizio := preload("res://scripts/regras/rodizio.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")

const Lance := preload("res://scripts/regras/lance.gd")
const Atributos := preload("res://scripts/regras/atributos.gd")

## A partida (partida.gd).
var p


func _init(partida) -> void:
	p = partida


func _mover(atleta: Node3D, time: int, direcao: Vector2, delta: float) -> void:
	atleta.position += Vector3(direcao.x, 0.0, direcao.y) * p.VELOCIDADE * p._atributo(time, "velocidade") * delta
	# Cada time fica no próprio lado da rede (com um pouco de área livre).
	var limite_x = p.LARGURA / 2.0 + 2.0
	atleta.position.x = clampf(atleta.position.x, -limite_x, limite_x)
	var fundo = p.COMPRIMENTO / 2.0 + 2.0
	if time == 0:
		atleta.position.z = clampf(atleta.position.z, 0.4, fundo)
	else:
		atleta.position.z = clampf(atleta.position.z, -fundo, -0.4)


## Lugar de cada atleta guardado por "momento" (13/11/2026, pedido do Victor:
## os companheiros andavam o tempo todo, um pouco pra cá e pra lá, e confundia).
## "time_indice" -> [momento, lugar no mundo].
var _lugares_guardados := {}


## Lugar (no mundo) pra onde o atleta "indice" do "time" deve ir agora.
## O lugar só muda quando muda o momento do jogo (cada bola lançada: saque,
## passe, levantamento, ataque, e o ponto): aí cada um vai direto pro lugar
## novo, sem ficar ajustando. Quem está no bloqueio continua lendo a bola.
func _alvo_da_ia(time: int, indice: int) -> Vector3:
	if _esta_no_bloqueio(time, indice):
		return _calcular_alvo(time, indice)
	var momento := [p.estado, p.bola.lancamentos, p.toques.time_com_a_bola, p.toques.toques,
		p.cortadas[0].is_empty(), p.cortadas[1].is_empty(), p.placar.quem_saca]
	var chave := "%d_%d" % [time, indice]
	var guardado: Array = _lugares_guardados.get(chave, [])
	if guardado.is_empty() or guardado[0] != momento:
		guardado = [momento, _calcular_alvo(time, indice)]
		_lugares_guardados[chave] = guardado
	return guardado[1]


## O atleta da rede está subindo pro bloqueio (o outro time vai atacar).
func _esta_no_bloqueio(time: int, indice: int) -> bool:
	if p.estado != p.Estado.RALLY:
		return false
	var posicao: int = p.rodizios[time].posicao_de(indice)
	var outro := 1 - time
	return Rodizio.e_da_rede(posicao) and p.toques.time_com_a_bola == outro and p.toques.toques >= 2 \
		and float(p.atletas[time][indice].get_meta("fora_do_bloqueio_ate", -1.0)) <= p._relogio


## Lugar calculado agora (sem guardar). No saque: a formação na ordem do rodízio (regra). Depois do saque, cada
## um vai pro lado da sua função (ponteiro na esquerda, central no meio,
## oposto e levantador na direita) e o levantador do fundo infiltra pra
## levantar quando a bola vem pro nosso lado. Quando o nosso time ataca, os
## outros cobrem o atacante; quando o outro time ataca, os do fundo se
## posicionam pelo lado do atacante. E ninguém fica em cima de um colega.
func _calcular_alvo(time: int, indice: int) -> Vector3:
	var posicao: int = p.rodizios[time].posicao_de(indice)
	var da_rede = Rodizio.e_da_rede(posicao)
	var e_levantador = indice == p.levantadores[time]
	if p.estado != p.Estado.RALLY:
		var recebendo: bool = time != p.placar.quem_saca
		return p._no_mundo(time, Formacao.lugar_no_saque(posicao, e_levantador, recebendo))

	var outro = 1 - time
	var funcao: String = p.funcoes[time].get(indice, "")
	var x_da_funcao = Formacao.x_da_funcao(funcao, da_rede)
	var bola_vem_pra_ca: bool = p.bola.em_voo and p._lado_da_queda() == time
	# O adversário levantou ou atacou: a rede fica pro bloqueio até a gente tocar.
	var adversario_vai_atacar: bool = p.toques.time_com_a_bola == outro and p.toques.toques >= 2
	var montando_o_ataque: bool = (p.toques.time_com_a_bola == time and p.toques.toques < 3) \
		or (bola_vem_pra_ca and not adversario_vai_atacar)
	var lugar: Vector2

	if da_rede and adversario_vai_atacar \
			and float(p.atletas[time][indice].get_meta("fora_do_bloqueio_ate", -1.0)) > p._relogio:
		# Ficou fora do bloqueio (duplo ou simples): ajuda na defesa.
		return p._no_mundo(time, _abrir_espaco(time, indice, _lugar_na_defesa(time, x_da_funcao)))
	if da_rede and adversario_vai_atacar:
		# Sobe pra rede e lê o levantamento: corre pra onde a bola vai.
		# (Sem abrir espaço: o bloqueio duplo é um do lado do outro.)
		lugar = Vector2(_x_do_bloqueio(time, indice, funcao, x_da_funcao), 0.7)
		return p._no_mundo(time, lugar)
	if _vamos_atacar(time):
		# Cobertura: chega perto do atacante, cada um do seu lado.
		var padrao = Vector2(x_da_funcao, 1.5 if da_rede else Formacao.y_do_fundo(x_da_funcao))
		lugar = _lugar_na_cobertura(time, padrao, p.COBERTURA_DA_REDE if da_rede else p.COBERTURA_DO_FUNDO)
	elif e_levantador and montando_o_ataque:
		# Infiltração: o levantador vai pro lugar do levantamento.
		return p._no_mundo(time, p.PONTO_DO_LEVANTADOR)
	elif da_rede and montando_o_ataque:
		# Recua pra ter espaço de correr pro ataque.
		lugar = Vector2(x_da_funcao, p.LINHA_DE_ATAQUE)
	elif da_rede:
		lugar = Vector2(x_da_funcao, 1.5)
	elif adversario_vai_atacar:
		lugar = _lugar_na_defesa(time, x_da_funcao)
	else:
		lugar = Vector2(x_da_funcao, Formacao.y_do_fundo(x_da_funcao))
	return p._no_mundo(time, _abrir_espaco(time, indice, lugar))


## O nosso time vai atacar: levantamento no ar vindo pra cá, ou atacante no pulo.
func _vamos_atacar(time: int) -> bool:
	if not p.cortadas[time].is_empty():
		return true
	return p.toques.time_com_a_bola == time and p.toques.toques == 2 and p.bola.em_voo and p._lado_da_queda() == time


## Onde vai ser a cortada do "time" (em coordenadas do time): o atacante no
## pulo, ou onde a bola levantada vai estar na altura da cortada.
func _ponto_do_ataque(time: int) -> Vector2:
	if not p.cortadas[time].is_empty():
		return p._no_time(time, (p.cortadas[time]["atleta"] as Node3D).position)
	var ate_a_batida = TempoDoToque.tempo_ate_altura(p.bola.position, p.bola.velocidade_atual(), TempoDoToque.ALTURA_IDEAL[Lance.CORTADA], p.bola.gravidade)
	return p._no_time(time, p.bola.posicao_daqui_a(maxf(ate_a_batida, 0.0)))


## Cobertura: do lugar de sempre ("padrao"), chega até "raio" metros do
## ponto do ataque, mantendo o lado (assim cada um cobre um pedaço).
func _lugar_na_cobertura(time: int, padrao: Vector2, raio: float) -> Vector2:
	var ataque = _ponto_do_ataque(time)
	var lugar = ataque + (padrao - ataque).limit_length(raio)
	lugar.y = maxf(lugar.y, 1.0)
	return lugar


## Defesa do fundo contra o ataque do outro time: anda um pouco pro lado do
## atacante; quem fica longe dele (a diagonal) recua, quem fica perto (a
## paralela) avança.
func _lugar_na_defesa(time: int, x_da_funcao: float) -> Vector2:
	var outro = 1 - time
	if not p.bola.em_voo or p._lado_da_queda() == time and p.cortadas[outro].is_empty():
		return Vector2(x_da_funcao, Formacao.y_do_fundo(x_da_funcao))
	var mundo = p._no_mundo(outro, _ponto_do_ataque(outro))
	var ataque_x = p._no_time(time, mundo).x
	var x = clampf(x_da_funcao + ataque_x * p.DEFESA_PRO_LADO_DO_ATAQUE, -p.LARGURA / 2.0 + 0.5, p.LARGURA / 2.0 - 0.5)
	var longe = clampf((absf(x_da_funcao - ataque_x) - 3.0) / 3.0, -1.0, 1.0)
	return Vector2(x, Formacao.y_do_fundo(x_da_funcao) + longe * p.DEFESA_RECUO)


## Sem amontoar: se um colega já está perto do "lugar", afasta o lugar dele.
func _abrir_espaco(time: int, indice: int, lugar: Vector2) -> Vector2:
	var ajustado = lugar
	for i in 6:
		if i == indice:
			continue
		var colega = p._no_time(time, p.atletas[time][i].position)
		var afastar = ajustado - colega
		var distancia = afastar.length()
		if distancia >= p.ESPACO_ENTRE_ATLETAS:
			continue
		if distancia < 0.01:
			# Em cima do colega: sai pro lado (cada um pra um lado, pelo número).
			afastar = Vector2(1.0 if indice > i else -1.0, 0.0)
		ajustado += afastar.normalized() * (p.ESPACO_ENTRE_ATLETAS - distancia)
	ajustado.x = clampf(ajustado.x, -p.LARGURA / 2.0 - 1.5, p.LARGURA / 2.0 + 1.5)
	ajustado.y = maxf(ajustado.y, 1.0)
	return ajustado


## Depois do ponto: cada um vai pro lugar que vai ocupar no próximo saque
## (quem saca vai pra trás da linha de fundo).
func _alvo_depois_do_ponto(time: int, indice: int) -> Vector3:
	if time == p.placar.quem_saca and indice == p.rodizios[time].atleta_na(1):
		return p._no_mundo(time, p.POSICAO_DO_SACADOR)
	return _alvo_da_ia(time, indice)


## Leitura do bloqueio: com o levantamento no ar, o bloqueio vê onde a bola
## vai estar na hora da cortada e corre pra lá. O central vai sempre; os
## da ponta só se a bola vai pro lado deles. Com o tempo de reação e a
## velocidade limitada, o levantamento rápido chega antes do bloqueio fechar.
## Antes do levantamento, acompanha a bola.
func _x_do_bloqueio(time: int, indice: int, funcao: String, x_da_funcao: float) -> float:
	var bola_x_do_time: float = p.bola.position.x * p._lado(time)
	if p.toques.toques < 2 or not p.bola.em_voo or p._lado_da_queda() == time:
		return lerpf(x_da_funcao, bola_x_do_time, 0.5)
	# Modo Caos: Bloqueio Leitor lê o levantamento na hora; Muralha Total junta os três.
	var leitor := Atributos.tem(p.times_em_jogo[time], "bloqueio_leitor")
	var muralha := Atributos.carga(p.times_em_jogo[time], "muralha_total") >= 1.0
	if p.bola.tempo_de_voo() < p.REACAO_DO_BLOQUEIO and not leitor and not muralha:
		# Ainda lendo o levantamento: fica onde está.
		return p.atletas[time][indice].position.x * p._lado(time)
	# Onde a bola vai estar na altura da cortada (descendo).
	var ate_a_batida = TempoDoToque.tempo_ate_altura(p.bola.position, p.bola.velocidade_atual(), TempoDoToque.ALTURA_IDEAL[Lance.CORTADA], p.bola.gravidade)
	var alvo_x: float = p.bola.posicao_daqui_a(maxf(ate_a_batida, 0.0)).x * p._lado(time)
	if funcao == "central" or muralha or absf(alvo_x - x_da_funcao) <= p.AJUDA_DO_BLOQUEIO:
		return alvo_x
	return x_da_funcao


## Antes do saque, o atleta controlado do time que recebe não pode sair da
## ordem do rodízio nem da quadra (senão é falta de posição).
func _manter_na_ordem(time: int, atleta: Node3D) -> void:
	var indice: int = p.atletas[time].find(atleta)
	if indice < 0:
		return
	var lugares = _lugares_do_time(time)
	var posicao: int = p.rodizios[time].posicao_de(indice)
	var ignorar = 1 if time == p.placar.quem_saca else 0
	var ajustado = Formacao.limitar(posicao, lugares[posicao], lugares, ignorar)
	var no_mundo = p._no_mundo(time, ajustado)
	atleta.position.x = no_mundo.x
	atleta.position.z = no_mundo.z


## Onde está cada posição do rodízio do "time", em coordenadas do time.
func _lugares_do_time(time: int) -> Dictionary:
	var lugares = {}
	for i in 6:
		lugares[p.rodizios[time].posicao_de(i)] = p._no_time(time, p.atletas[time][i].position)
	return lugares


func _mover_ia(atleta: Node3D, alvo: Vector3, delta: float, fator := 1.0) -> void:
	if p._esta_no_chao(atleta):
		return
	var atual = Vector2(atleta.position.x, atleta.position.z)
	var novo = atual.move_toward(Vector2(alvo.x, alvo.z), p.VELOCIDADE_IA * fator * delta)
	atleta.position.x = novo.x
	atleta.position.z = novo.y
