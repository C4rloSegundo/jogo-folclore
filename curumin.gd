extends CharacterBody2D

# --- Constantes ---
const VELOCIDADE_ANDAR: float = 150.0
const FORCA_PULO: float = -300.0
const GRAVIDADE: float = 400.0

# --- PRELOADS ---
const CENA_BOLA_FOGO = preload("res://bola_de_fogo.tscn")
const CENA_FOGO_FINAL = preload("res://fogo_final.tscn")
const CENA_EFEITO_PULO = preload("res://efeito_pulo.tscn")
const CENA_ESCUDO = preload("res://escudo_fogo.tscn")

# --- Variáveis de Estado ---
var vida_max: int = 3
var vida_atual: int = 3
var esta_invencivel: bool = false 
var ultimo_checkpoint_pos: Vector2
# Variáveis de Poderes
var tem_pulo_duplo: bool = false 
var tem_poder_fogo: bool = false 
var tem_escudo_fogo: bool = false 
var pulos_realizados: int = 0

# Variável para guardar o escudo (IMPORTANTE PARA LIGAR/DESLIGAR)
var escudo_ativo: Node2D = null

# Variáveis de Ataque
var pode_atirar: bool = true
var tempo_recarga_tiro: float = 0.5 
var timer_cooldown: Timer 

signal saude_mudou(vida_atual: int)

# --- Referências ---
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox_ataque: Area2D = get_node_or_null("Hitboxataque")
@onready var shape_ataque = get_node_or_null("Hitboxataque/CollisionShape2D")
@onready var timer_invencibilidade: Timer = $TimerInvencibilidade 
@onready var ponto_tiro: Marker2D = get_node_or_null("PontoTiro")
@onready var ponto_efeito_pulo: Marker2D = get_node_or_null("PontoEfeitoPulo")

func _ready():
	vida_atual = vida_max
	if shape_ataque: shape_ataque.disabled = true
	add_to_group("jogador")
	
	timer_cooldown = Timer.new()
	timer_cooldown.wait_time = tempo_recarga_tiro
	timer_cooldown.one_shot = true 
	timer_cooldown.timeout.connect(_on_cooldown_acabou)
	add_child(timer_cooldown)

func _physics_process(delta: float):
	
	if not is_on_floor():
		velocity.y += GRAVIDADE * delta
	else:
		pulos_realizados = 0 

	# --- PULO DUPLO ---
	if Input.is_action_just_pressed("pular"):
		if is_on_floor():
			velocity.y = FORCA_PULO
			pulos_realizados = 1
		elif tem_pulo_duplo and pulos_realizados < 2:
			velocity.y = FORCA_PULO
			pulos_realizados += 1
			criar_efeito_pulo()

	# --- MOVIMENTO ---
	var direcao = Input.get_axis("esquerda", "direita")
	velocity.x = direcao * VELOCIDADE_ANDAR
	
	# --- VIRAR TUDO ---
	if direcao > 0: 
		sprite.flip_h = false
		if hitbox_ataque: hitbox_ataque.position.x = abs(hitbox_ataque.position.x)
		if ponto_tiro: ponto_tiro.position.x = abs(ponto_tiro.position.x)
		# Move o escudo para a direita se ele existir
		if is_instance_valid(escudo_ativo):
			escudo_ativo.position.x = abs(escudo_ativo.position.x)
			
	elif direcao < 0: 
		sprite.flip_h = true
		if hitbox_ataque: hitbox_ataque.position.x = -abs(hitbox_ataque.position.x)
		if ponto_tiro: ponto_tiro.position.x = -abs(ponto_tiro.position.x)
		# Move o escudo para a esquerda se ele existir
		if is_instance_valid(escudo_ativo):
			escudo_ativo.position.x = -abs(escudo_ativo.position.x)
	
	# --- ATAQUE ---
	if Input.is_action_just_pressed("atacar"):
		if pode_atirar:
			sprite.play("atacando")
			if shape_ataque: shape_ataque.disabled = false
			criar_bola_de_fogo()
			pode_atirar = false
			timer_cooldown.start()
	
	# --- HABILIDADE ESCUDO (Tecla definida no Input Map como "escudo") ---
	elif Input.is_action_just_pressed("escudo"):
		if tem_escudo_fogo:
			ativar_desativar_escudo()
	
	elif sprite.animation != "atacando" or not sprite.is_playing():
		if shape_ataque: shape_ataque.disabled = true
		if not is_on_floor(): sprite.play("pulando")
		elif direcao != 0: sprite.play("andando")
		else: sprite.play("parado")

	move_and_slide()
