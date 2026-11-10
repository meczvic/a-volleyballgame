extends SceneTree
## Testes das cartas do Modo Caos (regra pura).
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_cartas.gd

const Cartas := preload("res://scripts/regras/cartas.gd")
const Atributos := preload("res://scripts/regras/atributos.gd")
const Dados := preload("res://scripts/comum/dados.gd")

var falhas := 0


func _init() -> void:
	var dados := Dados.cartas()
	_teste_dados(dados)
	_teste_sorteio(dados)
	_teste_troca_de_lugar(dados)
	_teste_modificadores(dados)
	_teste_conjuntos(dados)
	_teste_atributos_com_cartas()
	_teste_quando_escolher(dados)

	if falhas == 0:
		print("OK: todos os testes das cartas passaram.")
	else:
		print("FALHOU: %d verificação(ões) das cartas." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_dados(dados: Dictionary) -> void:
	_verificar(Cartas.todas(dados).size() == 21, "cartas.json tem as 21 cartas")
	for id in Cartas.IMPLEMENTADAS:
		_verificar(not Cartas.por_id(dados, id).is_empty(), "%s existe em cartas.json" % id)
		if id != Cartas.ID_DA_TROCA:
			_verificar(Cartas.EFEITOS.has(id), "%s tem efeito" % id)
	for id in Cartas.EFEITOS:
		_verificar(Cartas.IMPLEMENTADAS.has(id), "%s tem efeito mas não está em IMPLEMENTADAS" % id)
	_verificar(Cartas.tempo_limite(dados) == 60.0, "tempo limite de 60 s")
	_verificar(Cartas.cartas_por_escolha(dados) == 3, "3 cartas por escolha")


func _teste_sorteio(dados: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for tentativa in 50:
		var mao := ["muro"]
		var sorteadas := Cartas.sortear(dados, mao, rng, 3)
		_verificar(sorteadas.size() == 3, "sorteia 3 cartas")
		var sem_repeticao := {}
		for id in sorteadas:
			sem_repeticao[id] = true
			_verificar(Cartas.IMPLEMENTADAS.has(id), "%s sorteada tem efeito" % id)
			_verificar(not mao.has(id), "não sorteia carta que já está na mão")
			_verificar(id != Cartas.ID_DA_TROCA, "sem carta do adversário, não sai Troca de Lugar")
		_verificar(sem_repeticao.size() == sorteadas.size(), "as 3 cartas são diferentes")

	# Mão quase cheia: sorteia só o que sobra.
	var quase_tudo := Cartas.disponiveis(dados, [], "muro")
	var quase_cheia: Array = quase_tudo.duplicate()
	quase_cheia.erase("maos_firmes")
	quase_cheia.erase("pes_leves")
	var resto := Cartas.sortear(dados, quase_cheia, rng, 3, "muro")
	_verificar(resto.size() == 2, "sobram só 2: sorteia 2 (%d)" % resto.size())
	_verificar(Cartas.sortear(dados, quase_tudo, rng, 3, "muro").is_empty(), "mão cheia: nada a sortear")

	# Raridade: com muitos sorteios, prata sai mais que ouro.
	var contagem := { "prata": 0, "ouro": 0, "prismatica": 0 }
	for tentativa in 400:
		for id in Cartas.sortear(dados, [], rng, 1, "muro"):
			contagem[str(Cartas.por_id(dados, id).get("raridade"))] += 1
	_verificar(contagem["prata"] > contagem["ouro"], "prata sai mais que ouro")


func _teste_troca_de_lugar(dados: Dictionary) -> void:
	_verificar(not Cartas.disponiveis(dados, [], "").has(Cartas.ID_DA_TROCA), "Troca não sai sem carta pra copiar")
	_verificar(Cartas.disponiveis(dados, [], "muro").has(Cartas.ID_DA_TROCA), "Troca sai se o adversário pegou carta")
	_verificar(not Cartas.disponiveis(dados, ["muro"], "muro").has(Cartas.ID_DA_TROCA), "Troca não copia carta que eu já tenho")
	var mao := Cartas.adicionar(["pes_leves"], Cartas.ID_DA_TROCA, "muro")
	_verificar(mao == ["pes_leves", "muro"], "Troca de Lugar vira cópia da carta do adversário")
	_verificar(not mao.has(Cartas.ID_DA_TROCA), "a Troca não fica na mão")
	_verificar(Cartas.adicionar(["pes_leves"], "muro") == ["pes_leves", "muro"], "carta comum entra na mão")
	_verificar(Cartas.adicionar(["muro"], "muro") == ["muro"], "carta repetida não entra duas vezes")


func _teste_modificadores(dados: Dictionary) -> void:
	_verificar(Cartas.modificadores(dados, []).is_empty(), "sem cartas, sem modificadores")
	var mods := Cartas.modificadores(dados, ["pes_leves"])
	_verificar(is_equal_approx(float(mods["velocidade"]), 1.15), "Pés Leves: 15% mais rápido")
	mods = Cartas.modificadores(dados, ["muro", "saque_firme"])
	_verificar(is_equal_approx(float(mods["largura_do_bloqueio"]), 1.3), "Muro: bloqueio mais largo")
	_verificar(is_equal_approx(float(mods["erro_do_saque"]), 0.8), "Saque Firme: erra menos")
	mods = Cartas.modificadores(dados, ["levantador_preciso", "ataque_rapido"])
	_verificar(float(mods["levantamento_perfeito"]) > 0.0 and float(mods["levantamento_rapido"]) > 0.0, "cartas do levantamento")


func _teste_conjuntos(dados: Dictionary) -> void:
	# Mãos Firmes + Tapete Vermelho são as duas de defesa: bônus "Recepção mais fácil".
	var mao := ["maos_firmes", "tapete_vermelho"]
	var contagem := Cartas.conjuntos(dados, mao)
	_verificar(int(contagem.get("defesa", 0)) == 2, "2 cartas de defesa")
	var mods := Cartas.modificadores(dados, mao)
	_verificar(is_equal_approx(float(mods["janela_passe"]), 1.2 * 1.1), "bônus de defesa soma com a carta")
	_verificar(Cartas.bonus_ativos(dados, mao).size() == 1, "um bônus de conjunto ativo")
	_verificar(Cartas.bonus_ativos(dados, ["maos_firmes"]).is_empty(), "uma carta só não dá bônus")
	# Levantador Preciso + Ataque Rápido: conjunto ataque, mais cortada forte.
	var ataque := Cartas.modificadores(dados, ["levantador_preciso", "ataque_rapido"])
	_verificar(is_equal_approx(float(ataque["forca_da_cortada"]), 0.08), "bônus de ataque deixa a cortada mais forte")


func _teste_atributos_com_cartas() -> void:
	var normal := { "atributos": { "ataque": 3, "defesa": 3, "saque": 3, "bloqueio": 3, "velocidade": 3 } }
	var com_cartas: Dictionary = normal.duplicate(true)
	com_cartas["modificadores"] = {
		"velocidade": 1.15, "janela_passe": 1.2, "erro_do_saque": 0.8, "largura_do_bloqueio": 1.3,
		"tempo_no_chao": 0.5, "forca_da_cortada": 0.08, "levantamento_perfeito": 1.0, "levantamento_rapido": 1.0,
	}
	_verificar(is_equal_approx(Atributos.velocidade(normal), 1.0), "sem cartas, velocidade normal")
	_verificar(is_equal_approx(Atributos.velocidade(com_cartas), 1.15), "carta de velocidade vale")
	_verificar(is_equal_approx(Atributos.escala_da_janela(com_cartas, "passe"), 1.2), "carta aumenta a janela do passe")
	_verificar(is_equal_approx(Atributos.escala_da_janela(com_cartas, "cortada"), 1.0), "a cortada não mudou")
	_verificar(is_equal_approx(Atributos.erro_do_saque(com_cartas), 0.8), "carta diminui o erro do saque")
	_verificar(is_equal_approx(Atributos.largura_do_bloqueio(com_cartas), 1.3), "carta alarga o bloqueio")
	_verificar(is_equal_approx(Atributos.escala_do_tempo_no_chao(com_cartas), 0.5), "carta encurta o tempo no chão")
	_verificar(is_equal_approx(Atributos.escala_do_tempo_no_chao(normal), 1.0), "sem carta, tempo no chão normal")
	_verificar(is_equal_approx(Atributos.cortada_mais_forte(com_cartas), 0.08), "carta deixa a cortada mais forte")
	_verificar(Atributos.levantamento_perfeito(com_cartas) and Atributos.levantamento_rapido(com_cartas), "cartas do levantamento")
	_verificar(not Atributos.levantamento_perfeito(normal) and not Atributos.levantamento_rapido(normal), "sem carta, sem levantamento fixo")
	# Atributo do time e carta se somam.
	var forte := { "atributos": { "velocidade": 5 }, "modificadores": { "velocidade": 1.15 } }
	_verificar(is_equal_approx(Atributos.velocidade(forte), 1.16 * 1.15), "atributo e carta se multiplicam")


func _teste_quando_escolher(dados: Dictionary) -> void:
	_verificar(not Cartas.deve_escolher(dados, 0), "não escolhe com 0 pontos")
	_verificar(not Cartas.deve_escolher(dados, 1) and not Cartas.deve_escolher(dados, 2), "não escolhe nos pontos 1 e 2")
	_verificar(Cartas.deve_escolher(dados, 3) and Cartas.deve_escolher(dados, 6), "escolhe a cada 3 pontos")
