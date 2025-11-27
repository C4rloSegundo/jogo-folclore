extends Area2D

@export var velocidade: float = 350.0
@export var dano: int = 1
@export var forca_curva: float = 5.0 # Aumentei para 5.0 para ela virar mais rápido e não errar tanto

var direcao: Vector2 = Vector2.RIGHT 
var alvo: Node2D = null 

func _ready():
	await get_tree().create_timer(4.0).timeout
	queue_free()
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	#look_at(global_position + direcao)

func _process(delta):
	# --- LÓGICA TELEGUIADA (HOMING) ---
	if is_instance_valid(alvo):
		# Calcula a direção ideal para o jogador
		var direcao_alvo = global_position.direction_to(alvo.global_position)
		
		# Curva a direção. O SEGREDO ESTÁ NO .normalized() NO FINAL!
		# Isso impede que a bala perca velocidade nas curvas.
		direcao = direcao.lerp(direcao_alvo, forca_curva * delta).normalized()
		
		# Atualiza a rotação visual
		rotation = direcao.angle()
	
	# Move a bala
	position += direcao * velocidade * delta

func _on_body_entered(body):
	# DEBUG: Mostra no console o que a bala acertou
	print("Bala bateu em: ", body.name) 

	# 1. PROTEÇÃO: Se acertar o Robô ou qualquer inimigo, IGNORA e sai.
	if body.name == "RoboBoss" or body.is_in_group("inimigos"):
		return 

	# 2. Se acertar o jogador
	if body.is_in_group("jogador") and body.has_method("levar_dano"):
		body.levar_dano(1)
		queue_free() # Some
		
	# 3. Se acertar parede/chão
	elif body is TileMap or body is StaticBody2D:
		queue_free() # Some
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
