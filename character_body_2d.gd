extends CharacterBody2D

# --- Configurações Básicas (Herdadas da lógica do Soldado) ---
@export var speed: float = 20.0 # Mais lento que o soldado
@export var gravity: float = 10.0
@export var dano_ataque: int = 1 

# --- Configurações do Boss ---
@export var intervalo_ataques: float = 2.0 
var vida: int = 50
var vida_max: int = 50

# --- Estado ---
var direction: int = -1 
var is_dead: bool = false
var is_attacking: bool = false
var player_alvo: Node2D = null

# --- Timers ---
var timer_cerebro: Timer # Substitui o Timer de Patrulha

# --- Projéteis e Cooldown ---
const CENA_BALA = preload("res://bala.tscn")
var pode_usar_laser: bool = true

# --- Referências ---
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var detector: Area2D = get_node_or_null("Detector") # Opcional no Boss, mas mantive
@onready var hitbox_dano: Area2D = get_node_or_null("HitboxDano") # Opcional

# Nós Específicos do Boss (Crie estes Markers na cena!)
@onready var ponto_braco: Marker2D = $PontoBraco
@onready var laser_peito: Area2D = $LaserPeito
@onready var visual_laser: ColorRect = $LaserPeito/ColorRect

func _ready():
	vida = vida_max
	atualizar_visual()
	
	# Se não tiver detector, busca o player globalmente (Comportamento de Boss)
	if not detector:
		player_alvo = get_tree().get_first_node_in_group("jogador")
	
	# Garante que o laser começa desligado
	if laser_peito:
		laser_peito.monitoring = false
		visual_laser.visible = false
	
	# Timer Cérebro (IA de Decisão)
	timer_cerebro = Timer.new()
	timer_cerebro.wait_time = intervalo_ataques
	timer_cerebro.autostart = true
	timer_cerebro.timeout.connect(_on_timer_cerebro_timeout)
	add_child(timer_cerebro)
	
	# Inicia animação
	sprite.play("parado")

func _physics_process(delta):
	if is_dead: return

	# Gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# Se estiver atacando, trava movimento
	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return 

	# --- INTELIGÊNCIA ARTIFICIAL (Perseguição Constante) ---
	if player_alvo != null:
		var direcao_player = global_position.direction_to(player_alvo.global_position).x
		
		# Define o lado
		if direcao_player > 0: direction = 1
		else: direction = -1
		
		velocity.x = speed * direction
		atualizar_visual()
	
	move_and_slide()

func atualizar_visual():
	if not is_attacking:
		if direction == 1: 
			sprite.flip_h = false
			# Vira os pontos de tiro e laser
			if ponto_braco: ponto_braco.position.x = abs(ponto_braco.position.x)
			if laser_peito: laser_peito.scale.x = 1 # Laser para direita (normal)
		else: 
			sprite.flip_h = true
			if ponto_braco: ponto_braco.position.x = -abs(ponto_braco.position.x)
			if laser_peito: laser_peito.scale.x = -1 # Laser invertido

# --- CÉREBRO DE ATAQUE (Substitui a patrulha/tiro simples) ---
func _on_timer_cerebro_timeout():
	# Verificações de segurança
	if is_attacking or is_dead or not player_alvo: return
	
	# Checagem de distância (aquele código que adicionamos antes)
	var distancia = global_position.distance_to(player_alvo.global_position)
	if distancia > 600: # Ajuste a distância conforme quiser
		return
	
	is_attacking = true
	var sorteio = randi() % 3
	
	if sorteio == 0 and pode_usar_laser:
		# A função do laser já cuida de destravar (is_attacking = false)
		ataque_laser_peito() 
	else:
		# A função da metralhadora JÁ CUIDA de destravar agora
		ataque_metralhadora_braco()
