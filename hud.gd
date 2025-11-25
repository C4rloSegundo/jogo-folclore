extends HBoxContainer

# Esta função será chamada pelo sinal do Player
func _on_player_saude_mudou(vida_atual: int):
	# Pega todos os corações (filhos deste nó)
	var coracoes = get_children()
	
	# Loop para ligar ou desligar cada coração
	for i in range(coracoes.size()):
		# Se o índice (0, 1, 2) for menor que a vida atual, mostra. Senão, esconde.
		if i < vida_atual:
			coracoes[i].visible = true
		else:
			coracoes[i].visible = false
