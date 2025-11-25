extends CanvasLayer

# --- Referências dos Nós ---
# Pega o nó do Label que mostrará o número
@onready var label_vidas: Label = $LabelVidas


# Chamado quando a cena (HUD) está pronta
func _ready():
	# Esta é a parte mais importante: ligar a HUD ao Personagem.
	
	# 1. Espera o "dono" da HUD (a cena demo_floresta) estar pronta
	await get_owner().ready
	
	# 2. Tenta encontrar o nó "Personagem" (que é irmão da HUD)
	var personagem = get_owner().find_child("Personagem")
	
	if personagem:
		# 3. Se encontrou, liga o SINAL "saude_mudou" do Personagem
		# à FUNÇÃO "atualizar_vidas_label" desta HUD.
		personagem.saude_mudou.connect(atualizar_vidas_label)
		
		# 4. Atualiza a HUD uma vez no início, para mostrar a vida cheia
		atualizar_vidas_label(personagem.vida_atual)
	else:
		print("ERRO NA HUD: Nó 'Personagem' não encontrado.")


# Esta função é chamada AUTOMATICAMENTE toda vez que o
# sinal "saude_mudou" do Personagem é emitido.
func atualizar_vidas_label(vida_atual: int):
	# Simplesmente atualiza o texto do Label
	# O "str(vida_atual)" converte o número 3 para o texto "3"
	label_vidas.text = "x " + str(vida_atual)
