extends RefCounted
## Lances com a bola: passe, levantamento, cortada (do pulo à batida), largada e mergulho.
##
## Saiu do partida.gd (Fase C do plano de melhorias). "p" é a partida:
## tudo que é dela aparece como p.algo.

const Atributos := preload("res://scripts/regras/atributos.gd")
const Energia := preload("res://scripts/regras/energia.gd")
const EscolhaAtaque := preload("res://scripts/regras/escolha_ataque.gd")
const Estouro := preload("res://scripts/visual/estouro.gd")
const JeitosDeAtacar := preload("res://scripts/regras/jeitos_de_atacar.gd")
const JeitosDeDefender := preload("res://scripts/regras/jeitos_de_defender.gd")
const TempoDoToque := preload("res://scripts/regras/tempo_do_toque.gd")
const VelocidadeDaBola := preload("res://scripts/regras/velocidade_da_bola.gd")

const Lance := preload("res://scripts/regras/lance.gd")

## A partida (partida.gd).
var p


func _init(partida) -> void:
	p = partida


## Passe (atacando = false) ou ataque (atacando = true) do atleta controlado.
## Devolve false se a bola estava fora do alcance (o botão não valeu).
func _tentar_tocar(time: int, atacando: bool, mergulho := false) -> bool:
	var alcancou: bool
	if mergulho:
		alcancou = true
	elif atacando:
		alcancou = p._alcanca_bola(time, p.ALTURA_MINIMA_CORTADA, p.ALTURA_MAXIMA_CORTADA)
	else:
		alcancou = p._alcanca_bola(time, 0.0, p.ALTURA_MAXIMA_PASSE)
	if not alcancou:
		return false
	# Cortada perfeita fora da linha do corpo: o toque não vale e a bola passa.
	if not atacando and not mergulho and p.ultimo_toque != time \
			and not JeitosDeDefender.segura_cortada(p._forca_da_cortada, p._distancia_no_chao(p.controlados[time], p.bola.position)):
		return false
	if p.saque_em_jogo and time == p.placar.quem_saca:
		# Quem sacou não pode tocar no próprio saque: o toque é ignorado.
		# (Se a bola não passar a rede, ela cai do lado de quem sacou e é ponto do outro.)
		return true

	var falta = p._falta_no_toque(time, atacando)
	if falta != "":
		p._encerrar_rally(1 - time, falta)
		return true
	if not p.toques.registrar(time, p.atletas[time].find(p.controlados[time])):
		p._encerrar_rally(1 - time, "4 toques")
		return true
	if time != p.placar.quem_saca:
		p.saque_em_jogo = false
	p.ultimo_toque = time
	p._ponto_de_bloqueio = -1
	p._bloqueio_do_ataque = 1.0
	p._ataque_atravessa = false
	var cortada_recebida = p._forca_da_cortada
	p._forca_da_cortada = -1
	p._mostrar_marcas_de_ataque(-1)

	var numero: int = p.toques.toques
	var tipo = p._tipo_do_toque(numero, atacando)
	var qualidade = p._qualidade_do_toque(tipo, time)
	var atleta_que_tocou = p.controlados[time]
	if atacando and atleta_que_tocou.has_meta("qualidade_da_cortada"):
		qualidade = atleta_que_tocou.get_meta("qualidade_da_cortada")
		atleta_que_tocou.remove_meta("qualidade_da_cortada")
		# O tempo da cortada vale no botão: o aviso usa o erro de lá.
		atleta_que_tocou.set_meta("erro_do_toque", atleta_que_tocou.get_meta("erro_da_cortada", 0.0))
		atleta_que_tocou.remove_meta("erro_da_cortada")
	if mergulho:
		# Mergulho: no máximo "bom"; de longe (fora do alcance normal), ruim.
		var longe = p._distancia_no_chao(atleta_que_tocou, p.bola.position) > p.ALCANCE
		qualidade = JeitosDeDefender.qualidade_do_mergulho(qualidade, longe)
	if numero == 1 and not atacando:
		# Cortada perfeita do outro time: passe só bom foge e sai ruim.
		var antes = qualidade
		qualidade = JeitosDeDefender.qualidade_da_recepcao(qualidade, cortada_recebida)
		if qualidade != antes:
			p.interface.mostrar_mensagem("Cortada forte!", time, false)
	if numero == 1 and not atacando:
		if p._saque_canhao:
			# Saque Canhão (Modo Caos): a recepção desse saque sai ruim.
			p._saque_canhao = false
			qualidade = TempoDoToque.Qualidade.RUIM
		elif cortada_recebida >= 0 and qualidade != TempoDoToque.Qualidade.RUIM \
				and Atributos.tem(p.times_em_jogo[time], "contra_ataque"):
			# Contra-Ataque (Modo Caos): defendeu a cortada, o próximo ataque sai mais forte.
			Atributos.mudar_carga(p.times_em_jogo[time], "contra_ataque", 1.0)
			p.interface.mostrar_mensagem("Contra-ataque!", time, false)
	if atacando or numero <= 2:
		p._avisar_qualidade(p.controlados[time], qualidade)
	# Energia do toque (a cortada soma depois de sair, pra não gastar o que acabou de ganhar).
	var ganho = 0.0
	if mergulho:
		ganho = Energia.ajuste("ganho_do_mergulho", Energia.GANHO_DO_MERGULHO) if qualidade != TempoDoToque.Qualidade.RUIM else 0.0
	elif atacando:
		ganho = Energia.ganho_do_toque(Lance.CORTADA, qualidade) if numero != 2 and not atleta_que_tocou.get_meta("largada", false) else 0.0
	elif numero == 1:
		ganho = Energia.ganho_do_toque(Lance.PASSE, qualidade)
	elif numero == 2:
		ganho = Energia.ganho_do_toque(Lance.LEVANTAMENTO, qualidade)
	if atacando:
		_cortar(time, qualidade)
	elif numero == 1:
		_passar_pro_levantador(time, qualidade)
	elif numero == 2:
		_levantar(time, qualidade)
	else:
		p._devolver_de_graca(time)
	p._ganhar_energia(time, ganho)
	return true


