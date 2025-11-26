extends Control

func _ready():
	# (Opcional) Foca no botão de reiniciar para poder usar controle/teclado
	$VBoxContainer/BtnReiniciar.grab_focus()

func _on_btn_reiniciar_pressed():
	# Recarrega a fase onde o jogador estava
	# ATENÇÃO: Substitua "fase1.tscn" pelo nome do arquivo da sua fase!
	get_tree().change_scene_to_file("res://demofloresta.tscn")

func _on_btn_sair_pressed():
	get_tree().quit()
