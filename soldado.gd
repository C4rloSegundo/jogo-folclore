extends CharacterBody2D


# --- Configurações de Movimento (PADRÃO NOVO) ---
@export var speed: float = 40.0    # Velocidade reduzida
@export var gravity: float = 100.0 # Gravidade muito leve (flutuante)
@export var tempo_patrulha: float = 3.0 

# --- Variáveis de Patrulha ---

var direction = -1     # Começa andando para a esquerda



var timer_patrulha: Timer
var player_alvo: Node2D = null # Variável para guardar o jogador detectado

# --- Combate ---
var vida: int = 3
var is_dead: bool = false

# --- Referências ---
@onready var sprite: AnimatedSprite2D = $Sprite

# --- Inicialização ---
func _ready():
	atualizar_visual()
	
	# Configuração do Timer de Patrulha
	timer_patrulha = Timer.new()
	timer_patrulha.wait_time = tempo_patrulha
	timer_patrulha.one_shot = false
	timer_patrulha.autostart = true
	timer_patrulha.timeout.connect(virar_por_tempo)
	add_child(timer_patrulha)

# --- Física e Inteligência Artificial ---
func _physics_process(delta):
	if is_dead: return

	# 1. Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. DECISÃO: Perseguir ou Patrulhar?
	if player_alvo != null:
		# --- MODO PERSEGUIÇÃO ---
		# Calcula a direção para o jogador (1 ou -1)
		var direcao_player = global_position.direction_to(player_alvo.global_position).x
		
		if direcao_player > 0:
			direction = 1
		else:
			direction = -1
			
		# Pausa o relógio da patrulha enquanto persegue
		if not timer_patrulha.is_stopped():
			timer_patrulha.stop()
			
	else:
		# --- MODO PATRULHA ---
		# Se não tem alvo, religa o timer se estiver parado
		if timer_patrulha.is_stopped():
			timer_patrulha.start()

	# 3. Aplicar Movimento e Visual
	velocity.x = speed * direction
	atualizar_visual() # Garante que ele olha para onde anda
	move_and_slide()

# --- Função do Timer (Patrulha) ---
func virar_por_tempo():
	# Só vira pelo tempo se NÃO estiver perseguindo ninguém
	if player_alvo == null:
		direction *= -1

# --- Visual ---
func atualizar_visual():
	if direction == 1:
		sprite.flip_h = false # Direita
	else:
		sprite.flip_h = true  # Esquerda

# --- DETECÇÃO DO JOGADOR (Conecte estes sinais!) ---

# Conecte o sinal "body_entered" do seu Area2D (Detector) aqui:
func _on_detector_body_entered(body):
	if body.is_in_group("jogador"):
		player_alvo = body # Começa a perseguir!

# Conecte o sinal "body_exited" do seu Area2D (Detector) aqui:
func _on_detector_body_exited(body):
	if body == player_alvo:
		player_alvo = null # Para de perseguir e volta a patrulhar

# --- Combate ---
func levar_dano(dano: int):
	if is_dead: return
	vida -= dano
	sprite.modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)
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
