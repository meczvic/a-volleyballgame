extends SceneTree
## Testes dos atributos dos times.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_atributos.gd

const Atributos := preload("res://scripts/regras/atributos.gd")
const Dados := preload("res://scripts/comum/dados.gd")

var falhas := 0


func _init() -> void:
	var normal := {"atributos": {"ataque": 3, "defesa": 3, "saque": 3, "bloqueio": 3, "velocidade": 3}}
	var forte := {"atributos": {"ataque": 5, "defesa": 5, "saque": 5, "bloqueio": 5, "velocidade": 5}}
	var fraco := {"atributos": {"ataque": 1, "defesa": 1, "saque": 1, "bloqueio": 1, "velocidade": 1}}

	_verificar(is_equal_approx(Atributos.velocidade(normal), 1.0), "3 é o normal")
	_verificar(Atributos.nota({}, "ataque") == 3, "sem atributos, vale 3")
	_verificar(Atributos.velocidade(forte) > 1.0 and Atributos.velocidade(fraco) < 1.0, "velocidade")
	_verificar(Atributos.escala_da_janela(forte, "passe") > Atributos.escala_da_janela(fraco, "passe"), "defesa aumenta a janela do passe")
	_verificar(Atributos.escala_da_janela(forte, "cortada") > 1.0, "ataque aumenta a janela da cortada")
	_verificar(is_equal_approx(Atributos.escala_da_janela(forte, "levantamento"), 1.0), "levantamento não muda")
	_verificar(Atributos.alcance_extra_do_mergulho(forte) > 0.0, "defesa aumenta o mergulho")
	_verificar(Atributos.erro_do_saque(forte) < 1.0 and Atributos.erro_do_saque(fraco) > 1.0, "saque bom erra menos")
	_verificar(Atributos.largura_do_bloqueio(forte) > 1.0, "bloqueio alarga as mãos")
	_verificar(Atributos.cortada_mais_forte(forte) > 0.0, "ataque deixa a cortada mais reta")

	# Os times do jogo têm todos os atributos.
	for time in Dados.times():
		for nome in Atributos.NOMES:
			_verificar((time.get("atributos", {}) as Dictionary).has(nome), "%s tem %s" % [time.get("id"), nome])

	if falhas == 0:
		print("OK: todos os testes dos atributos passaram.")
	else:
		print("FALHOU: %d verificação(ões) dos atributos." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)
