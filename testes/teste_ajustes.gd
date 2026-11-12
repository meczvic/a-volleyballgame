extends SceneTree
## Testes de dados/ajustes.json (Etapa 5 do plano de jogabilidade):
## - o arquivo bate com os valores padrão que estão no código (não se perde);
## - mudar um número no JSON muda o jogo;
## - sem arquivo ou sem a chave, vale o padrão do código.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://testes/teste_ajustes.gd

const Ajustes := preload("res://scripts/comum/ajustes.gd")
const Atacar := preload("res://scripts/regras/jeitos_de_atacar.gd")
const Defender := preload("res://scripts/regras/jeitos_de_defender.gd")
const Energia := preload("res://scripts/regras/energia.gd")

var falhas := 0


func _initialize() -> void:
	process_frame.connect(_rodar, CONNECT_ONE_SHOT)


func _rodar() -> void:
	_teste_arquivo_bate_com_o_codigo()
	_teste_mudar_o_json_muda_o_jogo()
	_teste_padrao_sem_chave()
	Ajustes.recarregar()

	if falhas == 0:
		print("OK: todos os testes dos ajustes passaram.")
	else:
		print("FALHOU: %d verificação(ões) dos ajustes." % falhas)
	quit(1 if falhas > 0 else 0)


func _verificar(condicao: bool, mensagem: String) -> void:
	if not condicao:
		falhas += 1
		print("  falha: " + mensagem)


func _teste_arquivo_bate_com_o_codigo() -> void:
	Ajustes.recarregar()
	var dados = JSON.parse_string(FileAccess.get_file_as_string(Ajustes.ARQUIVO))
	_verificar(dados is Dictionary, "dados/ajustes.json existe e é um JSON válido")
	if not dados is Dictionary:
		return
	var grupos := { "ataques": Atacar, "defesa": Defender, "energia": Energia }
	for grupo in grupos:
		var constantes: Dictionary = grupos[grupo].get_script_constant_map()
		var do_grupo: Dictionary = dados.get(grupo, {})
		_verificar(not do_grupo.is_empty(), "o grupo \"%s\" tem números" % grupo)
		for chave in do_grupo:
			var nome := str(chave).to_upper()
			_verificar(constantes.has(nome), "\"%s.%s\" existe no código" % [grupo, chave])
			if constantes.has(nome):
				_verificar(is_equal_approx(float(do_grupo[chave]), float(constantes[nome])),
					"\"%s.%s\" no JSON (%s) é igual ao padrão do código (%s)" % [grupo, chave, do_grupo[chave], constantes[nome]])


func _teste_mudar_o_json_muda_o_jogo() -> void:
	Ajustes.usar_dados({ "ataques": { "bloqueio_do_pipe": 0.1 }, "energia": { "ganho_do_ponto": 0.5 }, "defesa": { "risco_do_mergulho": 3.0 } })
	_verificar(is_equal_approx(Atacar.efeito("Fundo", false, "")["bloqueio"], 0.1), "o bloqueio do pipe vem do JSON")
	_verificar(is_equal_approx(Energia.ajuste("ganho_do_ponto", Energia.GANHO_DO_PONTO), 0.5), "o ganho do ponto vem do JSON")
	_verificar(is_equal_approx(Defender.tempo_no_chao_do_mergulho(1.0, Energia.Qualidade.RUIM, true), 3.0), "o risco do mergulho vem do JSON")


func _teste_padrao_sem_chave() -> void:
	Ajustes.usar_dados({})
	_verificar(is_equal_approx(Atacar.efeito("Fundo", false, "")["bloqueio"], Atacar.BLOQUEIO_DO_PIPE), "sem dados, vale o padrão do código")
	Ajustes.usar_dados({ "ataques": { "bloqueio_do_pipe": "texto" } })
	_verificar(is_equal_approx(Atacar.efeito("Fundo", false, "")["bloqueio"], Atacar.BLOQUEIO_DO_PIPE), "valor que não é número cai no padrão")
