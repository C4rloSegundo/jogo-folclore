extends CharacterBody2D

# --- Configurações ---
@export var speed: float = 40.0
@export var gravity: float = 10.0
@export var tempo_patrulha: float = 3.0 

var direction: int = -1 
var timer_patrulha: Timer
var player_alvo: Node2D = null

# --- Combate ---
var vida: int = 3
var is_dead: bool = false

# --- Referências ---
@onready var sprite: AnimatedSprite2D = $Sprite
# O código vai procurar um nó chamado "Detector". 
# Se mudaste o nome na cena, avisa no erro.
@onready var detector: Area2D = $Detector 

func _ready():
	atualizar_visual()
	
	# --- 1. CRIAÇÃO DO TIMER (Patrulha) ---
	timer_patrulha = Timer.new()
	timer_patrulha.wait_time = tempo_patrulha
	timer_patrulha.one_shot = false
	timer_patrulha.autostart = true
	timer_patrulha.timeout.connect(virar_por_tempo)
	add_child(timer_patrulha)
	
	# --- 2. LIGAÇÃO AUTOMÁTICA DOS OLHOS ---
	if detector:
		# Limpa conexões antigas para evitar bugs
		if detector.body_entered.is_connected(_on_detector_body_entered):
			detector.body_entered.disconnect(_on_detector_body_entered)
		if detector.area_entered.is_connected(_on_detector_area_entered):
			detector.area_entered.disconnect(_on_detector_area_entered)
			
		# Liga detecção de CORPOS (CharacterBody2D)
		detector.body_entered.connect(_on_detector_body_entered)
		detector.body_exited.connect(_on_detector_body_exited)
		
		# Liga detecção de ÁREAS (Caso o jogador seja um Area2D)
		detector.area_entered.connect(_on_detector_area_entered)
		detector.area_exited.connect(_on_detector_area_exited)
		
		print("SUCESSO: Olhos do inimigo ligados e prontos!")
	else:
		print("ERRO: Não encontrei o nó 'Detector' na cena do Inimigo!")

# --- Física ---
func _physics_process(delta):
	if is_dead: return

	if not is_on_floor():
		velocity.y += gravity * delta

	# Lógica de Perseguição vs Patrulha
	if player_alvo != null:
		# Perseguindo
		var direcao_player = global_position.direction_to(player_alvo.global_position).x
		if direcao_player > 0: direction = 1
		else: direction = -1
		
		if not timer_patrulha.is_stopped(): timer_patrulha.stop()
	else:
		# Patrulhando
		if timer_patrulha.is_stopped(): timer_patrulha.start()

	velocity.x = speed * direction
	atualizar_visual()
	move_and_slide()

func virar_por_tempo():
	if player_alvo == null:
		direction *= -1

func atualizar_visual():
	if direction == 1: sprite.flip_h = false
	else: sprite.flip_h = true

# --- DETECÇÃO (A parte que estava a falhar) ---

# 1. Se o Jogador for um CORPO (CharacterBody2D)
func _on_detector_body_entered(body):
	print("Inimigo viu um CORPO: ", body.name)
	if body.is_in_group("jogador"):
		print("--> É O JOGADOR! ATACAR!")
		player_alvo = body

func _on_detector_body_exited(body):
	if body == player_alvo:
		player_alvo = null

# 2. Se o Jogador for uma ÁREA (Area2D) ou Hitbox
func _on_detector_area_entered(area):
	print("Inimigo viu uma ÁREA: ", area.name)
	var pai = area.get_parent()
	
	if area.is_in_group("jogador"):
		player_alvo = area
	elif pai.is_in_group("jogador"):
		print("--> É O JOGADOR (via PAI da área)!")
		player_alvo = pai

func _on_detector_area_exited(area):
	var pai = area.get_parent()
	if area == player_alvo or pai == player_alvo:
		player_alvo = null

# --- Combate ---
func levar_dano(dano: int):
	if is_dead: return
	vida -= dano
	if vida <= 0: morrer()

func morrer():
	if is_dead: return
	is_dead = true
	set_physics_process(false)
	timer_patrulha.stop()
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	sprite.play("morrendo")
	await sprite.animation_finished
	queue_free()

func _on_hitbox_dano_body_entered(body):
	if body.is_in_group("jogador") and body.has_method("levar_dano"):
		body.levar_dano(1)
func _on_hurtbox_area_entered(area):
	if area.name == "HitboxAtaque":
		levar_dano(1)
