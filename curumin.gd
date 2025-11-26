extends CharacterBody2D

# --- Constantes ---
const VELOCIDADE_ANDAR: float = 150.0
const FORCA_PULO: float = -300.0
const GRAVIDADE: float = 400.0
const CENA_BOLA_FOGO = preload("res://bola_de_fogo.tscn")

# --- Estado ---
var vida_max: int = 3
var vida_atual: int = 3
var ultimo_checkpoint_pos: Vector2
var esta_invencivel: bool = false 

signal saude_mudou(vida_atual: int)

# --- Referências ---
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox_ataque: Area2D = get_node_or_null("Hitboxataque")
@onready var shape_ataque = get_node_or_null("Hitboxataque/CollisionShape2D")
@onready var timer_invencibilidade: Timer = $TimerInvencibilidade 
@onready var ponto_tiro: Marker2D = get_node_or_null("PontoTiro")

func _ready():
	vida_atual = vida_max
	ultimo_checkpoint_pos = global_position
	
	if not ponto_tiro:
		print("ERRO: O nó 'PontoTiro' (Marker2D) não foi encontrado!")
	
	if shape_ataque:
		shape_ataque.disabled = true
	add_to_group("jogador")

func _physics_process(delta: float):
	
	if not is_on_floor():
		velocity.y += GRAVIDADE * delta

	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = FORCA_PULO

	var direcao = Input.get_axis("esquerda", "direita")
	velocity.x = direcao * VELOCIDADE_ANDAR
	
	# --- SISTEMA DE VIRAR TUDO ---
	if direcao > 0: # Direita
		sprite.flip_h = false
		
		# Empurra Hitbox para a direita
		if hitbox_ataque:
			hitbox_ataque.position.x = abs(hitbox_ataque.position.x)
			
		# Empurra Mira para a direita (Valor Positivo)
		if ponto_tiro:
			ponto_tiro.position.x = abs(ponto_tiro.position.x)
		
	elif direcao < 0: # Esquerda
		sprite.flip_h = true
		
		# Empurra Hitbox para a esquerda
		if hitbox_ataque:
			hitbox_ataque.position.x = -abs(hitbox_ataque.position.x)
			
		# Empurra Mira para a esquerda (Valor Negativo)
		if ponto_tiro:
			ponto_tiro.position.x = -abs(ponto_tiro.position.x)
	
	# --- Ataque ---
	if Input.is_action_just_pressed("atacar"):
		sprite.play("atacando")
		sprite.position.y = 0 
		if shape_ataque:
			shape_ataque.disabled = false
		
		# Dispara a bola
		criar_bola_de_fogo()
	
	elif sprite.animation != "atacando" or not sprite.is_playing():
		if shape_ataque:
			shape_ataque.disabled = true
			
		if not is_on_floor(): sprite.play("pulando")
		elif direcao != 0: sprite.play("andando")
		else: sprite.play("parado")

	move_and_slide()

# --- FUNÇÃO DE TIRO ---
func criar_bola_de_fogo():
	if not ponto_tiro:
		print("ERRO: PontoTiro não encontrado!")
		return

	var nova_bola = CENA_BOLA_FOGO.instantiate()
	
	# 1. Direção
	if sprite.flip_h:
		nova_bola.direcao = -1
	else:
		nova_bola.direcao = 1
	
	# 2. O SEGREDO MÁXIMO (Top Level + Marker2D)
	# O top_level faz a bola ignorar escalas estranhas do cenário
	nova_bola.top_level = true
	
	# A global_position pega a coordenada exata do pixel da tua mira no mundo
	nova_bola.global_position = ponto_tiro.global_position
	
	# 3. Adiciona ao mundo
	get_parent().add_child(nova_bola)
# ... (Resto das funções de dano mantidas iguais) ...
func levar_dano(dano: int):
	if esta_invencivel: return
	vida_atual -= dano
	saude_mudou.emit(vida_atual)
	if vida_atual <= 0: morrer()
	else: iniciar_invencibilidade()

func morrer():
	get_tree().reload_current_scene()

func iniciar_invencibilidade():
	esta_invencivel = true
	timer_invencibilidade.start()
	modulate.a = 0.5 

func _on_timer_invencibilidade_timeout() -> void:
	esta_invencivel = false
	modulate.a = 1.0 

func _on_hitbox_ataque_area_entered(body): 
	if body != self and body.has_method("levar_dano"):
		body.levar_dano(1)
