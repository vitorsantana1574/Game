class_name SistemaSaves
extends RefCounted
## Grava e lê as carreiras (4 espaços) e o progresso global do jogador.
## Os arquivos ficam em user://, que a Godot mapeia para a pasta de dados do usuário.

const TOTAL_SLOTS: int = 4

## Pasta dos saves. Os testes trocam para uma pasta própria.
var pasta: String = "user://saves"


func _caminho_slot(slot: int) -> String:
	return "%s/carreira_%d.json" % [pasta, slot]


func _caminho_meta() -> String:
	return "%s/meta.json" % pasta


func _caminho_progresso() -> String:
	return "%s/progresso.json" % pasta


func _garantir_pasta() -> void:
	DirAccess.make_dir_recursive_absolute(pasta)


static func slot_valido(slot: int) -> bool:
	return slot >= 0 and slot < TOTAL_SLOTS


func _ler_json(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var conteudo: Variant = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	return conteudo if conteudo is Dictionary else {}


func _gravar_json(caminho: String, dados: Dictionary) -> bool:
	_garantir_pasta()
	# Grava num arquivo temporário e depois troca, para não corromper o save se o jogo fechar no meio.
	var temporario: String = caminho + ".tmp"
	var arquivo: FileAccess = FileAccess.open(temporario, FileAccess.WRITE)
	if arquivo == null:
		return false
	arquivo.store_string(JSON.stringify(dados, "\t", false))
	arquivo.close()
	return DirAccess.rename_absolute(temporario, caminho) == OK


## Grava a carreira no espaço indicado e marca como último jogado.
func salvar(slot: int, carreira: Carreira) -> bool:
	if not slot_valido(slot):
		return false
	var registro: Dictionary = {
		"resumo": {
			"nome": carreira.organizacao.nome,
			"fase": carreira.descricao_fase(),
			"dificuldade": carreira.config.get("dificuldade", ""),
			"salvo_em": Time.get_datetime_string_from_system(false, true),
			"bandeira_png": carreira.organizacao.bandeira_png,
		},
		"carreira": carreira.para_dicionario(),
	}
	if not _gravar_json(_caminho_slot(slot), registro):
		return false
	marcar_ultimo(slot)
	return true


## Registra o espaço como último jogado (usado ao salvar e ao carregar).
func marcar_ultimo(slot: int) -> void:
	if slot_valido(slot):
		_gravar_json(_caminho_meta(), {"ultimo_slot": slot})


## Lê a carreira de um espaço. Devolve null se estiver vazio ou corrompido.
func carregar(slot: int) -> Carreira:
	if not slot_valido(slot):
		return null
	var registro: Dictionary = _ler_json(_caminho_slot(slot))
	if not registro.has("carreira"):
		return null
	return Carreira.de_dicionario(registro["carreira"])


## Resumos dos 4 espaços, na ordem. Espaço vazio = dicionário vazio.
func listar_resumos() -> Array[Dictionary]:
	var resumos: Array[Dictionary] = []
	for slot: int in range(TOTAL_SLOTS):
		var registro: Dictionary = _ler_json(_caminho_slot(slot))
		resumos.append(registro.get("resumo", {}).duplicate())
	return resumos


## Primeiro espaço vazio, ou -1 se todos estiverem ocupados.
func primeiro_slot_vazio() -> int:
	var resumos: Array[Dictionary] = listar_resumos()
	for slot: int in range(TOTAL_SLOTS):
		if resumos[slot].is_empty():
			return slot
	return -1


## Último espaço jogado, ou -1 se não houver (ou se ele tiver sido apagado).
func ultimo_slot() -> int:
	var slot: int = int(_ler_json(_caminho_meta()).get("ultimo_slot", -1))
	if not slot_valido(slot) or not FileAccess.file_exists(_caminho_slot(slot)):
		return -1
	return slot


func excluir(slot: int) -> bool:
	if not slot_valido(slot) or not FileAccess.file_exists(_caminho_slot(slot)):
		return false
	return DirAccess.remove_absolute(_caminho_slot(slot)) == OK


## Progresso que vale para todas as carreiras (ex.: Pesadelo desbloqueado).
func ler_progresso() -> Dictionary:
	return _ler_json(_caminho_progresso())


func gravar_progresso(progresso: Dictionary) -> bool:
	return _gravar_json(_caminho_progresso(), progresso)
