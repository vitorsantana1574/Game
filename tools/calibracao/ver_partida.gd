extends SceneTree
## Simula uma partida de exemplo e imprime a narração, o placar e a estatística final.
## Uso: godot --headless --path . -s res://tools/calibracao/ver_partida.gd -- <semente>
## Os campeões são sorteados entre os da posição (pode repetir campeão nos dois times: é só para ler a narração).
func _initialize() -> void:
	var g := GeradorJogadores.new(5)
	var por_pos := {}
	for c in Dados.campeoes()["campeoes"]:
		por_pos.get_or_add(str(c["posicoes"][0]), []).append(c["id"])
	var times := []
	for n in ["Vale Rift", "Lobos do Norte"]:
		var js := []
		for pos in SimuladorPartida.POSICOES:
			var j := g.gerar({"qualidade": 55, "posicao": pos})
			var lista: Array = por_pos[pos]
			js.append({"posicao": pos, "jogador": j, "campeao": lista[g._rng.randi() % lista.size()]})
		times.append({"nome": n, "jogadores": js})
	var t0 := Time.get_ticks_msec()
	var r := SimuladorPartida.simular({"times": times, "forcas_patch": {}, "semente": int(OS.get_cmdline_user_args()[0]) if OS.get_cmdline_user_args().size() > 0 else 11})
	print("ms: ", Time.get_ticks_msec() - t0, "  eventos ", r["eventos"].size(), " quadros ", r["quadros"].size())
	for e in r["eventos"]:
		if e["tipo"] == "item": continue
		for f in e["narracao"]:
			print("[%s] %s: %s" % [e["minuto"], f["nome"], f["texto"]])
	print(r["placar"])
	for j in r["jogadores"]:
		print(j["apelido"], " ", j["campeao"], " ", j["abates"], "/", j["mortes"], "/", j["assistencias"], " cs ", j["cs"], " ouro ", j["ouro"], " ", j["dominio"])
	quit()
