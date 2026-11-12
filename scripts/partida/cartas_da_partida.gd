extends RefCounted
## Modo Caos dentro da partida: abre a tela de escolha, troca cartas e aplica o efeito delas nos times.
##
## Saiu do partida.gd (Fase C do plano de melhorias). "p" é a partida:
## tudo que é dela aparece como p.algo.

const Cartas := preload("res://scripts/regras/cartas.gd")
const Atributos := preload("res://scripts/regras/atributos.gd")
const EscolhaDeCartas := preload("res://scripts/partida/escolha_de_cartas.gd")

## A partida (partida.gd).
var p


func _init(partida) -> void:
	p = partida


## A tela de escolha está aberta? (Os botões do jogo ficam parados.)
func _escolhendo_cartas() -> bool:
	return p.escolha_de_cartas != null and is_instance_valid(p.escolha_de_cartas)


## Sorteia as cartas de cada jogador e abre a tela de escolha. Quando os dois
## escolhem, as cartas valem e "depois" é chamado (por exemplo, preparar o saque).
func _abrir_escolha_de_cartas(depois: Callable) -> void:
	var opcoes: Array = []
	var nomes_das_maos: Array = []
	for time in 2:
		var ids = Cartas.sortear(p.dados_das_cartas, p.cartas_dos_times[time], p.sorteio,
			Cartas.cartas_por_escolha(p.dados_das_cartas), p.ultima_carta[1 - time])
		var cartas: Array = []
		for id in ids:
			cartas.append(Cartas.por_id(p.dados_das_cartas, id))
		opcoes.append(cartas)
		nomes_das_maos.append(_nomes_das_cartas(time))
	# Sem carta nova pra oferecer (já pegaram todas): segue o jogo.
	if (opcoes[0] as Array).is_empty() or (opcoes[1] as Array).is_empty():
		if depois.is_valid():
			depois.call()
		return
	# Tira a mensagem do ponto da frente da tela de escolha.
	p.interface.limpar_mensagens()
	p.escolha_de_cartas = EscolhaDeCartas.new()
	p.escolha_de_cartas.name = "EscolhaDeCartas"
	p.escolha_de_cartas.sorteio = p.sorteio
	p.add_child(p.escolha_de_cartas)
	p.escolha_de_cartas.configurar(
		opcoes,
		[p.times_em_jogo[0]["nome"], p.times_em_jogo[1]["nome"]],
		[p._cor_do_time(0), p._cor_do_time(1)],
		p.cartas_dos_times, nomes_das_maos,
		Cartas.tempo_limite(p.dados_das_cartas),
		[str(p.times_em_jogo[0]["id"]), str(p.times_em_jogo[1]["id"])],
		p.times_em_jogo, p.trocas_restantes.duplicate(), _trocar_cartas)
	p.escolha_de_cartas.terminou.connect(func(escolhas: Array) -> void:
		p.escolha_de_cartas = null
		_ao_escolher_cartas(escolhas)
		if depois.is_valid():
			depois.call())


## Botão TROCAR da tela de cartas: gasta uma troca do time e sorteia outras
## cartas (tenta não repetir as que estavam na tela). Sem troca, devolve [].
func _trocar_cartas(time: int, atuais: Array) -> Array:
	if p.trocas_restantes[time] <= 0:
		return []
	var quantidade = Cartas.cartas_por_escolha(p.dados_das_cartas)
	var ids: Array = []
	for tentativa in 8:
		ids = Cartas.sortear(p.dados_das_cartas, p.cartas_dos_times[time], p.sorteio,
			quantidade, p.ultima_carta[1 - time])
		var repetidas = 0
		for id in ids:
			if atuais.has(id):
				repetidas += 1
		if repetidas < ids.size():
			break
	if ids.is_empty():
		return []
	p.trocas_restantes[time] -= 1
	var cartas: Array = []
	for id in ids:
		cartas.append(Cartas.por_id(p.dados_das_cartas, id))
	return cartas


## As duas cartas escolhidas entram na mão de cada time. As duas escolhas
## valem ao mesmo tempo (a Troca de Lugar copia a carta que o outro já tinha).
func _ao_escolher_cartas(escolhas: Array) -> void:
	var anteriores: Array = p.ultima_carta.duplicate()
	for time in 2:
		var id = str(escolhas[time])
		var mao_antes: Array = p.cartas_dos_times[time]
		p.cartas_dos_times[time] = Cartas.adicionar(mao_antes, id, str(anteriores[1 - time]))
		# A última carta é a que entrou na mão (a cópia, no caso da Troca de Lugar).
		if p.cartas_dos_times[time].size() > mao_antes.size():
			p.ultima_carta[time] = p.cartas_dos_times[time][p.cartas_dos_times[time].size() - 1]
			_dar_cargas(time, str(p.ultima_carta[time]))
	_aplicar_cartas()


## Cartas que valem por usos ou tempo (Saque Canhão, Muralha Total, Relâmpago,
## Defesa de Ferro): o time ganha a carga na hora que pega.
func _dar_cargas(time: int, id: String) -> void:
	var cargas: Dictionary = Cartas.CARGAS_AO_PEGAR.get(id, {})
	for chave in cargas:
		var dados_do_time: Dictionary = p.times_em_jogo[time]
		Atributos.mudar_carga(dados_do_time, chave, Atributos.carga(dados_do_time, chave) + float(cargas[chave]))
		if chave == "relampago":
			p.interface.mostrar_mensagem("Relâmpago!", time, false)


## Passa o efeito das cartas de cada time pro jogo (time["modificadores"]).
func _aplicar_cartas() -> void:
	for time in 2:
		p.times_em_jogo[time]["modificadores"] = Cartas.modificadores(p.dados_das_cartas, p.cartas_dos_times[time])
		if p.interface.rotulos_de_cartas.size() > time:
			var nomes = _nomes_das_cartas(time)
			var texto = ", ".join(PackedStringArray(nomes)) if not nomes.is_empty() else ""
			var bonus = Cartas.bonus_ativos(p.dados_das_cartas, p.cartas_dos_times[time])
			if not bonus.is_empty():
				texto += "\n" + " · ".join(PackedStringArray(bonus))
			p.interface.mostrar_cartas(time, texto)


func _nomes_das_cartas(time: int) -> Array:
	var nomes: Array = []
	for id in p.cartas_dos_times[time]:
		nomes.append(str(Cartas.por_id(p.dados_das_cartas, id).get("nome", id)))
	return nomes
