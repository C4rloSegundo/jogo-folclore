extends CharacterBody2D

# --- Configurações ---
@export var speed: float = 40.0
@export var gravity: float = 100.0 # Ajustei para o padrão, mas podes mudar
@export var tempo_patrulha: float = 3.0 
@export var dano_ataque: int = 1 

# --- CONFIGURAÇÕES DE TIRO (NOVO) ---
@export var pode_atirar_longe: bool = true # Define se este inimigo atira
@export var intervalo_tiro: float = 2.0    # Tempo entre tiros
const CENA_TIRO = preload("res://tiro_inimigo.tscn")

var direction: int = -1 
var timer_patrulha: Timer
var timer_recarregar: Timer # Timer novo
var player_alvo: Node2D = null
var arma_pronta: bool = true # Controla o cooldown

# --- Combate ---
var vida: int = 3
var is_dead: bool = false
var is_attacking: bool = false 

# --- Referências ---
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var detector: Area2D = $Detector 
@onready var hitbox_dano: Area2D = $HitboxDano
# NOVO: Referência ao ponto de onde sai o tiro
@onready var ponto_tiro: Marker2D = get_node_or_null("PontoTiro")

func _ready():
	atualizar_visual()
	
	# Timer de Patrulha
	timer_patrulha = Timer.new()
	timer_patrulha.wait_time = tempo_patrulha
	timer_patrulha.autostart = true
	timer_patrulha.timeout.connect(virar_por_tempo)
	add_child(timer_patrulha)
	
	# Timer de Recarga (NOVO)
	timer_recarregar = Timer.new()
	timer_recarregar.wait_time = intervalo_tiro
	timer_recarregar.one_shot = true 
	timer_recarregar.timeout.connect(_on_arma_recarregada)
	add_child(timer_recarregar)
	
	# Conexões de segurança
	if detector:
		detector.body_entered.connect(_on_detector_body_entered)
		detector.body_exited.connect(_on_detector_body_exited)
	if hitbox_dano:
		hitbox_dano.body_entered.connect(_on_hitbox_dano_body_entered)

func _physics_process(delta):
	if is_dead: return

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return 

	# --- INTELIGÊNCIA ARTIFICIAL ---
	if player_alvo != null:
		# MODO PERSEGUIÇÃO
		var direcao_player = global_position.direction_to(player_alvo.global_position).x
		
		# Define o lado
		if direcao_player > 0: direction = 1
		else: direction = -1
		
		# Para o timer de patrulha enquanto persegue
		if not timer_patrulha.is_stopped(): timer_patrulha.stop()
		
		# --- LÓGICA DE TIRO ---
		# Se pode atirar, arma está pronta e tem o marcador configurado
		if pode_atirar_longe and arma_pronta and ponto_tiro:
			atirar_no_jogador()
			
	else:
		# MODO PATRULHA
		if timer_patrulha.is_stopped(): timer_patrulha.start()

	velocity.x = speed * direction
	atualizar_visual()
	move_and_slide()

func virar_por_tempo():
	if player_alvo == null:
		direction *= -1

func atualizar_visual():
	if not is_attacking:
		if direction == 1: 
			sprite.flip_h = false
			# Vira o ponto de tiro também!
			if ponto_tiro: ponto_tiro.position.x = abs(ponto_tiro.position.x)
		else: 
			sprite.flip_h = true
			if ponto_tiro: ponto_tiro.position.x = -abs(ponto_tiro.position.x)

# --- FUNÇÃO DE DISPARO ---
func atirar_no_jogador():
	arma_pronta = false
	timer_recarregar.start() # Começa o cooldown
	
	# Cria o tiro
	var tiro = CENA_TIRO.instantiate()
	tiro.direcao = direction # Usa a direção atual do inimigo
	
	# Posiciona no marcador (Top Level para não bugar com movimento)
	tiro.top_level = true
	tiro.global_position = ponto_tiro.global_position
	
	# Adiciona à cena
	get_parent().add_child(tiro)
	
	# Opcional: Tocar animação de tiro se tiveres
	# sprite.play("atirar")

func _on_arma_recarregada():
	arma_pronta = true # Pode atirar de novo

# --- DETECÇÃO ---
func _on_detector_body_entered(body):
	if body.is_in_group("jogador"):
		player_alvo = body

func _on_detector_body_exited(body):
	if body == player_alvo:
		player_alvo = null

# --- COMBATE ---
func levar_dano(dano: int):
	if is_dead: return
	vida -= dano
	if vida <= 0: morrer()

func morrer():
	if is_dead: return
	is_dead = true
	set_physics_process(false)
	timer_patrulha.stop()
	timer_recarregar.stop()
	velocity = Vector2.ZERO
	
	$CollisionShape2D.set_deferred("disabled", true)
	if hitbox_dano:
		hitbox_dano.set_deferred("monitoring", false)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
		
	sprite.play("morrendo")
	await sprite.animation_finished
	queue_free()

func _on_hitbox_dano_body_entered(body):
	if body != self and body.is_in_group("jogador") and body.has_method("levar_dano"):
		if not is_dead and not is_attacking:
			# Ataque corpo a corpo (se encostar)
			realizar_ataque(body)

func realizar_ataque(alvo):
	# Verifica animação de ataque corpo a corpo se existir
	if sprite.sprite_frames.has_animation("atacando"):
		is_attacking = true
		sprite.play("atacando")
		alvo.levar_dano(dano_ataque)
		await sprite.animation_finished
		is_attacking = false
		if not is_dead: sprite.play("default")
	else:
		# Se não tiver animação, dá dano direto
		alvo.levar_dano(dano_ataque)

func _on_hurtbox_area_entered(area):
	if area.name == "HitboxAtaque":
		levar_dano(1)
