extends VBoxContainer

signal slot_selecionado(slot: int)


func atualizar(registros: Array[Dictionary]) -> void:
	for filho: Node in get_children():
		remove_child(filho)
		filho.queue_free()
	for indice: int in range(registros.size()):
		var registro: Dictionary = registros[indice]
		var botao: Button = Button.new()
		botao.name = "slot_%d" % indice
		botao.alignment = HORIZONTAL_ALIGNMENT_LEFT
		botao.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		botao.custom_minimum_size.y = 46
		botao.disabled = registro.is_empty()
		if botao.disabled:
			botao.text = "Save %d · Vazio" % (indice + 1)
		else:
			botao.text = "Save %d · %s · %s" % [indice + 1, registro["nome"], registro["fase"]]
			botao.tooltip_text = botao.text
			botao.pressed.connect(slot_selecionado.emit.bind(indice))
			botao.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_child(botao)