## 1º toque. A qualidade decide o quanto a bola erra o levantador e o que
## ele vai poder levantar.
func _passar_pro_levantador(time: int, qualidade: TempoDoToque.Qualidade) -> void:
	p._animar(p.controlados[time], "manchete")
	p.sons.tocar("passe", p._intensidade_do_som(qualidade))
	p._peso_do_toque(time, p.bola.position, p._forca_da_qualidade(qualidade, 0.7, 0.3))
	p.qualidade_do_passe[time] = qualidade
	p._ultimo_levantamento[time] = {}
	var erro = p._erro_aleatorio(TempoDoToque.ERRO_DO_PASSE[qualidade])
	# O passe nunca passa da rede nem sai pela lateral.
	var lugar = p.PONTO_DO_LEVANTADOR + erro
	lugar.x = clampf(lugar.x, -p.LARGURA / 2.0 + 0.5, p.LARGURA / 2.0 - 0.5)
	lugar.y = maxf(lugar.y, 0.6)
	p.bola.lancar(p._no_mundo(time, lugar), TempoDoToque.ALTURA_DO_PASSE[qualidade], VelocidadeDaBola.gravidade(VelocidadeDaBola.do_passe()))
	p._ao_lancar_bola()
	p._mostrar_marcas_de_ataque(time)


