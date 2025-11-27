extends CharacterBody2D

# --- Configurações (Baseadas no Soldado) ---
@export var speed: float = 0.0 # Boss não anda (Torreta)
@export var gravity: float = 400.0
@export var tempo_patrulha: float = 2.0 # Usaremos isso como "Tempo entre Rajadas"
@export var dano_ataque: int = 1 

# --- CONFIGURAÇÕES DE TIRO ---
@export var pode_atirar_longe: bool = true
const CENA_TIRO = preload("res://bala.tscn")

var direction: int = -1 
var timer_intervalo_ataques: Timer # Equivalente ao timer_patrulha
var player_alvo: Node2D = null
var pode_atirar: bool = true # Controla o cooldown da rajada

# --- Combate ---
var vida: int = 40
var is_dead: bool = false
var is_attacking: bool = false 

# --- Referências ---
@onready var sprite: AnimatedSprite2D = $Sprite
# Boss não precisa de detector físico, ele acha o player no mapa todo
@onready var ponto_tiro: Marker2D = get_node_or_null("PontoTiro")

func _ready():
	atualizar_visual()
	add_to_group("inimigos") # Importante para a bala não te matar
	
	# Diferença do Soldado: O Boss acha o player globalmente
	player_alvo = get_tree().get_first_node_in_group("jogador")
	
	# Timer de Intervalo (Controla a cadência das rajadas)
	timer_intervalo_ataques = Timer.new()
	timer_intervalo_ataques.wait_time = tempo_patrulha
	timer_intervalo_ataques.one_shot = true 
	timer_intervalo_ataques.timeout.connect(_on_intervalo_acabou)
	add_child(timer_intervalo_ataques)
	
	sprite.play("parado")

func _physics_process(delta):
	if is_dead: return

	# Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# Se estiver no meio da rajada, trava
	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return 

	# --- INTELIGÊNCIA ARTIFICIAL (Torreta) ---
	if player_alvo != null:
		# Calcula direção (Esquerda ou Direita)
		var direcao_player = global_position.direction_to(player_alvo.global_position).x
		
		if direcao_player > 0: direction = 1
		else: direction = -1
		
		# Boss não anda (velocidade 0), apenas vira
		velocity.x = 0 
		
		# Lógica de Tiro (Rajada)
		if pode_atirar and ponto_tiro:
			atirar_rajada()
	
	atualizar_visual()
	move_and_slide()

# Libera o boss para atirar de novo
func _on_intervalo_acabou():
	pode_atirar = true

func atualizar_visual():
	if not is_attacking:
		if direction == 1: 
			sprite.flip_h = false # Direita
			if ponto_tiro: ponto_tiro.position.x = abs(ponto_tiro.position.x)
		else: 
			sprite.flip_h = true # Esquerda
			if ponto_tiro: ponto_tiro.position.x = -abs(ponto_tiro.position.x)

# --- FUNÇÃO DE DISPARO (Rajada) ---
func atirar_rajada():
	print("BOSS: Iniciando Rajada!")
	pode_atirar = false # Bloqueia novos tiros
	is_attacking = true # Trava a mira
	
	if sprite.sprite_frames.has_animation("atacando arma"):
		sprite.play("atacando arma")
	
	# Loop para dar 5 tiros (Metralhadora)
	for i in range(5):
		if is_dead: return
		criar_bala()
		await get_tree().create_timer(0.2).timeout # Tempo entre balas
	
	# Pequeno tempo de recuperação após atirar
	await get_tree().create_timer(0.5).timeout
	
	if is_dead: return
	
	# Destrava o boss e inicia o tempo para a próxima rajada
	is_attacking = false
	sprite.play("parado")
	timer_intervalo_ataques.start()

func criar_bala():
	var tiro = CENA_TIRO.instantiate()
	
	# Define a direção HORIZONTAL
	if direction == 1:
		tiro.direcao = Vector2.RIGHT
	else:
		tiro.direcao = Vector2.LEFT
	
	tiro.top_level = true
	tiro.global_position = ponto_tiro.global_position
	
	get_parent().add_child(tiro)

# --- COMBATE ---
func levar_dano(dano: int):
	if is_dead: return
	vida -= dano
	
	modulate = Color(10, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if vida <= 0: morrer()

func morrer():
	if is_dead: return
	
	print("BOSS: Morrendo...")
	is_dead = true
	set_physics_process(false)
	timer_intervalo_ataques.stop()
	velocity = Vector2.ZERO
	
	$CollisionShape2D.set_deferred("disabled", true)
	
	sprite.stop()
	sprite.play("morrendo")
	
	# Lembre-se: TIRE O LOOP DA ANIMAÇÃO 'morrendo' NO EDITOR!
	await sprite.animation_finished
	
	print("BOSS: Morto. Trocando em 5s...")
	await get_tree().create_timer(5.0).timeout
	
	# Salvar e Mudar Cena
	var hud = get_tree().current_scene.get_node_or_null("hud") # minúsculo
	if hud and Global:
		Global.tempo_da_partida = hud.parar_e_pegar_tempo()
	
	get_tree().change_scene_to_file("res://tela_vitoria.tscn") # minúsculo
