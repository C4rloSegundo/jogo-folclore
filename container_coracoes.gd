extends HBoxContainer

# Pode apagar _ready e _process se não for usar, para deixar o código limpo.

# Esta é a função que o sinal está chamando agora!
func _on_curumin_saude_mudou(vida_atual: int) -> void:
	# Pega a lista de todos os corações (filhos deste nó)
	var coracoes = get_children()
	
	# Passa por cada coração e verifica se deve aparecer ou sumir
	for i in range(coracoes.size()):
		if i < vida_atual:
			coracoes[i].visible = true  # Mostra o coração
		else:
			coracoes[i].visible = false # Esconde o coração
