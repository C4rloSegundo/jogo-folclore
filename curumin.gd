extends CharacterBody2D

# --- Constantes ---
const VELOCIDADE_ANDAR: float = 150.0
const FORCA_PULO: float = -300.0
const GRAVIDADE: float = 400.0
const CENA_BOLA_FOGO = preload("res://bola_de_fogo.tscn")

# --- Estado ---
var vida_max: int = 3
var vida_atual: int = 3
var esta_invencivel: bool = false 

# Variáveis de Pulo Duplo
var tem_pulo_duplo: bool = false 
var pulos_realizados: int = 0

signal saude_mudou(vida_atual: int)

# --- Referências ---
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox_ataque: Area2D = get_node_or_null("Hitboxataque")
@onready var shape_ataque = get_node_or_null("Hitboxataque/CollisionShape2D")
@onready var timer_invencibilidade: Timer = $TimerInvencibilidade 
@onready var ponto_tiro: Marker2D = get_node_or_null("PontoTiro")

# NOVO: Referência às partículas (Crie o nó na cena!)
@onready var fumaça_pulo: CPUParticles2D = get_node_or_null("ParticulaPulo")

func _ready():
	vida_atual = vida_max
	if shape_ataque: shape_ataque.disabled = true
	add_to_group("jogador")

func _physics_process(delta: float):
	
	if not is_on_floor():
		velocity.y += GRAVIDADE * delta
	else:
		pulos_realizados = 0 # Reseta os pulos ao tocar no chão

	# --- SISTEMA DE PULO DUPLO ---
	if Input.is_action_just_pressed("pular"):
		
		# Pulo 1: Chão
		if is_on_floor():
			velocity.y = FORCA_PULO
			pulos_realizados = 1
			
		# Pulo 2: Ar (Pulo Duplo)
		elif tem_pulo_duplo and pulos_realizados < 2:
			velocity.y = FORCA_PULO
			pulos_realizados += 1
			
			# EFEITO VISUAL DO PULO DUPLO
			if fumaça_pulo:
				fumaça_pulo.restart() # Reinicia a explosão de partículas
				fumaça_pulo.emitting = true

	# --- Movimento ---
	var direcao = Input.get_axis("esquerda", "direita")
	velocity.x = direcao * VELOCIDADE_ANDAR
	
	# Virar Sprite... (código igual ao anterior)
	if direcao > 0: 
		sprite.flip_h = false
		if hitbox_ataque: hitbox_ataque.position.x = abs(hitbox_ataque.position.x)
		if ponto_tiro: ponto_tiro.position.x = abs(ponto_tiro.position.x)
	elif direcao < 0: 
		sprite.flip_h = true
		if hitbox_ataque: hitbox_ataque.position.x = -abs(hitbox_ataque.position.x)
		if ponto_tiro: ponto_tiro.position.x = -abs(ponto_tiro.position.x)
	
	# Ataque... (código igual ao anterior)
	if Input.is_action_just_pressed("atacar"):
		sprite.play("atacando")
		if shape_ataque: shape_ataque.disabled = false
		criar_bola_de_fogo()
	
	elif sprite.animation != "atacando" or not sprite.is_playing():
		if shape_ataque: shape_ataque.disabled = true
		if not is_on_floor(): sprite.play("pulando")
		elif direcao != 0: sprite.play("andando")
		else: sprite.play("parado")

	move_and_slide()

# --- Função chamada pelo Saci ---
func desbloquear_pulo_duplo():
	tem_pulo_duplo = true
	print("PODER RECEBIDO: Pulo Duplo Ativado!")

# ... (Resto das funções criar_bola_de_fogo, levar_dano, etc. continuam iguais) ...
func criar_bola_de_fogo():
	if not ponto_tiro: return
	var nova_bola = CENA_BOLA_FOGO.instantiate()
	if sprite.flip_h: nova_bola.direcao = -1
	else: nova_bola.direcao = 1
	nova_bola.top_level = true
	nova_bola.global_position = ponto_tiro.global_position
	get_parent().add_child(nova_bola)

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
