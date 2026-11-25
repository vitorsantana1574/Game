# Proposta de ajuste de kits nº 1: Clavento, Prismora, Vedrassa e Nalcora

- **Autor:** Claude (lógica)
- **Data:** 25/11
- **Status:** **aprovada pelo dono em 25/11** e aplicada nos dados (textos provisórios até o GPT reescrever as fichas)
- **Base:** laboratório de campeões (`tools/relatorios/laboratorio_campeoes.md`)

Os testes usaram 1.500 a 2.000 lutas 5x5 por momento. Os outros 26 campeões ficaram como estão. As mecânicas novas já existem no laboratório (`tools/prototipos/laboratorio_campeoes.py`), e o teste pode ser refeito com `tools/prototipos/testar_proposta_kits_1.py`, mas **ainda não entraram nos dados do jogo**.

## Princípio

Não basta cortar ou somar dano. Cada mudança faz o campeão **pagar** pela força que sobra, ou **ganhar** força pelo caminho que já combina com o tema dele. Assim a fraqueza listada na ficha continua valendo, e o Micro e o Macro do jogador pesam mais.

Os nomes e a descrição das habilidades continuam. Mudam só alguns efeitos, que o GPT vai reescrever no estilo dele se você aprovar.

---

## 1. Clavento, o fechador de passagens (estava forte: 60% de vitória geral, 69% no meio)

**O que o laboratório mostrou:** a força dele não vinha do kit. Tirar o controle ou a passiva quase não mudava nada. Ela vinha da **Égide de Aço como 2º item**: os espinhos devolvem 12% do dano bruto dos ataques, e um suporte de linha de frente que segura atiradores lucra demais com isso no meio do jogo. Trocar só a build já derrubou a vitória no meio de 65% para 54%.

**Proposta "a chave abre dos dois lados":**
1. **Build:** a Égide de Aço sai da build recomendada e vira **item alternativo** "contra atiradores de ataques básicos". No lugar entra a Armadura Viva de Cristal.
2. **Passo de dobradiça:** depois do avanço, Clavento fica **exposto por 2 s**, com −20% de armadura e de resistência mágica. É a fraqueza que a ficha já cita ("intervalo após errar o avanço") virando regra: quem pune o avanço é recompensado.
3. **Fecho de travessia:** o atordoamento cai de 0,65 s para **0,45 s**, mas sobe **+0,3 s (0,75 s no total)** em quem estiver sob a lentidão do Dente de Fechadura. O combo pesa mais que o botão.

**Resultado:** antes 50 / 69 / 58% (início / meio / fim), 60% geral. Depois **53 / 55 / 51%**, **53% geral**.

---

## 2. Prismora, a calibradora de lentes (estava forte no início e no meio: 54% geral, 58% no meio)

**O que o laboratório mostrou:** a Projeção de Prova, com 850 de alcance, já dava muito dano no nível 10, porque o dano crescia por nível. Para uma campeã "forte no fim", o dano do meio do jogo chegava cedo demais.

**Proposta "o tripé precisa ser armado":**
1. **Tripé armado:** ao lançar a Projeção de Prova ou a Linha de Horizonte, ela fica **parada 0,35 s** montando o tripé, que já existe no tema. Engajes rápidos, a fraqueza da ficha, passam a pegá-la de verdade.
2. **Feixe que precisa de distância:** a Projeção de Prova causa dano total só a partir de **600 de distância**. Mais perto, causa 70%. Posicionar bem vira dano.
3. **Uma lente nova a cada item:** a Projeção de Prova cresce menos por nível (metade do ganho) e ganha **+12% de dano por item completo** (a bota não conta). O dano dela passa a vir do ouro e dos itens, não do nível, que é como uma campeã de fim de jogo deve crescer.

**Resultado:** antes 49 / 58 / 53%, 54% geral. Depois **42 / 55 / 53%**, **50% geral**.

O meio ainda está um pouco alto. Vou afinar na implementação, sem mudar a ideia.

---

## 3. Vedrassa, a porteira de vidro (estava fraca no fim: 40%)

**O que o laboratório mostrou:** a proteção dela era pequena e fixa (escudos de 3% e 6% da vida do aliado) e não crescia com os itens de tanque que ela compra. No fim de jogo, ela tinha muita vida e quase nenhuma utilidade.

**Proposta "a porta divide o peso":**
1. **Batente emprestado:** além do escudo, por 2,5 s **20% do dano que o aliado receberia vai para Vedrassa**, que o recebe com as próprias resistências. Os itens de tanque dela viram proteção do carregador.
2. **Batente de emergência (passiva):** o escudo passa a ser 6% da vida do aliado **+ 5% da vida bônus de Vedrassa**.
3. **Como enfrentá-la:** atacar dois aliados separados (já é a fraqueza da ficha) ou derrubar a própria Vedrassa, que agora absorve dano.

**Resultado:** antes 49 / 44 / 40%, 44% geral. Depois **52 / 52 / 45%**, **50% geral**.

---

## 4. Nalcora, a lapidadora de faíscas (estava fraca no meio: 43%)

**O que o laboratório mostrou:** o dano misto perdia valor no meio do jogo, porque 14 das 30 builds têm o Escudo do Guardião, um escudo que só absorve dano mágico, e a parte mágica dela era engolida. Além disso, ela morria cedo (78% das lutas).

**Proposta "a solda acha a junta fraca":**
1. **Junta fraca:** nas três habilidades, a parte **maior** do dano misto vai para a resistência **mais baixa** do alvo. A divisão continua a mesma, só inverte quando convém. A fraqueza "alvos com resistências mistas" fica, mas dói menos.
2. **Solda derrete escudo:** a parte mágica das habilidades dela **atravessa escudos que só absorvem dano mágico**, como os do Escudo do Guardião e do Véu Celestial.
3. **Vidragem súbita:** **+30% de dano** em quem estiver sob a lentidão do Fio de Retorno. Recompensa o combo.
4. **Solda de entrada (passiva):** **participar de um abate reabre a passiva** na hora, sem esperar 3 s fora de combate. É uma assassina que encadeia alvos.
5. **Build:** o Manto da Noite Eterna sobe para 2º item, antes da Presa da Serpente.

**Resultado:** antes 56 / 43 / 47%, 48% geral. Depois **57 / 48 / 43%**, **49% geral**. A curva fica a de uma campeã forte no início: alvo de 55 / 51 / 45%.

---

## Efeito no resto do jogo

As médias por classe continuam entre 47% e 54% nos três momentos. Nenhum outro campeão saiu do alvo por causa das mudanças.

## O que acontece se você aprovar

1. **GPT:** reescreve os efeitos dessas quatro fichas e as builds de Clavento e Nalcora em `docs/propostas/campeoes.md`.
2. **Claude:**
   - passa as mecânicas novas para o conversor e os dados;
   - recalibra os quatro;
   - atualiza o relatório e o GDD.
3. As funções da interface não mudam: as fichas novas aparecem sozinhas na enciclopédia.

Você pode aprovar tudo, aprovar só parte ou pedir outra ideia para qualquer um dos quatro.