# --- NOVA FUNÇÃO DE CURA ---
func curar_total():
	vida_atual = vida_max
	saude_mudou.emit(vida_atual) # Atualiza os corações na tela
	
	# Salva a posição atual (Checkpoint)
	ultimo_checkpoint_pos = global_position
	print("Vida recuperada e Checkpoint Salvo!")
func _on_cooldown_acabou():
	pode_atirar = true 

# --- FUNÇÃO DE TIRO ---
func criar_bola_de_fogo():
	if not ponto_tiro: return
	
	var nova_bola
	if tem_poder_fogo:
		nova_bola = CENA_FOGO_FINAL.instantiate()
		if "dano" in nova_bola: nova_bola.dano = 3 
	else:
		nova_bola = CENA_BOLA_FOGO.instantiate()
	
	if sprite.flip_h: nova_bola.direcao = -1
	else: nova_bola.direcao = 1
	
	nova_bola.top_level = true
	nova_bola.global_position = ponto_tiro.global_position
	get_parent().add_child(nova_bola)

# --- LÓGICA DE LIGAR/DESLIGAR ESCUDO ---
# --- LÓGICA DE LIGAR/DESLIGAR ESCUDO ---
func ativar_desativar_escudo():
	# Se já existe, desliga
	if is_instance_valid(escudo_ativo):
		escudo_ativo.queue_free()
		escudo_ativo = null 
		print("Escudo Desligado.")
	
	# Se não existe, liga
	else:
		escudo_ativo = CENA_ESCUDO.instantiate()
		
		# --- CONFIGURAÇÕES DE AJUSTE FINO ---
		var distancia_x = 20.0  # Quão longe do corpo (Horizontal)
		var altura_y = -25.0    # Altura (Negativo = Para Cima, tente -20 ou -30)
		var tamanho = 0.6       # Escala (1.0 = Normal, 0.5 = Metade)
		
		# 1. Aplica o Tamanho
		escudo_ativo.scale = Vector2(tamanho, tamanho)
		
		# 2. Define a Posição Inicial
		if sprite.flip_h: 
			# Olhando para a Esquerda
			escudo_ativo.position = Vector2(-distancia_x, altura_y)
		else:
			# Olhando para a Direita
			escudo_ativo.position = Vector2(distancia_x, altura_y)
		
		add_child(escudo_ativo)
		print("Escudo Ligado!")

# --- DESBLOQUEIOS ---
func desbloquear_pulo_duplo():
	tem_pulo_duplo = true
	print("PODER: Pulo Duplo!")

func desbloquear_poder_fogo():
	tem_poder_fogo = true
	print("PODER: Fogo Final!")

func desbloquear_escudo_fogo():
	if not tem_escudo_fogo:
		tem_escudo_fogo = true
		print("PODER: Escudo Desbloqueado! Aperte a tecla de escudo.")

# ... (Resto igual) ...
func criar_efeito_pulo():
	if not CENA_EFEITO_PULO or not ponto_efeito_pulo: return
	var efeito = CENA_EFEITO_PULO.instantiate()
	efeito.position = ponto_efeito_pulo.position
	add_child(efeito)

func levar_dano(dano: int):
	if esta_invencivel: return
	vida_atual -= dano
	saude_mudou.emit(vida_atual)
	if vida_atual <= 0: morrer()
	else: iniciar_invencibilidade()

func morrer():
	get_tree().change_scene_to_file("res://tela_de_morte.tscn")

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
