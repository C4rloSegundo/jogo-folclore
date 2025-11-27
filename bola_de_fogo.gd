extends Area2D

@export var velocidade: float = 400.0
@export var dano: int = 1
var direcao: int = 1 

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	if anim:
		# Toca a animação padrão se nenhuma outra foi definida antes
		if anim.animation == "default":
			anim.play("default")
		
		atualizar_visual()
	else:
		print("ERRO: Nó 'AnimatedSprite2D' não encontrado na Bola de Fogo!")

func _process(delta):
	position.x += velocidade * direcao * delta
	atualizar_visual()

func atualizar_visual():
	if not anim: return
	
	# Espelha o sprite se for para a esquerda
	if direcao == -1:
		anim.scale.x = -1
	else:
		anim.scale.x = 1

# --- FUNÇÃO PARA ATIVAR O PODER (ATUALIZADA PARA 'fogo_final') ---
# No bola_de_fogo.gd

func ativar_poder():
	dano = 3
	if anim:
		# Confirme se o nome aqui é EXATAMENTE igual ao que criou no SpriteFrames
		if anim.sprite_frames.has_animation("fogo_final"):
			anim.play("fogo_final")
		else:
			print("ERRO: Animação 'fogo_final' não existe!")

func _on_body_entered(body):
	if body.is_in_group("jogador"): return
	
	if body.has_method("levar_dano"):
		body.levar_dano(dano)
		queue_free()
	elif body is TileMap or body is TileMapLayer:
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
