extends CharacterBody2D

# --- Constantes ---
const VELOCIDADE_ANDAR: float = 20.0 
const GRAVIDADE: float = 400.0 
const INTERVALO_ATAQUES: float = 2.0

# --- PRELOADS ---
const CENA_BALA = preload("res://bala.tscn")

# --- Variáveis de Estado ---
var vida_max: int = 1
var vida_atual: int = 1
var is_dead: bool = false
var is_attacking: bool = false

# --- Variáveis de Poderes ---
var pode_usar_laser: bool = true 

# --- Variáveis de IA ---
var timer_cerebro: Timer
var player_alvo: Node2D = null

# --- Referências ---
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var ponto_braco: Marker2D = get_node_or_null("PontoBraco")
@onready var laser_peito: Area2D = get_node_or_null("LaserPeito")
@onready var visual_laser: ColorRect = get_node_or_null("LaserPeito/ColorRect")

func _ready():
	vida_atual = vida_max
	add_to_group("inimigos")
	
	player_alvo = get_tree().get_first_node_in_group("jogador")
	
	if laser_peito: laser_peito.monitoring = false
	if visual_laser: visual_laser.visible = false
	
	timer_cerebro = Timer.new()
	timer_cerebro.wait_time = INTERVALO_ATAQUES
	timer_cerebro.autostart = true
	timer_cerebro.timeout.connect(_on_timer_cerebro_timeout)
	add_child(timer_cerebro)
	
	sprite.play("parado")

func _physics_process(delta: float):
	if is_dead: return

	if not is_on_floor():
		velocity.y += GRAVIDADE * delta

	if is_attacking:
		velocity.x = 0 
	elif player_alvo:
		var dir_x = global_position.direction_to(player_alvo.global_position).x
		var direcao = 1 if dir_x > 0 else -1
		
		velocity.x = direcao * VELOCIDADE_ANDAR
		virar_boss(direcao)
	
	move_and_slide()

func virar_boss(direcao: int):
	if direcao > 0: # Direita
		sprite.flip_h = false 
		if ponto_braco: ponto_braco.position.x = abs(ponto_braco.position.x)
		if laser_peito: laser_peito.scale.x = 1
	else: # Esquerda
		sprite.flip_h = true
		if ponto_braco: ponto_braco.position.x = -abs(ponto_braco.position.x)
		if laser_peito: laser_peito.scale.x = -1

func _on_timer_cerebro_timeout():
	if is_attacking or is_dead or not player_alvo: return
	
	var distancia = global_position.distance_to(player_alvo.global_position)
	if distancia > 600: return 

	is_attacking = true
	var sorteio = randi() % 3
	
	if sorteio == 0 and pode_usar_laser:
		ataque_laser()
	else:
		ataque_metralhadora()

# --- ATAQUES ---
func ataque_metralhadora():
	print("Boss: Rajada!")
	sprite.stop()
	sprite.play("atacando arma")
	
	for i in range(5):
		if is_dead: return 
		atirar_bala()
		await get_tree().create_timer(0.2).timeout
	
	await get_tree().create_timer(0.5).timeout
	if is_dead: return 
	
	is_attacking = false
	sprite.play("parado")

func atirar_bala():
	if not ponto_braco or not CENA_BALA: return
	
	var tiro = CENA_BALA.instantiate()
	tiro.global_position = ponto_braco.global_position
	
	if player_alvo:
		tiro.direcao = (player_alvo.global_position - ponto_braco.global_position).normalized()
	
	get_parent().add_child(tiro)

func ataque_laser():
	print("Boss: LASER!")
	pode_usar_laser = false
	recuperar_laser_10s()
	
	sprite.stop()
	sprite.play("atacando missel")
	modulate = Color(3, 0, 0)
	
	await get_tree().create_timer(1.5).timeout
	if is_dead: return 
	
	modulate = Color(1, 1, 1)
	if visual_laser: visual_laser.visible = true
	if laser_peito: laser_peito.monitoring = true
	
	if laser_peito:
		var corpos = laser_peito.get_overlapping_bodies()
		for corpo in corpos:
			if corpo.is_in_group("jogador") and corpo.has_method("levar_dano"):
				corpo.levar_dano(999)
	
	await get_tree().create_timer(0.5).timeout
	if is_dead: return 
	
	if visual_laser: visual_laser.visible = false
	if laser_peito: laser_peito.monitoring = false
	
	await get_tree().create_timer(0.5).timeout
	if is_dead: return 
	
	is_attacking = false
	sprite.play("parado")

func recuperar_laser_10s():
	await get_tree().create_timer(10.0).timeout
	pode_usar_laser = true
	print("Boss: Laser pronto!")

# --- COMBATE E MORTE ---
func levar_dano(dano: int):
	if is_dead: return
	vida_atual -= dano
	modulate = Color(10, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	if vida_atual <= 0: morrer()

func morrer():
	if is_dead: return
	
	print("BOSS: Iniciando morte...")
	is_dead = true
	
	timer_cerebro.stop()
	velocity = Vector2.ZERO
	
	$CollisionShape2D.set_deferred("disabled", true)
	if laser_peito: laser_peito.set_deferred("monitoring", false)
	if visual_laser: visual_laser.visible = false
	
	sprite.stop()
	sprite.play("morrendo")
	
	# Lembre-se de tirar o Loop da animação no editor!
	await sprite.animation_finished
	
	print("BOSS: Destruído. Aguardando 5s...")
	await get_tree().create_timer(5.0).timeout
	
	# --- AJUSTADO PARA NOMES MINÚSCULOS AQUI ---
	var hud = get_tree().current_scene.get_node_or_null("hud") # "hud" minúsculo
	
	if hud and Global:
		Global.tempo_da_partida = hud.parar_e_pegar_tempo()
		print("Tempo salvo!")
	else:
		print("AVISO: 'hud' (minúsculo) não encontrado ou Global ausente.")
	
	# Caminho exato do arquivo
	get_tree().change_scene_to_file("res://tela_vitoria.tscn")
