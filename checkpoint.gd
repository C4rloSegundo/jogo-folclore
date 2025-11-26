extends Area2D

# Variável para garantir que só cura uma vez
var ja_ativado = false

# Pegamos a referência do nó de animação
@onready var anim_fogueira = $AnimatedSprite2D

func _ready():
	# Garante que começa acesa (caso não tenha marcado "Playing" no editor)
	anim_fogueira.play("queimando")

func _on_body_entered(body):
	# Verifica se é o Player E se a fogueira ainda está acesa (não ativada)
	if body.has_method("curar_total") and not ja_ativado:
		
		print("Checkpoint ativado! Curando player e apagando fogo.")
		
		# 1. Cura o player e salva o checkpoint (função que criamos no Player)
		body.curar_total()
		
		# 2. Marca como ativado para não curar de novo
		ja_ativado = true
		
		# 3. Muda a animação visualmente para "apagada"
		anim_fogueira.play("apagada")