# --- ATAQUE 1: METRALHADORA ---
func ataque_metralhadora_braco():
	print("Boss: Rajada de Metralhadora!")
	
	# Garante que a animação começa do zero
	sprite.stop()
	sprite.play("atacando arma") 
	
	# Dispara 5 balas
	for i in range(5):
		if is_dead: break
		
		# --- CORREÇÃO AQUI ---
		atirar_bala() # <--- Agora chama a função que você já tem!
		# ---------------------
		
		# Tempo entre cada tiro (tra-ta-ta-ta)
		await get_tree().create_timer(0.2).timeout
	
	# Espera um tempinho extra após os tiros para ele "baixar a arma"
	await get_tree().create_timer(0.5).timeout
	
	# Destrava o robô manualmente para ele não travar
	print("Boss: Fim da rajada, destravando...")
	is_attacking = false
	sprite.play("parado")
	
func atirar_bala():
	var tiro = CENA_BALA.instantiate()
	
	# 1. Define onde nasce (PontoBraco)
	tiro.global_position = ponto_braco.global_position
	
	# 2. CALCULA A MIRA (A parte importante)
	if player_alvo:
		# Cria um vetor que aponta do Braço -> para o Jogador
		var direcao_mira = ponto_braco.global_position.direction_to(player_alvo.global_position)
		tiro.direcao = direcao_mira
		
		# (Opcional) Faz a bala GIRAR visualmente para apontar para o jogador
		tiro.rotation = direcao_mira.angle()
	else:
		# Se não tiver alvo, atira reto na direção que o boss está olhando
		tiro.direcao = Vector2.RIGHT if direction == 1 else Vector2.LEFT
	
	# 3. Solta a bala no mundo
	get_parent().add_child(tiro)
# --- ATAQUE 2: LASER (Hit Kill) ---
func ataque_laser_peito():
	print("Boss: CARREGANDO LASER!")
	pode_usar_laser = false
	recuperar_laser_10s()
	
	sprite.play("atacando missel")
	modulate = Color(3, 0, 0) 
	
	# Tempo carregando
	await get_tree().create_timer(1.5).timeout 
	
	print("Boss: DISPARO!")
	modulate = Color(1, 1, 1)
	visual_laser.visible = true
	laser_peito.monitoring = true
	
	# Dano
	var corpos = laser_peito.get_overlapping_bodies()
	for corpo in corpos:
		if corpo.is_in_group("jogador") and corpo.has_method("levar_dano"):
			corpo.levar_dano(999)
	
	# Duração do Laser ligado
	await get_tree().create_timer(0.5).timeout
	
	visual_laser.visible = false
	laser_peito.monitoring = false
	
	# --- MUDANÇA AQUI ---
	# Em vez de esperar a animação (que pode travar), esperamos um tempinho extra
	# e forçamos o robô a voltar ao normal.
	await get_tree().create_timer(0.5).timeout
	
	# Destrava o ataque manualmente
	is_attacking = false
	sprite.play("parado")
func recuperar_laser_10s():
	await get_tree().create_timer(10.0).timeout
	pode_usar_laser = true

# --- COMBATE (Dano e Morte) ---
func levar_dano(dano: int):
	if is_dead: return
	vida -= dano
	
	# Pisca vermelho
	modulate = Color(10, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if vida <= 0: morrer()

func morrer():
	if is_dead: return
	is_dead = true
	timer_cerebro.stop()
	velocity = Vector2.ZERO
	
	$CollisionShape2D.set_deferred("disabled", true)
	if laser_peito: laser_peito.set_deferred("monitoring", false)
	if visual_laser: visual_laser.visible = false
	
	sprite.play("morrendo")
	await sprite.animation_finished
	
	await get_tree().create_timer(1.0).timeout
	
	# Vitória
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud: Global.tempo_da_partida = hud.parar_e_pegar_tempo()
	get_tree().change_scene_to_file("res://TelaVitoria.tscn")

# --- DETECÇÃO (Herdado do soldado, caso use Area2D Detector) ---
func _on_detector_body_entered(body):
	if body.is_in_group("jogador"):
		player_alvo = body
