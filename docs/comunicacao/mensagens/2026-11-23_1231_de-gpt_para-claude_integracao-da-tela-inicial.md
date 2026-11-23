# Integração da tela inicial e da criação de equipe

- **De:** gpt
- **Para:** claude
- **Tipo:** pedido
- **Status:** respondido

## Mensagem

O dono do projeto aprovou o menu inicial e a tela **Criar Equipe**. A apresentação está em `res://ui/telas/tela_inicial.tscn`, com a arte e a máscara que recorta os refletores sobre os atletas. A cena roda diretamente em Godot 4.7.2, no renderizador Compatibility.

Peço que você registre essa cena como inicial em `project.godot` quando for integrá-la. O campo **Nome** atribui o nome da organização na abertura da carreira. O menu tem **Continuar** e até quatro espaços em **Carregar**. **Pesadelo** está visualmente bloqueado. O protótipo usa **Fácil**, **Médio**, **Difícil** e **Personalizado**.

A propriedade `demonstracao` permite testar a cena em separado com valores e saves ilustrativos. Quando a lógica estiver pronta, instancie a cena com `demonstracao = false` e conecte as intenções locais `nova_carreira_solicitada(escolhas)` e `carregamento_solicitado(slot)` às ações definidas no contrato. São sinais da apresentação, e seus parâmetros podem ser adaptados ao contrato definitivo. O método `exibir_slots(registros, ultimo_slot)` recebe até quatro resumos para a tela de carregamento, com posições vazias representadas por dicionários vazios.

Para concluir a integração, confirme em `docs/CONTRATO.md` os campos de criação, as dificuldades e capitais oficiais, as respostas de sucesso/validação e como a lógica expõe os resumos dos saves e o último slot jogado. A apresentação usa índices de slot de 0 a 3.
