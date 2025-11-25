extends CharacterBody2D

# --- Variáveis de Patrulha ---
@export var speed = 40.0
var gravity = 1000.0 # Define a gravidade para o inimigo
var direction = -1     # Começa andando para a esquerda

# --- Variáveis de Combate ---
var vida: int = 3 # O inimigo tem 3 pontos de vida
var is_dead: bool = false # <-- NOVO: Adicione esta "trava"

# --- Referências de Nós ---
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var detector_parede: RayCast2D = $detector_parede
@onready var detector_abismo: RayCast2D = $detector_abismo


# --- Funções de Combate ---

# Chamada pelo "Hurtbox" do inimigo quando for atingido
func levar_dano2(dano: int):
	vida -= dano
	print("Inimigo tomou dano! Vida restante: ", vida)
	
	if vida <= 0:
		morrer()
func levar_dano(dano: int):
	# Não pode levar dano se já estiver morto
	if is_dead:
		return
		
	vida -= dano
	print("Inimigo tomou dano! Vida restante: ", vida)
	
	if vida <= 0:
		morrer()

func morrer2():
	print("Inimigo derrotado!")
	queue_free() # Remove o inimigo da cenafunc morrer()	# Se já chamamos 'morrer', não faça nada (evita bugs	if is_dead		retur	is_dead = tru	# 1. Pare toda a lógica de IA e físic	set_physics_process(false	# 2. Desligue as colisões para o jogador não bater nel	$CollisionShape2D.disabled = tru	$Hurtbox.disabled = true # Desliga a Area2	# 3. Toque a animação de mort	sprite.play("morrendo") # <-- Use o nome da sua animaçã	# 4. ESPERE a animação "morrendo" termina	await sprite.animation_finishe	# 5. Só DEPOIS que a animação terminar, remova o inimig	queue_free(# --- Lógica de Física (Patrulha) --
# ✅ FUNÇÃO MORRER (ATUALIZADA)
func morrer():
	# Se já chamamos 'morrer', não faça nada (evita bugs)
	if is_dead:
		return
	is_dead = true
	
	# 1. Pare toda a lógica de IA e física
	set_physics_process(false)
	
	# 2. Desligue as colisões para o jogador não bater nele
	$CollisionShape2D.disabled = true # Desliga a colisão do CORPO
	
	# ⬇️⬇️ A CORREÇÃO ESTÁ AQUI ⬇️⬇️
	# Nós desabilitamos o CollisionShape2D que está DENTRO do Hurtbox
	$Hurtbox/CollisionShape2D.disabled = true 
	
	# 3. Toque a animação de morte
	sprite.play("morrendo") # <-- Use o nome da sua animação

	# 4. ESPERE a animação "morrendo" terminar
	await sprite.animation_finished
	
	# 5. Só DEPOIS que a animação terminar, remova o inimigo
	queue_free()




func _physics_process(delta):
	# 1. Aplicar Gravidade
#	if not is_on_floor():
#		velocity.y += gravity * delta

	# 2. Lógica para Virar (Checar *antes* de mover)
	
	# Ajusta os sensores e o sprite para a direção atual
	if direction == 1: # Indo para a direita
		sprite.flip_h = false
		detector_parede.target_position.x = 16 # Aponta o raio para a direita
		detector_abismo.position.x = 16        # Move o raio para a borda direita
	else: # Indo para a esquerda
		sprite.flip_h = true
		detector_parede.target_position.x = -16 # Aponta o raio para a esquerda
		detector_abismo.position.x = -16       # Move o raio para a borda esquerda

	# 3. Checar Sensores e Mudar Direção
	# Só vira se estiver no chão E (bater na parede OU não achar chão na frente)
	if is_on_floor() and (detector_parede.is_colliding() or not detector_abismo.is_colliding()):
		direction *= -1 # Inverte a direção (1 vira -1, -1 vira 1)

	# 4. Definir Velocidade Horizontal
	velocity.x = speed * direction

	# 5. Mover o Inimigo
	move_and_slide()


# --- Sinais Conectados (do guia_cena_soldado.md) ---

# Esta função é conectada ao sinal "body_entered" da "HitboxDano"
# Ela é chamada quando o Soldado TOCA no jogador
func _on_hitbox_dano_body_entered(body):
	# Verifica se o corpo que entrou está no grupo "jogador"
	if body.is_in_group("jogador"):
		# Chama a função "levar_dano" que existe no script do jogador
		body.levar_dano(1)


# Esta função é conectada ao sinal "area_entered" da "Hurtbox"
# Ela é chamada quando o Soldado é ATINGIDO pelo ataque do jogador
func _on_hurtbox_area_entered(area):
	# Verifica se a área que nos atingiu é a "HitboxAtaque" do jogador
	# (O nome "HitboxAtaque" deve estar correto na cena do personagem)
	if area.name == "HitboxAtaque":
		levar_dano(1) # Chama a função de dano deste próprio script
