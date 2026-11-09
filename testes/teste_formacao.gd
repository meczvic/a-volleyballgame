extends SceneTree
## Testes da formação no saque (regra da ordem do rodízio, FIVB 7.4).
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_formacao.gd

const Formacao := preload("res://scripts/regras/formacao.gd")

var falhas := 0


func _init() -> void:
	_teste_formacao_do_jogo_e_sempre_legal()
	_teste_detecta_quem_passa_na_frente()
	_teste_detecta_troca_de_lado()
	_teste_detecta_fora_da_quadra()
	_teste_quem_saca_nao_conta()
	_teste_limitar_mantem_a_ordem()
	_teste_lado_de_cada_funcao()

	if falhas == 0:
		print("OK: todos os testes da formação passaram.")
	else:
		print("FALHOU: %d verificação(ões) da formação." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


## Formação que o jogo monta, com o levantador na "posicao_do_levantador".
func _formacao(posicao_do_levantador: int, recebendo: bool) -> Dictionary:
	var lugares := {}
	for posicao in range(1, 7):
		lugares[posicao] = Formacao.lugar_no_saque(posicao, posicao == posicao_do_levantador, recebendo)
	return lugares


func _teste_formacao_do_jogo_e_sempre_legal() -> void:
	for levantador in range(1, 7):
		for recebendo in [true, false]:
			var lugares := _formacao(levantador, recebendo)
			var faltas := Formacao.faltas(lugares)
			_verificar(faltas.is_empty(), "levantador na %d, %s: %s" % [
				levantador, "recebendo" if recebendo else "sacando", faltas])


func _teste_detecta_quem_passa_na_frente() -> void:
	var lugares := _formacao(1, true)
	# O do meio do fundo (6) passa na frente do meio da rede (3).
	lugares[6] = Vector2(0.0, lugares[3].y - 0.5)
	_verificar(not Formacao.faltas(lugares).is_empty(), "6 na frente do 3 é falta")


func _teste_detecta_troca_de_lado() -> void:
	var lugares := _formacao(1, true)
	# O da esquerda da rede (4) vai pra direita do meio (3).
	lugares[4] = Vector2(lugares[3].x + 0.5, lugares[4].y)
	_verificar(not Formacao.faltas(lugares).is_empty(), "4 à direita do 3 é falta")


func _teste_detecta_fora_da_quadra() -> void:
	var lugares := _formacao(1, true)
	lugares[5] = Vector2(-3.0, 9.5)
	_verificar(not Formacao.faltas(lugares).is_empty(), "atrás da linha de fundo é falta")


func _teste_quem_saca_nao_conta() -> void:
	var lugares := _formacao(1, false)
	# Quem saca (posição 1) fica atrás da linha de fundo.
	lugares[1] = Vector2(2.5, 10.0)
	_verificar(not Formacao.faltas(lugares).is_empty(), "sem ignorar, o sacador conta")
	_verificar(Formacao.faltas(lugares, 1).is_empty(), "ignorando o sacador, está tudo certo")


func _teste_limitar_mantem_a_ordem() -> void:
	var desejos := [
		Vector2(-10.0, 0.0), Vector2(10.0, 20.0), Vector2(0.0, 0.0),
		Vector2(4.0, 1.0), Vector2(-4.0, 8.9), Vector2(0.0, 5.0),
	]
	for levantador in range(1, 7):
		for posicao in range(1, 7):
			for desejo in desejos:
				var lugares := _formacao(levantador, true)
				lugares[posicao] = Formacao.limitar(posicao, desejo, lugares)
				var faltas := Formacao.faltas(lugares)
				_verificar(faltas.is_empty(), "limitar a %d indo pra %s: %s" % [posicao, desejo, faltas])


func _teste_lado_de_cada_funcao() -> void:
	_verificar(Formacao.x_da_funcao("ponteiro", true) < 0.0, "ponteiro ataca pela esquerda")
	_verificar(Formacao.x_da_funcao("central", true) == 0.0, "central ataca pelo meio")
	_verificar(Formacao.x_da_funcao("oposto", true) > 0.0, "oposto ataca pela direita")
	_verificar(Formacao.x_da_funcao("ponteiro", false) == 0.0, "no fundo, o ponteiro passa no meio")
