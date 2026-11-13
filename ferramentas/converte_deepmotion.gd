extends SceneTree
## Converte uma animação do DeepMotion (vídeo -> animação) pro formato das outras.
## Rodar no terminal, dentro da pasta do projeto:
##   godot --headless --script res://ferramentas/converte_deepmotion.gd
##
## O .fbx fica em animacoes/deepmotion/ e já chega no esqueleto comum pelo
## deepmotion_bone_map.tres (ver animacoes/LEIA-ME.md). Aqui só falta:
## - virar meia volta: o DeepMotion entrega o atleta de costas pro que o jogo
##   chama de frente (o quadril começa girado 180°);
## - salvar como .tres com o nome que o jogo usa.
## O resto (quadril no lugar, trecho do lance) quem faz é o animador.

const CONVERSOES := {
	"res://animacoes/deepmotion/cortada.fbx": "res://animacoes/cortada_deepmotion.tres",
	# Toque (levantamento) do vídeo livre do Pexels 6217270 (producao/videos_pexels),
	# trecho de 1 a 4 s, convertido no DeepMotion em 12/11/2026.
	"res://animacoes/deepmotion/levantamento.fbx": "res://animacoes/levantamento_deepmotion.tres",
	# Manchete (Pexels 6217284, 3 a 7,5 s), saque em pé (6217332, 3 a 10,3 s, em
	# câmera lenta) e saque viagem (6217265, 1 a 8,1 s), convertidos em 13/11/2026.
	"res://animacoes/deepmotion/manchete.fbx": "res://animacoes/manchete_deepmotion.tres",
	"res://animacoes/deepmotion/saque.fbx": "res://animacoes/saque_deepmotion.tres",
	"res://animacoes/deepmotion/saque_viagem.fbx": "res://animacoes/saque_viagem_deepmotion.tres",
}
## A meia volta só vale pra vídeo filmado de COSTAS pro atleta (a cortada do
## Victor). Vídeo filmado de FRENTE (como o do Pexels) já sai virado certo.
## Conferir: o peito tem que apontar pro mesmo lado da animação "parado".
const SEM_MEIA_VOLTA := [
	"res://animacoes/deepmotion/levantamento.fbx",
	"res://animacoes/deepmotion/manchete.fbx",
	"res://animacoes/deepmotion/saque_viagem.fbx",
	# O saque em pé (filmado de lado) saía com o peito pra trás: leva a meia volta.
]


func _init() -> void:
	for origem in CONVERSOES:
		var cena: Node = load(origem).instantiate()
		var player: AnimationPlayer = cena.get_node("AnimationPlayer")
		var animacao: Animation = player.get_animation(player.get_animation_list()[0]).duplicate()
		cena.free()
		if not origem in SEM_MEIA_VOLTA:
			_meia_volta(animacao)
		var destino: String = CONVERSOES[origem]
		var erro := ResourceSaver.save(animacao, destino)
		print("%s -> %s (%.2f s) %s" % [origem, destino, animacao.length, "ok" if erro == OK else "ERRO %d" % erro])
	quit()


## Gira o quadril (e com ele o corpo todo) 180° em volta do eixo vertical.
func _meia_volta(animacao: Animation) -> void:
	var giro := Quaternion(Vector3.UP, PI)
	var rotacao := animacao.find_track(NodePath("%GeneralSkeleton:Hips"), Animation.TYPE_ROTATION_3D)
	if rotacao >= 0:
		for chave in animacao.track_get_key_count(rotacao):
			var q: Quaternion = animacao.track_get_key_value(rotacao, chave)
			animacao.track_set_key_value(rotacao, chave, giro * q)
	var posicao := animacao.find_track(NodePath("%GeneralSkeleton:Hips"), Animation.TYPE_POSITION_3D)
	if posicao >= 0:
		for chave in animacao.track_get_key_count(posicao):
			var p: Vector3 = animacao.track_get_key_value(posicao, chave)
			animacao.track_set_key_value(posicao, chave, giro * p)
