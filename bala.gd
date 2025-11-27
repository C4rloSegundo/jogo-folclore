extends Area2D

var velocidade = 400
var direcao = Vector2.RIGHT # Importante ser Vector2, não int!

func _ready():
	await get_tree().create_timer(3.0).timeout
	queue_free()
	
func _process(delta):
	position += direcao * velocidade * delta
	
	# ISSO AQUI FAZ A MÁGICA:
	# A bala olha para a posição atual + a direção que ela está indo
	look_at(position + direcao)

func _on_body_entered(body):
	# DEBUG: Vamos ver no que a bala está batendo
	print("Bala bateu em: ", body.name) 
	
	# 1. PROTEÇÃO TOTAL: Se for o Boss, sai da função imediatamente
	if body.name == "RoboBoss" or body == get_parent(): 
		return

	# 2. Se for o jogador
	if body.is_in_group("jogador") and body.has_method("levar_dano"):
		body.levar_dano(1)
		queue_free()
	
	# 3. Se for parede (TileMap)
	elif body is TileMap or body is StaticBody2D:
		queue_free()
