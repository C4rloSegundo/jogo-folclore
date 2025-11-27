extends Control

# ATENÇÃO: Verifique se o caminho do nó está correto para a sua cena!
# Se der erro, apague o caminho, arraste o Label da árvore para aqui.
@onready var label_tempo_final = $UI_Container/ContainerStats/LabelTempoFinal

func _ready():
	# 1. Recupera o valor do Global
	var tempo = Global.tempo_da_partida
	
	# 2. Formata para texto (00:00.000)
	var texto_formatado = formatar_tempo(tempo)
	
	# 3. Mostra na tela (A CORREÇÃO FOI FEITA AQUI)
	# Usamos "+" para juntar o texto fixo com a variável formatada
	label_tempo_final.text = "SEU TEMPO: " + texto_formatado

# Função auxiliar de formatação
func formatar_tempo(t: float) -> String:
	var minutos = int(t / 60)
	var segundos = int(fmod(t, 60))
	var milis = int(fmod(t, 1) * 1000)
	return "%02d:%02d.%03d" % [minutos, segundos, milis]
	
func _on_btn_sair_pressed():
	get_tree().quit()


func _on_btn_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
