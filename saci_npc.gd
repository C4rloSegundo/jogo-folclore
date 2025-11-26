extends Area2D

# --- Variáveis de Interação ---
var pode_interagir: bool = false
var dialogo_ativo: bool = false
var indice_frase: int = 0

# --- O Diálogo ---
@export var lista_falas: Array[String] = [
	"Saci: Ei! Psiu! Você aí!",
	"Saci: Estou preso nesta jaula mágica.",
	"Saci: Dizem que só uma chave de ouro pode abrir.",
	"Saci: Se você me ajudar, dou-te um presente!"
]

# --- Referências ---
@onready var label_aviso: Label = $Label

# CORREÇÃO AQUI: Removemos o "CanvasLayer" do caminho
# Agora a caixa é filha direta do Saci
@onready var caixa_dialogo: Control = $CaixaDialogo
@onready var texto_dialogo: Label = $CaixaDialogo/TextoDialogo

func _ready():
	# Começa tudo escondido
	label_aviso.visible = false
	caixa_dialogo.visible = false
	
	# Dica Pro: Garante que o balão apareça na frente de tudo (z-index)
	caixa_dialogo.z_index = 10

func _unhandled_input(event):
	if event.is_action_pressed("interagir"):
		if pode_interagir and not dialogo_ativo:
			iniciar_dialogo()
		elif dialogo_ativo:
			avancar_dialogo()

func iniciar_dialogo():
	dialogo_ativo = true
	indice_frase = 0
	
	caixa_dialogo.visible = true
	label_aviso.visible = false
	
	texto_dialogo.text = lista_falas[indice_frase]

func avancar_dialogo():
	indice_frase += 1
	if indice_frase < lista_falas.size():
		texto_dialogo.text = lista_falas[indice_frase]
	else:
		fechar_dialogo()

func fechar_dialogo():
	dialogo_ativo = false
	caixa_dialogo.visible = false
	if pode_interagir:
		label_aviso.visible = true

# --- SINAIS ---

func _on_body_entered(body):
	if body.is_in_group("jogador"):
		pode_interagir = true
		if not dialogo_ativo:
			label_aviso.visible = true

func _on_body_exited(body):
	if body.is_in_group("jogador"):
		pode_interagir = false
		label_aviso.visible = false
		if dialogo_ativo:
			fechar_dialogo()