## 2º toque. Passe ruim só deixa levantar alto (ponta ou fundo); passe e
## levantamento perfeitos dão o levantamento rápido, que chega antes do bloqueio.
func _levantar(time: int, qualidade: TempoDoToque.Qualidade) -> void:
	p._animar(p.controlados[time], "levantamento")
	p.sons.tocar("levantamento", p._intensidade_do_som(qualidade))
	p._peso_do_toque(time, p.bola.position, p._forca_da_qualidade(qualidade, 0.5, 0.2))
	var passe: TempoDoToque.Qualidade = p.qualidade_do_passe[time]
	var escolhido = _ataque_escolhido(time, passe)
	var altura = TempoDoToque.altura_do_levantamento(passe, qualidade)
	# Altura escolhida segurando o passe (13/11/2026): alta ou normal valem
	# como pedidas; a rápida passa pela regra de baixo. Passe ruim só deixa a alta.
	var pedida: float = p.altura_pedida[time]
	p.altura_pedida[time] = -1.0
	var pediu_rapida := is_equal_approx(pedida, TempoDoToque.ALTURA_DO_LEVANTAMENTO_RAPIDO)
	if pedida > 0.0 and passe != TempoDoToque.Qualidade.RUIM and not pediu_rapida:
		altura = pedida
	if Atributos.levantamento_rapido(p.times_em_jogo[time]):
		altura = TempoDoToque.ALTURA_DO_LEVANTAMENTO_RAPIDO
	# Rápida (toque curto no passe, ou segurando o flutuante): sai mesmo com
	# passe só "bom". Passe ou levantamento ruim não deixam. Se não forem
	# perfeitos, o atacante recebe a bola com mais erro.
	var raio: float = TempoDoToque.ERRO_DO_LEVANTAMENTO[qualidade]
	var quer_rapido: bool = p._segurando_botao[time].get(Lance.BOTAO_FLUTUANTE, false) \
		or pediu_rapida
	if quer_rapido and altura != TempoDoToque.ALTURA_DO_LEVANTAMENTO_RAPIDO \
			and passe != TempoDoToque.Qualidade.RUIM and qualidade != TempoDoToque.Qualidade.RUIM:
		altura = TempoDoToque.ALTURA_DO_LEVANTAMENTO_RAPIDO
		if passe != TempoDoToque.Qualidade.PERFEITO or qualidade != TempoDoToque.Qualidade.PERFEITO:
			raio *= JeitosDeAtacar.valor("erro_do_rapido_forcado", JeitosDeAtacar.ERRO_DO_RAPIDO_FORCADO)
	var erro = p._erro_aleatorio(raio)
	var alvo: Vector3 = p.alvos_de_ataque[time][escolhido] + Vector3(erro.x, 0.0, erro.y)
	p.bola.lancar(alvo, altura, VelocidadeDaBola.gravidade(VelocidadeDaBola.do_levantamento()))
	p._ao_lancar_bola()
	var nome: String = p.ATAQUES[escolhido]["nome"]
	var rapido: bool = altura == TempoDoToque.ALTURA_DO_LEVANTAMENTO_RAPIDO
	p._ultimo_levantamento[time] = { "nome": nome, "rapido": rapido }
	# Só o levantamento rápido merece texto: o resto o jogador já vê pela bola.
	if rapido:
		p.interface.mostrar_mensagem("Rápido: %s" % nome, time, false)


## Pra onde o levantador manda: a direção apertada, só entre os ataques que
## o passe deixou. Sem direção, o meio (ou a ponta, se o meio não der).
func _ataque_escolhido(time: int, passe: TempoDoToque.Qualidade) -> int:
	var liberados: Array[int] = []
	var alvos: Array = []
	for i in p.ATAQUES.size():
		if TempoDoToque.ataque_liberado(passe, p.ATAQUES[i]["nome"]):
			liberados.append(i)
			alvos.append(p.alvos_de_ataque[time][i])
	var padrao = liberados.find(p.ATAQUE_PADRAO)
	if padrao < 0:
		padrao = 0
	var escolhido = EscolhaAtaque.escolher(alvos, p._direcao_no_mundo(time), padrao)
	return liberados[escolhido]


