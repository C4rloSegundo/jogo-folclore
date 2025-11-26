extends AnimatedSprite2D

func _ready():
	# Verificação de segurança: A animação existe?
	if not sprite_frames.has_animation("default"):
		print("ERRO NO EFEITO: Não existe animação chamada 'default'!")
		print("Verifique o painel SpriteFrames na parte inferior do editor.")
		return

	# Força o início da animação
	play("default")
	
	# Conecta o sinal
	if animation_finished.is_connected(_on_animation_finished):
		animation_finished.disconnect(_on_animation_finished)
		
	animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	queue_free()
