extends CharacterBody2D

# --- Configurações ---
@export var speed: float = 20.0
@export var gravity: float = 10.0
@export var intervalo_ataques: float = 2.0 

# --- Estado ---
var vida: int = 50
var vida_max: int = 50
var is_dead: bool = false
var is_attacking: bool = false 

# --- Projéteis ---
const CENA_BALA = preload("res://bala.tscn")

# Controle do Laser (Cooldown)
var pode_usar_laser: bool = true

# --- Referências ---
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var player_alvo: Node2D = get_tree().get_first_node_in_group("jogador")

# --- CORREÇÃO AQUI: Usamos os nomes novos ---
@onready var ponto_braco = $PontoBraco
@onready var laser_peito = $LaserPeito
@onready var visual_laser = $LaserPeito/ColorRect
@onready var ponto_peito = $PontoPeito # (Opcional, caso use misseis no futuro)

var timer_cerebro: Timer

func _ready():
	vida = vida_max
	sprite.play("parado")
	
	laser_peito.monitoring = false
	visual_laser.visible = false
	
	timer_cerebro = Timer.new()
	timer_cerebro.wait_time = intervalo_ataques
	timer_cerebro.autostart = true
	timer_cerebro.timeout.connect(_on_timer_cerebro_timeout)
	add_child(timer_cerebro)

func _physics_process(delta):
	if is_dead: return

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_attacking:
		velocity.x = 0
		move_and_slide()
		return 

	if player_alvo:
		var dir_x = global_position.direction_to(player_alvo.global_position).x
		var direcao = 1 if dir_x > 0 else -1
		velocity.x = speed * direcao
		virar_boss(direcao)
	
	move_and_slide()

# --- FUNÇÃO CORRIGIDA ---
func virar_boss(direcao: int):
	if direcao > 0:
		sprite.flip_h = true  # Direita
		ponto_braco.position.x = abs(ponto_braco.position.x)
		laser_peito.scale.x = -1 
	else:
		sprite.flip_h = false # Esquerda
		ponto_braco.position.x = -abs(ponto_braco.position.x)
		laser_peito.scale.x = 1 

func _on_timer_cerebro_timeout():
	if is_attacking or is_dead or not player_alvo: return
	
	is_attacking = true
	var sorteio = randi() % 3
	
	if sorteio == 0 and pode_usar_laser:
		await ataque_laser_peito()
	else:
		await ataque_metralhadora_braco()
	
	if not is_dead:
		is_attacking = false
		sprite.play("parado")

func ataque_metralhadora_braco():
	print("Boss: Metralhadora!")
	sprite.play("atacando arma") 
	
	for i in range(5):
		if is_dead: break
		criar_bala()
		await get_tree().create_timer(0.2).timeout
	
	await get_tree().create_timer(0.5).timeout
	await sprite.animation_finished

func criar_bala():
	var bala = CENA_BALA.instantiate()
	# CORREÇÃO: Usando ponto_braco
	bala.global_position = ponto_braco.global_position
	if player_alvo:
		var direcao = (player_alvo.global_position - ponto_braco.global_position).normalized()
		bala.direcao = direcao
	get_parent().add_child(bala)

func ataque_laser_peito():
	print("Boss: CARREGANDO LASER!")
	pode_usar_laser = false
	recuperar_laser_10s()
	
	sprite.play("atacando missel")
	modulate = Color(2, 0, 0)
	
	await get_tree().create_timer(1.5).timeout
	
	print("Boss: DISPARO DE LASER!")
	modulate = Color(1, 1, 1)
	visual_laser.visible = true
	laser_peito.monitoring = true
	
	var corpos = laser_peito.get_overlapping_bodies()
	for corpo in corpos:
		if corpo.is_in_group("jogador") and corpo.has_method("levar_dano"):
			corpo.levar_dano(999) 
	
	await get_tree().create_timer(0.5).timeout
	
	visual_laser.visible = false
	laser_peito.monitoring = false
	
	await sprite.animation_finished

func recuperar_laser_10s():
	await get_tree().create_timer(10.0).timeout
	pode_usar_laser = true
	print("Boss: Laser Recarregado!")

func levar_dano(dano: int):
	if is_dead: return
	vida -= dano
	modulate = Color(10, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	if vida <= 0: morrer()

func morrer():
	is_dead = true
	timer_cerebro.stop()
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	visual_laser.visible = false
	laser_peito.set_deferred("monitoring", false)
	
	sprite.play("morrendo")
	
	await sprite.animation_finished
	await get_tree().create_timer(1.0).timeout
	
	var hud = get_tree().current_scene.get_node("HUD")
	if hud: Global.tempo_da_partida = hud.parar_e_pegar_tempo()
	get_tree().change_scene_to_file("res://TelaVitoria.tscn")
