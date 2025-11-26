extends Area2D

# Você pode mudar esse valor no Inspector para espinhos mais fortes!
@export var quantidade_dano: int = 1

func _on_body_entered(body):
	# Verifica se o corpo que entrou tem a função de tomar dano (ou seja, é o Player)
	if body.has_method("levar_dano"):
		print("Espinho atingiu: ", body.name)
		body.levar_dano(quantidade_dano)
