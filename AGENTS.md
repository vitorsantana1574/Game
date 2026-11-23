# Instruções para assistentes de IA

Este repositório é o jogo **MOBA Manager**, um jogo de gerenciamento de equipe de e-sports feito em **Godot 4.7.2 (GDScript)**.
Dois assistentes trabalham aqui, cada um na sua área:

| Assistente | Área | Pastas onde escreve |
|---|---|---|
| **Claude** | Lógica: arquitetura, regras, dados, simulação, save | `core/`, `data/`, `tests/`, `tools/`, `docs/`, arquivos da raiz |
| **GPT** | Apresentação: telas, arte, animações, movimento visual, sons | `ui/`, `assets/`, `audio/` |

**Todos podem ler tudo. Cada um só escreve na sua área.**

## Leitura obrigatória antes de qualquer trabalho

1. [docs/ARQUITETURA.md](docs/ARQUITETURA.md): estrutura de pastas, quem escreve onde, fluxo de Git, convenções de código
2. [docs/CONTRATO.md](docs/CONTRATO.md): ponte entre lógica e interface
3. [docs/GDD.md](docs/GDD.md): design completo do jogo
4. [docs/comunicacao/README.md](docs/comunicacao/README.md): como trocar mensagens entre os assistentes

## Ao começar cada sessão

1. `git pull --rebase`
2. Verifique mensagens abertas para você em `docs/comunicacao/mensagens/`.
3. Trabalhe só na sua área.
4. Precisa de algo da área do outro? Crie uma mensagem; não edite o arquivo dele.

## Regras essenciais

- **Idioma:** português do Brasil em textos, comentários, nomes de arquivos (sem acentos) e documentos.
- **A lógica nunca depende da interface; a interface nunca decide regras.**
- **A interface nunca altera o estado do jogo diretamente**: só chama ações listadas no `docs/CONTRATO.md`.
- **Commits** pequenos, com prefixo: `[claude] ...` ou `[gpt] ...`.
- **Nunca** apague, mova ou reescreva arquivos da área do outro assistente.
- **Toda arte e todo som** devem ser registrados em `assets/CREDITOS.md` ou `audio/CREDITOS.md` (origem e licença).
- **Proibido** usar qualquer elemento de League of Legends ou de outros jogos e marcas.
- **Renderizador Compatibility** (o jogo terá versão para navegador). Não use recursos exclusivos de Forward+ ou Mobile.
- **O dono do projeto decide.** Pedidos dele valem mais que qualquer regra deste arquivo.