## Ataque apertado: se a bola vai estar ao alcance no alto do pulo, o atleta
## sai do chão agora e bate nela daqui a TEMPO_ATE_A_BATIDA (_atualizar_cortada).
## As regras (faltas, toques) são conferidas na batida, por _tentar_tocar.
## Devolve false se a bola não vai estar ao alcance (o botão não valeu).
func _comecar_cortada(time: int) -> bool:
	var atleta = p.controlados[time]
	if not p.cortadas[time].is_empty() or p.bloqueios._esta_pulando(atleta) or not p.bola.em_voo:
		return false
	var prevista: Vector3 = p.bola.posicao_daqui_a(p.TEMPO_ATE_A_BATIDA)
	var no_chao = Vector2(prevista.x - atleta.position.x, prevista.z - atleta.position.z)
	if no_chao.length() > p.ALCANCE or prevista.y < p.ALTURA_MINIMA_CORTADA or prevista.y > p.ALTURA_MAXIMA_CORTADA:
		return false
	# Na regra do ataque do fundo vale de onde o atleta saiu do chão.
	atleta.set_meta("saiu_do_chao_em", atleta.position)
	# Pula o bastante pra mão (na pose da batida) chegar na altura da bola.
	var mao_acima_dos_pes = p.ALTURA_DAS_MAOS
	var animador = p._animador_de(atleta)
	if animador:
		mao_acima_dos_pes = animador.altura_da_mao_na_batida()
	p.bloqueios._pular(atleta, clampf(prevista.y - mao_acima_dos_pes, p.PULO_MINIMO_DA_CORTADA, p.PULO_MAXIMO_DA_CORTADA))
	p._animar(atleta, "cortada")
	# O tempo da cortada vale no botão: a batida vem TEMPO_ATE_A_BATIDA depois.
	atleta.set_meta("qualidade_da_cortada", p._qualidade_do_toque(Lance.CORTADA, time))
	atleta.set_meta("erro_da_cortada", atleta.get_meta("erro_do_toque", 0.0))
	p.cortadas[time] = {
		"atleta": atleta, "tempo": 0.0,
		"de": Vector2(atleta.position.x, atleta.position.z),
	}
	return true


func _atualizar_cortada(time: int, delta: float) -> void:
	var cortada: Dictionary = p.cortadas[time]
	var atleta: Node3D = cortada["atleta"]
	cortada["tempo"] += delta
	# No ar, o atleta vai pra onde a mão encontra a bola na batida (sem a mão,
	# pra baixo da bola). Sem chegar mais perto da rede do que pode.
	var falta: float = maxf(p.TEMPO_ATE_A_BATIDA - cortada["tempo"], 0.0)
	var prevista: Vector3 = p.bola.posicao_daqui_a(falta)
	var alvo = Vector2(prevista.x, prevista.z)
	var mao_agora = _posicao_da_mao(atleta)
	if mao_agora != null:
		alvo -= Vector2((mao_agora as Vector3).x - atleta.position.x, (mao_agora as Vector3).z - atleta.position.z)
	alvo.y = p._lado(time) * maxf(alvo.y * p._lado(time), p.DISTANCIA_MINIMA_DA_REDE + 0.05)
	var fracao = smoothstep(0.0, p.TEMPO_ATE_A_BATIDA, cortada["tempo"])
	var ponto: Vector2 = (cortada["de"] as Vector2).lerp(alvo, fracao)
	atleta.position.x = ponto.x
	atleta.position.z = ponto.y
	if p.estado != p.Estado.RALLY or not p.bola.em_voo or p.controlados[time] != atleta:
		_terminar_cortada(time, atleta)
		atleta.remove_meta("qualidade_da_cortada")
		return
	if cortada["tempo"] < p.TEMPO_ATE_A_BATIDA:
		# Chegando na batida, a bola vai encostando na mão.
		var mao = _mao_perto_da_bola(atleta, p.TEMPO_ATE_A_BATIDA - cortada["tempo"])
		if mao != null:
			var peso = smoothstep(p.TEMPO_ATE_A_BATIDA - p.IMA_DA_MAO, p.TEMPO_ATE_A_BATIDA, cortada["tempo"])
			p.bola.puxar_para(mao, peso)
		return
	p.cortadas[time] = {}
	_bater_na_bola(time, atleta)
	_terminar_cortada(time, atleta)


## Fim da cortada (com ou sem batida): solta a bola do ímã e limpa as marcas do atleta.
func _terminar_cortada(time: int, atleta: Node3D) -> void:
	p.cortadas[time] = {}
	p.bola.puxar_para(Vector3.ZERO, 0.0)
	atleta.remove_meta("saiu_do_chao_em")
	atleta.remove_meta("largada")


