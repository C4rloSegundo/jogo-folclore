extends Area2D

# --- Variáveis ---
var pode_interagir: bool = false
var dialogo_ativo: bool = false
var indice_frase: int = 0
var jogador_ref: Node2D = null
var ja_libertado: bool = false

# --- Falas ---
var falas_preso: Array[String] = [
	"Curupira: Ei! Psiu! Você aí!",
	"Curupira: Esses caçadores me prenderam com ferro frio...",
	"Curupira: Me ajude a sair daqui, por favor!",
	"Curupira: (Pressione F para quebrar a jaula)"
]

var falas_livre: Array[String] = [
	"Curupira: Ah! A liberdade! O cheiro da mata!",
	"Curupira: Eu sou o Curupira, protetor desta floresta.",
	"Curupira: Você tem um coração bom, forasteiro.",
	"Curupira: Como gratidão, vou te ensinar um segredo antigo...",
	"Curupira: (Você recebeu o Poder de Fogo Final!)", # Texto atualizado
	"Curupira: Agora vá! A floresta precisa de nós. Adeus!"
]

# --- Referências (CORRIGIDAS PARA A TUA CENA) ---
@onready var sprite: Sprite2D = $Sprite2D
# O nome na tua cena é "Label", então usamos Label aqui
@onready var label_aviso: Label = $Label 
@onready var caixa_dialogo: Control = $CaixaDialogo
@onready var texto_dialogo: Label = $CaixaDialogo/TextoDialogo
@onready var colision_jaula: StaticBody2D = $StaticBody2D

func _ready():
	if label_aviso:
		label_aviso.visible = false
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
	
	print("Curupira: Toma o Fogo Azul e o Escudo Protetor!")
	
	if jogador_ref:
		# Dá o poder de fogo
		if jogador_ref.has_method("desbloquear_poder_fogo"):
			jogador_ref.desbloquear_poder_fogo()
		
		# Dá o escudo (NOVO)
		if jogador_ref.has_method("desbloquear_escudo_fogo"):
			jogador_ref.desbloquear_escudo_fogo()
	
	await get_tree().create_timer(1.0).timeout
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
