extends CanvasLayer

@onready var label_tempo = $LabelTempo # Certifique-se que o Label existe na cena

var tempo_decorrido: float = 0.0
var cronometro_ativo: bool = true

func _process(delta):
	# Só conta se o cronômetro estiver ligado
	if cronometro_ativo:
		# 'delta' é o tempo que passou desde o último frame (fração de segundos)
		tempo_decorrido += delta
		atualizar_texto()

func atualizar_texto():
	# Matemática para transformar números quebrados em Minutos:Segundos:Milissegundos
	var milisegundos = fmod(tempo_decorrido, 1) * 1000
	var segundos = fmod(tempo_decorrido, 60)
	var minutos = tempo_decorrido / 60
	
	# Formatação estilo ranking: 02:15.340
	# %02d = 2 dígitos inteiros
	# %03d = 3 dígitos (para milissegundos)
	label_tempo.text = "%02d:%02d.%03d" % [minutos, segundos, milisegundos]

# Função para parar o tempo quando chegar no final da fase
func parar_e_pegar_tempo():
	cronometro_ativo = false
	return tempo_decorrido
