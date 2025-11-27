extends CanvasLayer

# Usamos 'get_node_or_null' para evitar crash se o nome estiver errado
@onready var label_tempo = get_node_or_null("LabelTempo") 

var tempo_decorrido: float = 0.0
var cronometro_ativo: bool = true

func _ready():
	# Garante que o tempo zera sempre que a fase reinicia
	tempo_decorrido = 0.0
	cronometro_ativo = true

func _process(delta):
	# Só conta se o cronômetro estiver ligado
	if cronometro_ativo:
		tempo_decorrido += delta
		
		# Só tenta atualizar o texto se o Label existir na cena
		if label_tempo:
			atualizar_texto()

func atualizar_texto():
	var minutos = int(tempo_decorrido / 60)
	var segundos = int(fmod(tempo_decorrido, 60))
	var milisegundos = int(fmod(tempo_decorrido, 1) * 1000)
	
	# Formatação: 02:15.340
	label_tempo.text = "%02d:%02d.%03d" % [minutos, segundos, milisegundos]

# --- FUNÇÃO IMPORTANTE ---
# Esta é a função que o ROBO BOSS chama quando morre
func parar_e_pegar_tempo():
	cronometro_ativo = false # Congela o relógio
	return tempo_decorrido   # Entrega o valor para quem pediu (Boss)
