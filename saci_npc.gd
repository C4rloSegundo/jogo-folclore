extends Area2D

# --- Variáveis de Interação ---
var pode_interagir: bool = false
var dialogo_ativo: bool = false
var indice_frase: int = 0
var jogador_ref: Node2D = null # Guardamos quem é o jogador para dar o poder depois

# --- O Novo Diálogo (Ajustado) ---
@export var lista_falas: Array[String] = [
	"Saci: Opa! Finalmente uma alma viva por aqui!",
	"Saci: Eu sou o Saci Pererê, o guardião desta mata.",
	"Saci: Fui preso nesta jaula por caçadores malvados...",
	"Saci: Ei, quem é você? Parece um guerreiro forte.",
	"Saci: Escuta... Se você conseguir abrir esta jaula...",
	"Saci: Prometo que uso minha magia para te ajudar na jornada!",

]

# --- Referências ---
@onready var label_aviso: Label = $Label
@onready var caixa_dialogo: Control = $CaixaDialogo
@onready var texto_dialogo: Label = $CaixaDialogo/TextoDialogo

func _ready():
	# Começa tudo escondido e garante que o balão fica na frente
	label_aviso.visible = false
	caixa_dialogo.visible = false
	caixa_dialogo.z_index = 20 # Número alto para ficar na frente de tudo

func _unhandled_input(event):
	if event.is_action_pressed("interagir"):
		# Inicia ou Avança
		if pode_interagir and not dialogo_ativo:
			iniciar_dialogo()
		elif dialogo_ativo:
			avancar_dialogo()

func iniciar_dialogo():
	dialogo_ativo = true
	indice_frase = 0
	
	caixa_dialogo.visible = true
	label_aviso.visible = false
	
	# Mostra a primeira frase
	texto_dialogo.text = lista_falas[indice_frase]

func avancar_dialogo():
	indice_frase += 1
	
	# Verifica se ainda tem falas
	if indice_frase < lista_falas.size():
		texto_dialogo.text = lista_falas[indice_frase]
	else:
		fechar_dialogo_e_libertar()

func fechar_dialogo_e_libertar():
	dialogo_ativo = false
	caixa_dialogo.visible = false
	
	print("Saci: Obrigado! Aqui está o meu presente...")
	
	# 1. Dá o poder ao jogador (Pulo Duplo)
	if jogador_ref and jogador_ref.has_method("desbloquear_pulo_duplo"):
		jogador_ref.desbloquear_pulo_duplo()
	
	# 2. Efeito de sumir (Opcional: Pode colocar particulas ou som aqui)
	await get_tree().create_timer(0.5).timeout
	
	# 3. Saci vai embora
	queue_free()

# --- SINAIS ---
func _on_body_entered(body):
	if body.is_in_group("jogador"):
		pode_interagir = true
		jogador_ref = body # Guarda a referência do jogador para usar no final
		if not dialogo_ativo:
			label_aviso.visible = true

func _on_body_exited(body):
	if body.is_in_group("jogador"):
		pode_interagir = false
		jogador_ref = null
		label_aviso.visible = false
		if dialogo_ativo:
			# Se sair no meio, apenas fecha a janela, não liberta o Saci
			dialogo_ativo = false
			caixa_dialogo.visible = false
