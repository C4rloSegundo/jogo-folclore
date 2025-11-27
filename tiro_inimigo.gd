extends Area2D

@export var velocidade: float = 300.0
@export var dano: int = 1
var direcao: int = 1 

func _ready():
	# Força a conexão do sinal via código para garantir que funciona
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Conecta o sinal de sair da tela
	var notifier = get_node_or_null("VisibleOnScreenNotifier2D")
	if notifier and not notifier.screen_exited.is_connected(_on_visible_on_screen_notifier_2d_screen_exited):
		notifier.screen_exited.connect(_on_visible_on_screen_notifier_2d_screen_exited)

func _process(delta):
	position.x += velocidade * direcao * delta

func _on_body_entered(body):
	# DEBUG: Mostra no console o que o tiro tocou
	print("TIRO TOCOU EM: ", body.name)
	
	# Ignora se bater no próprio inimigo (para não se matar)
	if body.is_in_group("inimigos") or body.name.begins_with("Inimigo"):
		return

	# Tenta acertar o Jogador
	# Verificamos de 3 formas diferentes para ter certeza
	if body.is_in_group("jogador") or body.name == "Player" or body.name == "Jogador":
		print(" >> É O JOGADOR! Causando dano...")
		
		if body.has_method("levar_dano"):
			body.levar_dano(dano)
		else:
			print("ERRO: O Jogador não tem a função 'levar_dano'!")
			
		queue_free() # Destrói o tiro
	
	# Se bater em parede/chão
	elif body is TileMap or body is TileMapLayer:
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
