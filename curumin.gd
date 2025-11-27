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

# Variáveis de Controlo
var pode_atirar: bool = true
var tempo_recarga_tiro: float = 0.5 
var timer_cooldown: Timer 

# --- ESCUDO (NOVO) ---
var escudo_ativo: Node2D = null
var pode_usar_escudo: bool = true
var duracao_escudo: float = 2.0 # Tempo que fica ligado
var cooldown_escudo: float = 3.0 # Tempo para recarregar depois de usar
var timer_duracao_escudo: Timer
var timer_cooldown_escudo: Timer

signal saude_mudou(vida_atual: int)

# --- Referências ---
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox_ataque: Area2D = get_node_or_null("Hitboxataque")
@onready var shape_ataque = get_node_or_null("Hitboxataque/CollisionShape2D")
@onready var timer_invencibilidade: Timer = $TimerInvencibilidade 
@onready var ponto_tiro: Marker2D = get_node_or_null("PontoTiro")
@onready var ponto_efeito_pulo: Marker2D = get_node_or_null("PontoEfeitoPulo")
@onready var ponto_escudo: Marker2D = get_node_or_null("PontoEscudo")

func _ready():
	vida_atual = vida_max
	if shape_ataque: shape_ataque.disabled = true
	add_to_group("jogador")
	
	# Timer Tiro
	timer_cooldown = Timer.new()
	timer_cooldown.wait_time = tempo_recarga_tiro
	timer_cooldown.one_shot = true 
	timer_cooldown.timeout.connect(_on_cooldown_acabou)
	add_child(timer_cooldown)
	
	# Timer Duração Escudo (Quanto tempo fica ligado)
	timer_duracao_escudo = Timer.new()
	timer_duracao_escudo.wait_time = duracao_escudo
	timer_duracao_escudo.one_shot = true
	timer_duracao_escudo.timeout.connect(_on_escudo_acabou)
	add_child(timer_duracao_escudo)
	
	# Timer Cooldown Escudo (Quanto tempo espera para usar de novo)
	timer_cooldown_escudo = Timer.new()
	timer_cooldown_escudo.wait_time = cooldown_escudo
	timer_cooldown_escudo.one_shot = true
	timer_cooldown_escudo.timeout.connect(_on_escudo_recarregado)
	add_child(timer_cooldown_escudo)

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y += GRAVIDADE * delta
	else:
		pulos_realizados = 0 

	# --- PULO ---
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
		if ponto_escudo: ponto_escudo.position.x = abs(ponto_escudo.position.x)
	elif direcao < 0: 
		sprite.flip_h = true
		if hitbox_ataque: hitbox_ataque.position.x = -abs(hitbox_ataque.position.x)
		if ponto_tiro: ponto_tiro.position.x = -abs(ponto_tiro.position.x)
		if ponto_escudo: ponto_escudo.position.x = -abs(ponto_escudo.position.x)
	
	if is_instance_valid(escudo_ativo) and ponto_escudo:
		escudo_ativo.position = ponto_escudo.position
	
	# --- ATAQUE ---
	if Input.is_action_just_pressed("atacar"):
		if pode_atirar:
			sprite.play("atacando")
			if shape_ataque: shape_ataque.disabled = false
			criar_bola_de_fogo()
			pode_atirar = false
			timer_cooldown.start()
	
	# --- ESCUDO ---
	elif Input.is_action_just_pressed("escudo"):
		if tem_escudo_fogo and pode_usar_escudo:
			ativar_escudo()
	
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

# --- LÓGICA DO ESCUDO ---
func ativar_escudo():
	if is_instance_valid(escudo_ativo): return # Já está ligado
	
	if not ponto_escudo: return
	
	# Liga o escudo
	escudo_ativo = CENA_ESCUDO.instantiate()
	escudo_ativo.scale = Vector2(1.5, 1.5)
	escudo_ativo.position = ponto_escudo.position
	add_child(escudo_ativo)
	print("Escudo LIGADO (Duração: 2s)")
	
	# Começa a contar o tempo de vida
	timer_duracao_escudo.start()
	
	# Impede de usar de novo imediatamente (inicia recarga)
	pode_usar_escudo = false

func _on_escudo_acabou():
	# O tempo acabou, desliga o escudo
	if is_instance_valid(escudo_ativo):
		escudo_ativo.queue_free()
		escudo_ativo = null
		print("Escudo DESLIGADO (Tempo Esgotado)")
	
	# Inicia o tempo de recarga para poder usar de novo
	timer_cooldown_escudo.start()

func _on_escudo_recarregado():
	pode_usar_escudo = true
	print("Escudo PRONTO para usar novamente!")

# --- RESTO ---
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

func desbloquear_pulo_duplo():
	tem_pulo_duplo = true
	print("PODER: Pulo Duplo!")

func desbloquear_poder_fogo():
	tem_poder_fogo = true
	print("PODER: Fogo Final!")

func desbloquear_escudo_fogo():
	if not tem_escudo_fogo:
		tem_escudo_fogo = true
		print("PODER: Escudo (Tecla Q)!")

func criar_efeito_pulo():
	if not CENA_EFEITO_PULO or not ponto_efeito_pulo: return
	var efeito = CENA_EFEITO_PULO.instantiate()
	efeito.position = ponto_efeito_pulo.position
	add_child(efeito)

func levar_dano(dano: int):
	if esta_invencivel: return
	# Se tiver escudo ligado, protege!
	if is_instance_valid(escudo_ativo):
		print("Escudo bloqueou o dano!")
		return
		
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
