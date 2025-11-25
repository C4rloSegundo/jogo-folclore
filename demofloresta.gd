extends Node2D

# Este script fica no nó raiz "DemoFloresta".
# A sua única função, por agora, é gerir a Zona de Morte.


# Esta função foi criada automaticamente quando conectou o sinal
# "body_entered" da sua "ZonaDeMorte".
# Ela é chamada sempre que um corpo físico (como o Personagem)
# entra nessa área.
func _on_zona_de_morte_body_entered(body):
	
	# Verificamos se o corpo que entrou está no grupo "jogador"
	# (Lembre-se que definimos este grupo no guia_cena_personagem.md)
	if body.is_in_group("jogador"):
		
		# Se for o jogador, chamamos a função "morrer()"
		# que já existe no script do Personagem.
		print("Jogador caiu na Zona de Morte!")
		body.morrer()
		
