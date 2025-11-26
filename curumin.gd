extends CharacterBody2D

# --- Constantes de Física ---
const VELOCIDADE_ANDAR: float = 150.0
const FORCA_PULO: float = -300.0
const GRAVIDADE: float = 400.0

# --- Variáveis de Estado ---
var vida_max: int = 3
var vida_atual: int = 3
var ultimo_checkpoint_pos: Vector2
var esta_invencivel: bool = false # NOVO: Controla se pode levar dano

# --- Sinais ---
signal saude_mudou(vida_atual: int)

# --- Referências de Nós ---
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox_ataque: Area2D = $Hitboxataque
@onready var shape_ataque = $Hitboxataque/CollisionShape2D
# NOVO: Referência ao Timer (Certifique-se que o nome na árvore é igual!)
@onready var timer_invencibilidade: Timer = $TimerInvencibilidade 

# Chamado assim que a cena entra na árvore
func _ready():
	vida_atual = vida_max
	ultimo_checkpoint_pos = global_position
	print("Personagem pronto!")
	
	shape_ataque.disabled = true

# Chamado a cada frame de física
func _physics_process(delta: float):
	
	# --- Gravidade ---
	if not is_on_floor():
		velocity.y += GRAVIDADE * delta

	# --- Lógica de Pulo ---
	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = FORCA_PULO

	# --- Lógica de Movimento (Esquerda/Direita) ---
	var direcao = Input.get_axis("esquerda", "direita")
	velocity.x = direcao * VELOCIDADE_ANDAR
	
	# Vira o sprite para a direção correta
	if direcao > 0:
		sprite.flip_h = false
	elif direcao < 0:
		sprite.flip_h = true
	
	# --- Lógica de Animação e Ataque ---
	if Input.is_action_just_pressed("atacar"):
		sprite.play("atacando")
		sprite.position.y = 0 
		shape_ataque.disabled = false
	
	elif sprite.animation != "atacando" or not sprite.is_playing():
		shape_ataque.disabled = true
		
		if not is_on_floor():
			sprite.play("pulando")
			sprite.position.y = 0 
		elif direcao != 0:
			sprite.play("andando")
			sprite.position.y = 0
		else:
			sprite.play("parado")
			sprite.position.y = 0 

	move_and_slide()

# --- Funções de Combate ---

# ALTERADO: Agora verifica invencibilidade antes de aplicar dano
func levar_dano(dano: int):
	# 1. Se já estiver invencível, ignora o dano e sai da função
	if esta_invencivel:
		return

	# 2. Aplica o dano normalmente
	vida_atual -= dano
	saude_mudou.emit(vida_atual)
	print("Personagem tomou dano! Vidas restantes: ", vida_atual)
	
	if vida_atual <= 0:
		morrer()
	else:
		# 3. Se ainda está vivo, fica invencível por um tempo
		iniciar_invencibilidade()

func morrer():
	print("PERSONAGEM MORREU!")
	# Muda para a cena de Game Over
	# Certifique-se de salvar a cena de morte como "tela_morte.tscn"
	get_tree().change_scene_to_file("res://tela_de_morte.tscn")

# NOVO: Função para ativar o modo "fantasma"
func iniciar_invencibilidade():
	esta_invencivel = true
	timer_invencibilidade.start() # Inicia o relógio
	modulate.a = 0.5 # Deixa o personagem 50% transparente

# NOVO: Esta função deve estar conectada ao sinal "timeout" do Timer
func _on_timer_invencibilidade_timeout() -> void:
	esta_invencivel = false
	modulate.a = 1.0 # Volta a cor normal (100% opaco)
	print("Invencibilidade acabou.")

# --- Conexão de Sinal (Ataque do Player) ---
func _on_hitbox_ataque_area_entered(body): 
	print("Hitbox acertou um CORPO: ", body.name)
	if body.has_method("levar_dano"):
		body.levar_dano(1)

func curar_total():
	vida_atual = vida_max
	saude_mudou.emit(vida_atual)
	ultimo_checkpoint_pos = global_position 
	print("Checkpoint salvo! Vida recuperada.")
	
