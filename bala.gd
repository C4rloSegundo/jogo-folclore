extends Area2D

var velocidade = 600 # Bala é rápida!
var direcao = Vector2.LEFT 
var dano = 1

func _process(delta):
	position += direcao * velocidade * delta

func _on_body_entered(body):
	if body.is_in_group("jogador") and body.has_method("levar_dano"):
		body.levar_dano(dano)
		queue_free()
	elif body.name != "RoboBoss": # Ignora o próprio chefe
		queue_free() # Some na parede
