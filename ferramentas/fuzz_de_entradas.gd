extends SceneTree
## Teste adversarial (QA de 24/11/2026): aperta botões ao acaso e ao mesmo tempo, pausa e recarrega a partida, e confere bola/atletas (NaN, fora da quadra) e estado parado.
##   godot --headless --fixed-fps 60 --path . --script res://ferramentas/fuzz_de_entradas.gd -- seg=150 modo=caos|tudo|segurar sem=1
## modo=caos: botões do J1 ao acaso; tudo: J1 e J2; segurar: todos os botões do J1 apertados o tempo todo.
## Teste adversarial: aperta tudo ao mesmo tempo, solta, pausa, reinicia.
var p
var t := 0.0
var rng := RandomNumberGenerator.new()
var acoes := ["cima","baixo","esquerda","direita","passe","ataque","saque_flutuante","bloqueio","mergulho"]
var seg := 120.0
var modo := "caos"
var _estado_ant := -1
var _tempo_no_estado := 0.0
var _max_parado := 0.0
var _problemas: Array = []
var _reinicios := 0
var _quadro := 0
var _bola_max := 0.0
var _pausas := 0
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("seg="): seg = float(a.split("=")[1])
		if a.begins_with("modo="): modo = a.split("=")[1]
		if a.begins_with("sem="): rng.seed = int(a.split("=")[1])
	root.get_node("Configuracao").contra_computador = true
	_abrir()
func _abrir() -> void:
	if p != null and is_instance_valid(p):
		root.remove_child(p); p.free()
	p = load("res://cenas/partida.tscn").instantiate()
	root.add_child(p); current_scene = p
func _ap(a: String, v: bool) -> void:
	var e := InputEventAction.new(); e.action = a; e.pressed = v
	Input.parse_input_event(e)
func _process(d: float) -> bool:
	_quadro += 1
	if p == null or not is_instance_valid(p) or p.bola == null: return false
	t += d
	# checagens
	var b: Vector3 = p.bola.global_position
	if is_nan(b.x) or is_nan(b.y) or is_nan(b.z): _problemas.append("bola NaN t=%.1f" % t)
	elif b.length() > 60.0: _problemas.append("bola longe %s t=%.1f est=%d" % [b, t, p.estado])
	_bola_max = maxf(_bola_max, b.y)
	for time in 2:
		for a in p.atletas[time]:
			var q: Vector3 = a.global_position
			if is_nan(q.x) or absf(q.x) > 25.0 or absf(q.z) > 30.0 or q.y < -1.0 or q.y > 6.0:
				_problemas.append("atleta fora/estranho %s time %d t=%.1f" % [q, time, t]); break
	if p.estado == _estado_ant:
		if not paused: _tempo_no_estado += d
	else:
		_max_parado = maxf(_max_parado, _tempo_no_estado) if _estado_ant != 3 else _max_parado
		_tempo_no_estado = 0.0; _estado_ant = p.estado
	if _tempo_no_estado > 25.0 and p.estado != 3 and not paused:
		_problemas.append("estado %d parado %.0fs (placar %s)" % [p.estado, _tempo_no_estado, p.placar.pontos]); _tempo_no_estado = 0.0
	# entradas
	if modo == "caos" or modo == "tudo":
		for a in acoes:
			if rng.randf() < 0.35:
				_ap("p1_" + a, rng.randf() < 0.5)
			if modo == "tudo" and rng.randf() < 0.1:
				_ap("p2_" + a, rng.randf() < 0.5)
	elif modo == "segurar":
		for a in acoes: _ap("p1_" + a, true)
	if rng.randf() < 0.01:
		_ap("pausa", true); _ap("pausa", false); _pausas += 1
	if rng.randf() < 0.002 and not paused:
		_reinicios += 1
		for a in acoes: _ap("p1_" + a, false)
		_abrir()
	if t > seg:
		print("RESULTADO modo=%s t=%.0f pausas=%d reinicios=%d placar=%s sets=%s estado=%d bola_max_y=%.1f maior_parado=%.1f" % [modo, t, _pausas, _reinicios, p.placar.pontos, p.placar.sets, p.estado, _bola_max, _max_parado])
		var vistos := {}
		for x in _problemas:
			var k: String = x.substr(0, 14)
			if not vistos.has(k): vistos[k] = 0
			vistos[k] += 1
			if vistos[k] <= 3: print("PROBLEMA ", x)
		print("total problemas: ", _problemas.size())
		return true
	return false
