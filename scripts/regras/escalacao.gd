extends RefCounted
## Escalação: em que posição do rodízio cada atleta começa, pela função dele.
##
## Sistema 5-1 (um levantador), o mais usado no vôlei. Na ordem de saque
## (posições 1 a 6) fica:
##   1 levantador, 2 ponteiro, 3 central, 4 oposto, 5 ponteiro, 6 central.
## Assim o levantador fica sempre do lado oposto do oposto (3 posições de
## distância), os 2 ponteiros um oposto ao outro e os 2 centrais também.
## Sempre tem 1 levantador ou oposto, 1 ponteiro e 1 central na rede.
##
## Sem líbero: decisão do Victor (09/11/2026), 6 atletas por time.
## Quem estiver marcado como líbero no elenco joga na vaga que sobrar
## (normalmente a de oposto).

const ORDEM_DAS_FUNCOES := ["levantador", "ponteiro", "central", "oposto", "ponteiro", "central"]


## Função "limpa" a partir do texto do elenco ("Levantador", "central"...).
## Devolve "" se não for uma das 4 funções de quadra (por exemplo, "líbero").
static func funcao_de(dados_atleta: Dictionary) -> String:
	var texto := str(dados_atleta.get("posicao", "")).to_lower()
	if texto.begins_with("levant"):
		return "levantador"
	if texto.begins_with("ponteir"):
		return "ponteiro"
	if texto.begins_with("central"):
		return "central"
	if texto.begins_with("opost"):
		return "oposto"
	return ""


## Os 6 índices do elenco, um por posição do rodízio: ordem[0] começa na
## posição 1 (quem saca), ordem[1] na posição 2, e assim por diante.
## Elenco com menos de 6 (ou sem dados): completa com 0, 1, 2... na ordem.
static func ordem_inicial(elenco: Array) -> Array[int]:
	var ordem: Array[int] = [-1, -1, -1, -1, -1, -1]
	var usados := {}
	var quantos := mini(elenco.size(), 6)

	# 1ª passada: cada vaga pega o primeiro atleta livre com aquela função.
	for vaga in 6:
		for i in quantos:
			if usados.has(i):
				continue
			if funcao_de(elenco[i]) == ORDEM_DAS_FUNCOES[vaga]:
				ordem[vaga] = i
				usados[i] = true
				break

	# 2ª passada: vagas que sobraram ficam com quem sobrou, na ordem da lista.
	var proximo := 0
	for vaga in 6:
		if ordem[vaga] != -1:
			continue
		while usados.has(proximo):
			proximo += 1
		ordem[vaga] = proximo
		usados[proximo] = true
	return ordem


## Função de jogo de cada atleta (pelo índice do elenco), conforme a vaga
## que ele ocupa na escalação.
static func funcoes_por_atleta(ordem: Array) -> Dictionary:
	var funcoes := {}
	for vaga in ordem.size():
		funcoes[ordem[vaga]] = ORDEM_DAS_FUNCOES[vaga]
	return funcoes
