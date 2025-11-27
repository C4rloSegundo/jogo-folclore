extends Area2D

# --- Variáveis de Interação ---
var pode_interagir: bool = false
var dialogo_ativo: bool = false
var indice_frase: int = 0
var jogador_ref: Node2D = null 

# --- O DIÁLOGO COM PERSONALIDADE ---
@export var lista_falas: Array[String] = [
	"Saci: Opa! Finalmente uma alma viva por aqui!",
	"Saci: Eu sou o Saci Pererê, o guardião desta mata.",
	"Saci: Gosto de pregar peças, mas dessa vez fui eu que caí numa armadilha...",
	"Saci: Fui preso nesta jaula por caçadores malvados que odeiam a floresta.",
	"Saci: Ei, quem é você? Parece um guerreiro forte.",
	"Saci: Escuta... Se você conseguir abrir esta jaula...",
	"Saci: Prometo que uso minha magia do redemoinho para te ajudar na jornada!"
]

# --- Referências ---
# Usamos o nome "Label" porque é o que está na tua cena
@onready var label_aviso: Label = $Label
@onready var caixa_dialogo: Control = $CaixaDialogo
@onready var texto_dialogo: Label = $CaixaDialogo/TextoDialogo

func _ready():
	# Garante que começa invisível
	if label_aviso: label_aviso.visible = false
	if caixa_dialogo: 
		caixa_dialogo.visible = false
		caixa_dialogo.z_index = 20

func _unhandled_input(event):
	if event.is_action_pressed("interagir"):
		if pode_interagir and not dialogo_ativo:
			iniciar_dialogo()
		elif dialogo_ativo:
			avancar_dialogo()

func iniciar_dialogo():
	if not caixa_dialogo: return
	
	dialogo_ativo = true
	indice_frase = 0
	
	caixa_dialogo.visible = true
	if label_aviso: label_aviso.visible = false
	
	texto_dialogo.text = lista_falas[indice_frase]

func avancar_dialogo():
	indice_frase += 1
	
	if indice_frase < lista_falas.size():
		texto_dialogo.text = lista_falas[indice_frase]
	else:
		fechar_dialogo_e_libertar()

func fechar_dialogo_e_libertar():
	dialogo_ativo = false
	caixa_dialogo.visible = false
	
	print("Saci: Obrigado! Toma o Pulo Duplo e o Escudo!")
	
	if jogador_ref:
		# Dá o Pulo Duplo
		if jogador_ref.has_method("desbloquear_pulo_duplo"):
			jogador_ref.desbloquear_pulo_duplo()
			
		# Dá o Escudo
		if jogador_ref.has_method("desbloquear_escudo_fogo"):
			jogador_ref.desbloquear_escudo_fogo()
	
	# Efeito de sumir
	await get_tree().create_timer(0.5).timeout
	queue_free()

# --- SINAIS ---
func _on_body_entered(body):
	if body.is_in_group("jogador"):
		pode_interagir = true
		jogador_ref = body 
		if not dialogo_ativo and label_aviso:
			label_aviso.visible = true

func _on_body_exited(body):
	if body.is_in_group("jogador"):
		pode_interagir = false
		jogador_ref = null
		if label_aviso: label_aviso.visible = false
		if dialogo_ativo:
			dialogo_ativo = false
			caixa_dialogo.visible = false