## Posição da mão da cortada, se ela vai estar perto da bola daqui a
## "segundos" (null se longe ou se o atleta não tem personagem).
func _mao_perto_da_bola(atleta: Node3D, segundos: float):
	var mao = _posicao_da_mao(atleta)
	if mao == null or (mao as Vector3).distance_to(p.bola.posicao_daqui_a(segundos)) > p.ALCANCE_DA_MAO:
		return null
	return mao


## Onde está a mão da cortada do personagem (null sem personagem).
func _posicao_da_mao(atleta: Node3D):
	var animador = p._animador_de(atleta)
	return animador.posicao_da_mao() if animador else null


## Batida da cortada, no alto do pulo: a bola vai pra mão (se a mão chegou
## perto) e sai de lá. Se a cortada não valer, a bola segue o caminho dela.
func _bater_na_bola(time: int, atleta: Node3D) -> void:
	var antes: Vector3 = p.bola.position
	var lancamentos: int = p.bola.lancamentos
	var mao = _mao_perto_da_bola(atleta, 0.0)
	if mao != null:
		p.bola.position = mao
	_tentar_tocar(time, true)
	if p.bola.lancamentos == lancamentos:
		p.bola.position = antes


## Cortada, na batida (alto do pulo). A qualidade, medida no botão, decide
## a força (quanto a bola sobe), o erro da mira e a profundidade.
## Cortada ruim sai fraca e torta.
func _cortar(time: int, qualidade: TempoDoToque.Qualidade = TempoDoToque.Qualidade.BOM) -> void:
	if p.toques.toques == 2:
		# Atacar no 2º toque: bola de segunda, o levantador empurra a bola.
		_largar(time, qualidade, "Bola de segunda!")
		return
	if p.controlados[time].get_meta("largada", false):
		_largar(time, qualidade)
		return
	var jeito: Dictionary = TempoDoToque.CORTADA[qualidade]
	# A direção mira: esquerda/direita, e pra frente (funda) ou pra trás (curta).
	var alvo = p._alvo_da_cortada(time)
	alvo.y = clampf(alvo.y, jeito["fundo_min"], jeito["fundo_max"])
	# Jeito do ataque: rápido do meio, pipe, diagonal ou paralela.
	var levantamento: Dictionary = p._ultimo_levantamento[time]
	p._ultimo_levantamento[time] = {}
	var efeito = JeitosDeAtacar.efeito(
		levantamento.get("nome", ""), levantamento.get("rapido", false),
		JeitosDeAtacar.jeito_da_mira(p.controlados[time].position.x, alvo.x))
	# Energia cheia e cortada que não saiu ruim: SUPER CORTADA.
	var super_cortada: bool = p.energias[time].cheia() and qualidade != TempoDoToque.Qualidade.RUIM
	var dados_do_time: Dictionary = p.times_em_jogo[time]
	# Diagonal Mortal (Modo Caos): a diagonal abre mais o ângulo e o bloqueio pega menos.
	if Atributos.tem(dados_do_time, "diagonal_mortal") \
			and JeitosDeAtacar.jeito_da_mira(p.controlados[time].position.x, alvo.x) == "diagonal":
		alvo.x = clampf(alvo.x + signf(alvo.x) * 0.9, -p.LARGURA / 2.0 + 0.3, p.LARGURA / 2.0 - 0.3)
		efeito["bloqueio"] = float(efeito["bloqueio"]) * 0.85
		efeito["nome"] = "Diagonal Mortal!"
	# Contra-Ataque (Modo Caos): depois de defender uma cortada, este ataque sai mais forte.
	var contra_ataque := Atributos.carga(dados_do_time, "contra_ataque") >= 1.0 and qualidade != TempoDoToque.Qualidade.RUIM
	Atributos.mudar_carga(dados_do_time, "contra_ataque", 0.0)
	if contra_ataque:
		efeito["bloqueio"] = float(efeito["bloqueio"]) * 0.85
		efeito["subida_a_menos"] = float(efeito["subida_a_menos"]) + 0.12
	var erro_da_mira = maxf(float(jeito["erro_da_mira"]) + float(efeito["erro_a_mais"]), 0.1)
	if super_cortada:
		erro_da_mira = minf(erro_da_mira, Energia.ajuste("erro_da_super", Energia.ERRO_DA_SUPER))
	var destino = p._destino_na_quadra_do_outro(time, alvo, erro_da_mira)
	p.miras[time].esconder()
	var subida = maxf(float(jeito["subida"]) - Atributos.cortada_mais_forte(p.times_em_jogo[time]) - float(efeito["subida_a_menos"]), 0.05)
	if super_cortada:
		subida = minf(subida, Energia.ajuste("subida_da_super", Energia.SUBIDA_DA_SUPER))
	if qualidade != TempoDoToque.Qualidade.RUIM:
		# Cortada ruim não aproveita o jeito: o bloqueio pega normal.
		p._bloqueio_do_ataque = float(efeito["bloqueio"])
		if super_cortada:
			p._bloqueio_do_ataque = minf(p._bloqueio_do_ataque, Energia.ajuste("bloqueio_da_super", Energia.BLOQUEIO_DA_SUPER))
		if efeito["nome"] != "":
			p.interface.mostrar_mensagem(efeito["nome"], time, false)
		if qualidade == TempoDoToque.Qualidade.PERFEITO and Atributos.tem(dados_do_time, "cortada_sinistra"):
			# Cortada Sinistra (Modo Caos): a cortada perfeita atravessa o bloqueio.
			p._ataque_atravessa = true
			p.interface.mostrar_mensagem("Cortada Sinistra!", time, false)
	var ponto_da_batida: Vector3 = p.bola.position
	p._forca_da_cortada = int(TempoDoToque.Qualidade.PERFEITO) if super_cortada else int(qualidade)
	# A cortada sai em linha reta, pra baixo, direto no destino. Só cai no arco
	# se a reta bateria na rede (ataque curto) ou se a cortada saiu ruim.
	var reta := VelocidadeDaBola.da_cortada_reta(qualidade, super_cortada)
	if reta <= 0.0 or not p.bola.lancar_reto(destino, reta):
		p.bola.lancar(destino, p.bola.position.y + subida, VelocidadeDaBola.gravidade(VelocidadeDaBola.da_cortada(qualidade, super_cortada)))
	p._ao_lancar_bola()
	# Muralha Total (Modo Caos) do outro time: este ataque gasta um uso.
	if Atributos.gastar_carga(p.times_em_jogo[1 - time], "muralha_total"):
		p.interface.mostrar_mensagem("Muralha!", 1 - time, false)
	if qualidade != TempoDoToque.Qualidade.RUIM and Atributos.tem(dados_do_time, "bola_fantasma"):
		_bola_fantasma()
	p.sons.tocar("cortada", p._intensidade_do_som(qualidade))
	p.bola.amassar(1.0 if super_cortada else p._forca_da_qualidade(qualidade, 1.0, 0.7))
	if super_cortada:
		p.energias[time].gastar()
		p._atualizar_barra_de_energia(time)
		p.sons.tocar("super")
		p.impacto.cortada(true)
		Estouro.mostrar(p, ponto_da_batida, p.COR_DA_SUPER_CORTADA, 1.6)
		p.rastro.destacar(p.COR_DA_SUPER_CORTADA)
		p.interface.mostrar_mensagem("SUPER CORTADA!", time, false)
	elif qualidade != TempoDoToque.Qualidade.RUIM:
		var perfeita = qualidade == TempoDoToque.Qualidade.PERFEITO
		p.impacto.cortada(perfeita)
		Estouro.mostrar(p, ponto_da_batida, p.COR_DA_CORTADA_PERFEITA if perfeita else Color(1.0, 1.0, 1.0), 1.0 if perfeita else 0.45)
		if perfeita:
			p.rastro.destacar(p.COR_DA_CORTADA_PERFEITA)


