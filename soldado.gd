extends CharacterBody2D

# --- Configurações ---
@export var speed: float = 40.0
@export var gravity: float = 10.0
@export var tempo_patrulha: float = 3.0 
@export var dano_ataque: int = 1 

var direction: int = -1 
var timer_patrulha: Timer
var player_alvo: Node2D = null

# --- Combate ---
var vida: int = 3
var is_dead: bool = false
var is_attacking: bool = false # Controla o estado de ataque

# --- Referências ---
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var detector: Area2D = $Detector 
@onready var hitbox_dano: Area2D = $HitboxDano

func _ready():
	atualizar_visual()
	
	# 1. Timer de Patrulha
	timer_patrulha = Timer.new()
	timer_patrulha.wait_time = tempo_patrulha
	timer_patrulha.one_shot = false
	timer_patrulha.autostart = true
	timer_patrulha.timeout.connect(virar_por_tempo)
	add_child(timer_patrulha)
	
	# 2. Conexão Detector (Olhos)
	if detector:
		# Desconecta anteriores para evitar erros
		if detector.body_entered.is_connected(_on_detector_body_entered):
			detector.body_entered.disconnect(_on_detector_body_entered)
		if detector.area_entered.is_connected(_on_detector_area_entered):
			detector.area_entered.disconnect(_on_detector_area_entered)
			
		detector.body_entered.connect(_on_detector_body_entered)
		detector.body_exited.connect(_on_detector_body_exited)
		detector.area_entered.connect(_on_detector_area_entered)
		detector.area_exited.connect(_on_detector_area_exited)
	else:
		print("AVISO: Nó 'Detector' não encontrado.")

	# 3. Conexão HitboxDano (Ataque)
	if hitbox_dano:
		if not hitbox_dano.body_entered.is_connected(_on_hitbox_dano_body_entered):
			hitbox_dano.body_entered.connect(_on_hitbox_dano_body_entered)
		print("SUCESSO: HitboxDano conectada!")
	else:
		print("ERRO: Não encontrei o nó 'HitboxDano'.")

# --- Física ---
func _physics_process(delta):
	if is_dead: return

	# Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# --- BLOQUEIO DE MOVIMENTO DURANTE ATAQUE ---
	# Se a animação de ataque estiver rodando, o inimigo congela no lugar
	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return 

	# Lógica: Perseguição ou Patrulha
	if player_alvo != null:
		# Persegue
		var direcao_player = global_position.direction_to(player_alvo.global_position).x
		if direcao_player > 0: direction = 1
		else: direction = -1
		
		if not timer_patrulha.is_stopped(): timer_patrulha.stop()
	else:
		# Patrulha
		if timer_patrulha.is_stopped(): timer_patrulha.start()

	velocity.x = speed * direction
	atualizar_visual()
	
	move_and_slide()

func virar_por_tempo():
	if player_alvo == null:
		direction *= -1

func atualizar_visual():
	if not is_attacking:
		if direction == 1: sprite.flip_h = false
		else: sprite.flip_h = true

# --- DETECÇÃO (Olhos) ---
func _on_detector_body_entered(body):
	if body.is_in_group("jogador"):
		player_alvo = body

func _on_detector_body_exited(body):
	if body == player_alvo:
		player_alvo = null

func _on_detector_area_entered(area):
	var pai = area.get_parent()
	if area.is_in_group("jogador"):
		player_alvo = area
	elif pai.is_in_group("jogador"):
		player_alvo = pai

func _on_detector_area_exited(area):
	var pai = area.get_parent()
	if area == player_alvo or pai == player_alvo:
		player_alvo = null

# --- COMBATE (Dano Recebido) ---
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
	if hitbox_dano:
		hitbox_dano.set_deferred("monitoring", false)
	
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
		
	sprite.play("morrendo")
	await sprite.animation_finished
	queue_free()

# --- SISTEMA DE ATAQUE (HitboxDano) ---

# Este é o ÚNICO lugar que dispara o ataque
func _on_hitbox_dano_body_entered(body):
	# TRAVA DE SEGURANÇA:
	# Ignora a si mesmo e o chão
	if body == self or body is TileMap or body is TileMapLayer:
		return
		
	# Só aceita se for do grupo "jogador"
	if body.is_in_group("jogador") and body.has_method("levar_dano"):
		
		# Só ataca se não estiver morto nem já atacando
		if not is_dead and not is_attacking:
			print("Alvo válido detectado! Iniciando ataque...")
			realizar_ataque(body)

func realizar_ataque(alvo):
	# VERIFICAÇÃO DE NOME DA ANIMAÇÃO (NOVO)
	# Verifica se existe a animação "atacando"
	if not sprite.sprite_frames.has_animation("atacando"):
		print("ERRO CRÍTICO: Não existe uma animação chamada 'atacando' no SpriteFrames!")
		print("Verifique se o nome é 'Attack', 'Atacar', 'batida', etc. e mude no código.")
		
		# Fallback para não travar o jogo se a animação não existir
		is_attacking = true
		alvo.levar_dano(dano_ataque)
		await get_tree().create_timer(0.5).timeout
		is_attacking = false
		return

	# 1. Trava o movimento
	is_attacking = true
	
	# 2. Toca a animação "atacando"
	sprite.play("atacando") 
	
	# 3. Causa o dano
	alvo.levar_dano(dano_ataque)
	
	# 4. Espera a animação terminar
	await sprite.animation_finished
	
	# 5. Destrava o movimento e volta ao sprite padrão
	is_attacking = false
	if not is_dead:
		# Se tiveres uma animação de andar/default, ele volta para ela
		if sprite.sprite_frames.has_animation("default"):
			sprite.play("default")
		elif sprite.sprite_frames.has_animation("andar"):
			sprite.play("andar")

func _on_hurtbox_area_entered(area):
	if area.name == "HitboxAtaque":
		levar_dano(1)
