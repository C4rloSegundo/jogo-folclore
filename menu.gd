extends Control

func _on_btn_jogar_pressed():
	# Carrega a sua primeira fase
	# DICA: Arraste o arquivo da fase aqui para garantir o caminho certo
	get_tree().change_scene_to_file("res://demofloresta.tscn")

func _on_btn_sair_pressed():
	# Fecha o jogo
	get_tree().quit()