## Bola Fantasma (Modo Caos): a marca de onde a bola vai cair some por um
## instante logo depois da cortada.
func _bola_fantasma() -> void:
	p.marcador.esconder()
	if not p.is_inside_tree():
		return
	await p.get_tree().create_timer(0.6, false).timeout
	if is_instance_valid(p) and p.bola.em_voo and p.estado == p.Estado.RALLY:
		p.marcador.mostrar_em(p.bola.ponto_previsto)


## Largada: bola curta, devagar e por cima do bloqueio. A direção mira o lado
## (esquerda/direita); a qualidade (tempo do botão) só muda o erro.
func _largar(time: int, qualidade: TempoDoToque.Qualidade, mensagem := "Largada!") -> void:
	var alvo = p._alvo_da_cortada(time)
	alvo.y = (p.LARGADA_FUNDO_MIN + p.LARGADA_FUNDO_MAX) / 2.0
	var destino = p._destino_na_quadra_do_outro(time, alvo, p.ERRO_DA_LARGADA[qualidade], p.LARGADA_FUNDO_MIN, p.LARGADA_FUNDO_MAX)
	p.miras[time].esconder()
	p.bola.lancar(destino, p.bola.position.y + p.SUBIDA_DA_LARGADA)
	p._ao_lancar_bola()
	p.sons.tocar("levantamento", 0.6)
	p.interface.mostrar_mensagem(mensagem, time, false)


