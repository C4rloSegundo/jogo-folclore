extends Area2D

# --- Variáveis ---
var pode_interagir: bool = false
var dialogo_ativo: bool = false
var indice_frase: int = 0
var jogador_ref: Node2D = null
var ja_libertado: bool = false

# --- Falas do Curupira (Narrativa do Pai) ---
var falas_preso: Array[String] = [
	"Curupira: Ei! Psiu! Você aí!",
	"Curupira: Esses caçadores me prenderam com ferro frio...",
	"Curupira: Minha magia não funciona contra este metal.",
	"Curupira: Por favor, quebre esta jaula! (Pressione F)"
]

var falas_livre: Array[String] = [
	"Curupira: Ah! Finalmente livre! Meus pés virados agradecem.",
	"Curupira: Espere... esses olhos... essa coragem...",
	"Curupira: Meu filho! É você! Eu sabia que viria.",
	"Curupira: Eu sou o Curupira, guardião desta mata... e seu pai.",
	"Curupira: Fui capturado tentando proteger o Coração da Floresta.",
	"Curupira: Mas agora vejo que o destino escolheu você para terminar minha missão.",
	"Curupira: Você é o único que pode deter a destruição que se aproxima.",
	"Curupira: Tome, receba a minha chama sagrada. Ela é sua por direito.",
	"Curupira: (Você recebeu o Poder de Fogo Final!)",
	"Curupira: Agora vá, meu filho! Mostre a eles a fúria da natureza. Eu estarei sempre contigo."
]

# --- Referências ---
@onready var sprite: Sprite2D = $Sprite2D
@onready var label_aviso: Label = $Label 
@onready var caixa_dialogo: Control = $CaixaDialogo
@onready var texto_dialogo: Label = $CaixaDialogo/TextoDialogo
@onready var colision_jaula: StaticBody2D = $StaticBody2D

func _ready():
	if label_aviso: label_aviso.visible = false
	if caixa_dialogo: 
		caixa_dialogo.visible = false
		caixa_dialogo.z_index = 20

func _unhandled_input(event):
	if event.is_action_pressed("interagir") and pode_interagir:
		if not dialogo_ativo:
			iniciar_dialogo()
		else:
			avancar_dialogo()

func iniciar_dialogo():
	if not caixa_dialogo: return
	
	dialogo_ativo = true
	caixa_dialogo.visible = true
	if label_aviso: label_aviso.visible = false
	indice_frase = 0
	
	if not ja_libertado:
		texto_dialogo.text = falas_preso[indice_frase]
	else:
		texto_dialogo.text = falas_livre[indice_frase]

func avancar_dialogo():
	indice_frase += 1
	var lista_atual = falas_livre if ja_libertado else falas_preso
	
	if indice_frase < lista_atual.size():
		texto_dialogo.text = lista_atual[indice_frase]
	else:
		if not ja_libertado:
			libertar_curupira()
		else:
			dar_poder_e_sumir()

func libertar_curupira():
	print("Jaula quebrada!")
	ja_libertado = true
	dialogo_ativo = false
	if caixa_dialogo: caixa_dialogo.visible = false
	
	if colision_jaula:
		colision_jaula.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		colision_jaula.visible = false
	
	await get_tree().create_timer(0.5).timeout
	iniciar_dialogo()

func dar_poder_e_sumir():
	dialogo_ativo = false
	if caixa_dialogo: caixa_dialogo.visible = false
	
	print("Curupira (Pai): Receba o Fogo Final, meu filho!")
	
	if jogador_ref:
		# Dá o Fogo Final
		if jogador_ref.has_method("desbloquear_poder_fogo"):
			jogador_ref.desbloquear_poder_fogo()
			
		# Dá o Escudo (Opcional, se quiseres manter)
		if jogador_ref.has_method("desbloquear_escudo_fogo"):
			jogador_ref.desbloquear_escudo_fogo()
	
	await get_tree().create_timer(2.0).timeout # Tempo para ler a última mensagem mentalmente
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
			if caixa_dialogo: caixa_dialogo.visible = false
