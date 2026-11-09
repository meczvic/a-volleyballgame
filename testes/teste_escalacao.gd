extends SceneTree
## Testes da escalação pela função de cada atleta (sistema 5-1, sem líbero).
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_escalacao.gd

const Escalacao := preload("res://scripts/regras/escalacao.gd")
const Rodizio := preload("res://scripts/regras/rodizio.gd")

var falhas := 0


func _init() -> void:
	_teste_funcao_pelo_texto()
	_teste_elenco_completo()
	_teste_elenco_fora_de_ordem()
	_teste_quem_sobra_preenche_a_vaga()
	_teste_elenco_vazio()
	_teste_sempre_um_levantador_ou_oposto_na_rede()

	if falhas == 0:
		print("OK: todos os testes da escalação passaram.")
	else:
		print("FALHOU: %d verificação(ões) da escalação." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _atleta(posicao: String) -> Dictionary:
	return {"nome": posicao, "posicao": posicao}


func _teste_funcao_pelo_texto() -> void:
	_verificar(Escalacao.funcao_de(_atleta("Levantador")) == "levantador", "Levantador")
	_verificar(Escalacao.funcao_de(_atleta("ponteira")) == "ponteiro", "ponteira vira ponteiro")
	_verificar(Escalacao.funcao_de(_atleta("Central")) == "central", "Central")
	_verificar(Escalacao.funcao_de(_atleta("Oposta")) == "oposto", "Oposta vira oposto")
	_verificar(Escalacao.funcao_de(_atleta("Líbero")) == "", "líbero não é função de quadra")
	_verificar(Escalacao.funcao_de({}) == "", "sem posição")


func _teste_elenco_completo() -> void:
	var elenco := [
		_atleta("Levantador"), _atleta("Ponteiro"), _atleta("Central"),
		_atleta("Oposto"), _atleta("Ponteiro"), _atleta("Central"),
	]
	var ordem := Escalacao.ordem_inicial(elenco)
	_verificar(ordem == [0, 1, 2, 3, 4, 5], "elenco já na ordem do 5-1: %s" % [ordem])


func _teste_elenco_fora_de_ordem() -> void:
	# Lista com os 2 ponteiros e os 2 centrais juntos, o oposto no fim.
	var elenco := [
		_atleta("Levantador"), _atleta("Ponteiro"), _atleta("Ponteiro"),
		_atleta("Central"), _atleta("Central"), _atleta("Oposto"),
	]
	var ordem := Escalacao.ordem_inicial(elenco)
	_verificar(ordem == [0, 1, 3, 5, 2, 4], "levantador, ponteiro, central, oposto, ponteiro, central: %s" % [ordem])
	var funcoes := Escalacao.funcoes_por_atleta(ordem)
	_verificar(funcoes[5] == "oposto" and funcoes[0] == "levantador", "funções de cada atleta")

	# Levantador e oposto ficam sempre em lados opostos (3 posições de distância).
	var rodizio = Rodizio.new()
	rodizio.comecar_com(ordem)
	for _giro in 6:
		var distancia := absi(rodizio.posicao_de(0) - rodizio.posicao_de(5))
		_verificar(distancia == 3, "levantador oposto ao oposto")
		rodizio.girar()


func _teste_quem_sobra_preenche_a_vaga() -> void:
	# Sem oposto (ex.: tinha um líbero): quem sobrou joga na vaga de oposto.
	var elenco := [
		_atleta("Ponteiro"), _atleta("Levantador"), _atleta("Central"),
		_atleta("Líbero"), _atleta("Central"), _atleta("Ponteiro"),
	]
	var ordem := Escalacao.ordem_inicial(elenco)
	_verificar(ordem == [1, 0, 2, 3, 5, 4], "líbero vira oposto: %s" % [ordem])
	_verificar(_sem_repetir(ordem), "cada atleta numa vaga só")


func _teste_elenco_vazio() -> void:
	var ordem := Escalacao.ordem_inicial([])
	_verificar(ordem == [0, 1, 2, 3, 4, 5], "sem elenco: 0 a 5 na ordem")


func _teste_sempre_um_levantador_ou_oposto_na_rede() -> void:
	var rodizio = Rodizio.new()
	rodizio.comecar_com([0, 1, 2, 3, 4, 5])
	var funcoes := Escalacao.funcoes_por_atleta([0, 1, 2, 3, 4, 5])
	for _giro in 6:
		var na_rede := []
		for atleta in 6:
			if Rodizio.e_da_rede(rodizio.posicao_de(atleta)):
				na_rede.append(funcoes[atleta])
		_verificar(na_rede.has("central") and na_rede.has("ponteiro") \
			and (na_rede.has("levantador") or na_rede.has("oposto")),
			"na rede: 1 ponteiro, 1 central e o levantador ou o oposto (%s)" % [na_rede])
		rodizio.girar()


func _sem_repetir(ordem: Array) -> bool:
	var vistos := {}
	for indice in ordem:
		if vistos.has(indice):
			return false
		vistos[indice] = true
	return vistos.size() == 6