## Mergulho do atleta controlado: se a bola está baixa e ao alcance do
## mergulho, ele se joga e toca (bola pior). Se não, se joga no vazio.
## Nos dois casos fica no chão TEMPO_NO_CHAO segundos.
func _mergulhar(time: int) -> void:
	var atleta = p.controlados[time]
	if atleta == null or p._esta_no_chao(atleta) or p.bloqueios._esta_pulando(atleta):
		return
	# Mergulho no tempo alcança mais longe; fora do tempo (ou no vazio) deixa
	# mais tempo no chão.
	var tempo_do_botao = TempoDoToque.Qualidade.RUIM
	if p.bola.em_voo:
		tempo_do_botao = p._qualidade_do_toque(Lance.PASSE, time)
	var alcance = p.ALCANCE_DO_MERGULHO + Atributos.alcance_extra_do_mergulho(p.times_em_jogo[time]) \
		+ JeitosDeDefender.alcance_a_mais(tempo_do_botao)
	var ate_a_bola = Vector2(p.bola.position.x - atleta.position.x, p.bola.position.z - atleta.position.z)
	var alcanca: bool = p.bola.em_voo and p.bola.position.y <= p.ALTURA_MAXIMA_DO_MERGULHO \
		and ate_a_bola.length() <= alcance
	var tempo_no_chao = p.TEMPO_NO_CHAO * Atributos.escala_do_tempo_no_chao(p.times_em_jogo[time])
	atleta.set_meta("no_chao_ate", p._relogio + JeitosDeDefender.tempo_no_chao_do_mergulho(tempo_no_chao, tempo_do_botao, alcanca))
	p.sons.tocar("mergulho")
	if alcanca:
		_tentar_tocar(time, false, true)
		# Se joga até perto da bola. A animação vem depois do toque, pra
		# manchete do passe não tomar o lugar do mergulho.
		var passo = ate_a_bola.limit_length(maxf(ate_a_bola.length() - 0.5, 0.0))
		_deslocar(atleta, time, passo)
		_animar_mergulho(atleta, ate_a_bola)
		return
	var rumo = ate_a_bola.normalized() if p.bola.em_voo else p._direcao_no_mundo(time).normalized()
	_deslocar(atleta, time, rumo * p.MERGULHO_NO_VAZIO)
	_animar_mergulho(atleta, rumo)


## Mergulho pro lado do "rumo" (esquerda ou direita de quem mergulha).
func _animar_mergulho(atleta: Node3D, rumo: Vector2) -> void:
	p.online.ao_mergulhar(atleta, rumo)
	var animador = p._animador_de(atleta)
	if animador:
		animador.mergulhar(rumo)


## Move o atleta "passo" metros no chão, sem passar da rede nem sair da área.
func _deslocar(atleta: Node3D, time: int, passo: Vector2) -> void:
	atleta.position += Vector3(passo.x, 0.0, passo.y)
	p.ia._mover(atleta, time, Vector2.ZERO, 0.0)
