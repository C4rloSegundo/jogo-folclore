extends Area2D

# Configurações da Bola
@export var velocidade: float = 400.0
@export var dano: int = 1
var direcao: int = 1 # 1 = Direita, -1 = Esquerda

# Referência automática ao nó de animação
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	print("FOGO: Nasci na posição ", global_position) # <-- ADICIONA ISTO
	# 1. Toca a animação assim que nasce
	if anim:
		anim.play("default")
	
	# 2. Se a bola for para a esquerda, roda o desenho 180 graus
	if direcao == -1:
		rotation_degrees = 180 

func _process(delta):
	# Move a bola para a frente
	position.x += velocidade * direcao * delta

# Quando a bola bate em algo
func _on_body_entered(body):
	# Ignora o jogador
	if body.is_in_group("jogador"):
		return
	# ADICIONA ISTO PARA SABER NO QUE BATEU
	print("FOGO: Bati em ", body.name, "kk e vou morrer.")
	# Se for Inimigo, dá dano
	if body.has_method("levar_dano"):
		body.levar_dano(dano)
		queue_free() # Destrói a bola
	
	# Se for Parede/Chão
	elif body is TileMap or body is TileMapLayer:
		queue_free() # Destrói a bola

# Quando a bola sai da tela (limpeza)
func _on_visible_on_screen_notifier_2d_screen_exited():
	print("FOGO: Sai da tela. Tchau.") # <-- ADICIONA ISTO
	queue_free()


func _on_visible_on_screen_enabler_2d_screen_exited() -> void:
	pass # Replace with function body.
