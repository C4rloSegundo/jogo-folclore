extends CharacterBody2D

# --- Constantes de Física ---
const VELOCIDADE_ANDAR: float = 150.0
const FORCA_PULO: float = -300.0
const GRAVIDADE: float = 400.0

# --- Variáveis de Estado ---
var vida_max: int = 3
var vida_atual: int = 3
var ultimo_checkpoint_pos: Vector2

# --- Sinais ---
signal saude_mudou(vida_atual: int)

# --- Referências de Nós ---
#
# ------------------------------------------------------------------
#  ✅ CORREÇÃO PRINCIPAL AQUI:
#  Atualizando TODOS os caminhos para refletir sua cena, onde
#  o sprite E o hitbox estão DENTRO do nó "curumim".
# ------------------------------------------------------------------
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox_ataque: Area2D = $Hitboxataque
@onready var shape_ataque = $Hitboxataque/CollisionShape2D
#
#

# Chamado assim que a cena entra na árvore
func _ready():
	vida_atual = vida_max
	ultimo_checkpoint_pos = global_position
	print("Personagem pronto!")
	
	# Esta linha agora vai funcionar
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
		
		# Esta linha agora vai funcionar
		shape_ataque.disabled = false
	
	elif sprite.animation != "atacando" or not sprite.is_playing():
		
		# Esta linha agora vai funcionar
		shape_ataque.disabled = true
		
		if not is_on_floor():
			sprite.play("pulando")
			sprite.position.y = 0 
			
		elif direcao != 0:
			sprite.play("andando")
			sprite.position.y = 0 # (Seu ajuste)
			
		else:
			sprite.play("parado")
			sprite.position.y = 0 

	# Aplica o movimento
	move_and_slide()


# --- Funções de Combate ---
func levar_dano(dano: int):
	vida_atual -= dano
	saude_mudou.emit(vida_atual)
	print("Personagem tomou dano! Vidas restantes: ", vida_atual)
	if vida_atual <= 0:
		morrer()

func morrer():
	print("PERSONAGEM MORREU!")
	get_tree().reload_current_scene()


# --- Conexão de Sinal ---
#func _on_hitbox_ataque_area_entered(area):
# --- Conexão de Sinal ---
# (Conecte o sinal "body_entered" a esta função)
func _on_hitbox_ataque_area_entered(body): # Mudei o nome do parâmetro para 'body'
	
	print("Hitbox acertou um CORPO: ", body.name)

	# Precisamos checar se o corpo que acertamos é um inimigo
	# (pois ele pode ter acertado o jogador ou o chão).
	# A forma mais segura é checar se ele TEM a função "levar_dano".
	if body.has_method("levar_dano"):
		
		# ✅ CORREÇÃO: Chamamos 'levar_dano' DIRETAMENTE no 'body'.
		body.levar_dano(1)
