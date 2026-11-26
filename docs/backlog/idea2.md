# Catálogo rápido de ideias

## Ideia crua

Milestones

### M1
- criar modulo de gold, para monitorar o farming de gold por hora
- contabilizaremos apenas gold recebido através de looting e vendor price.
- não consideraremos trades ou mails
- (duvida: existem outras formas de receber gold além das 4 que mencionei? loot, vendor, trade e mail)

### M2
- ter a dependencia opicional do addon Auctionator
- não tem Auctionator? usa o valor de "vendor" dos itens dropados na session
- tem Auctionator? usa o valor do Auctionator (quando melhor que o do "vendor")

### M3
- Settings individual para considerar trade e/ou mails recebidos na session

## Ideia pensada

### M1 — Valor do farming na coleta

- Criar o módulo Gold para acompanhar o rendimento estimado do farming por hora.
- Somar as moedas recebidas por loot e o valor de venda ao NPC dos itens
  coletados durante a sessão, multiplicado pela quantidade recebida.
- Incluir recompensas de quests como ganhos da própria sessão, sem tratá-las
  como recebimentos externos de mail ou trade.
- Descontar itens entregues para concluir quests pelo valor de vendor × quantidade
  exigida e confirmada pela redução no inventário. Registrar cada item como saída,
  mantendo quantidade e `questID`; itens sem valor continuam ignorados.
- Avaliar os itens no momento da coleta, sem exigir que sejam vendidos ao NPC.
- Ignorar itens com valor de vendor zero. Se o preço ainda não estiver disponível,
  manter o evento pendente e descartá-lo caso o valor carregado seja zero.
- A venda posterior dos itens já avaliados não acrescenta seu valor novamente.
- Itens que já estavam nas bolsas antes da sessão não entram no total apenas
  por serem vendidos durante ela.
- Considerar despesas e deduzir o valor de consumíveis efetivamente usados
  durante a sessão, como potions e food.
- Trades e mails ficam fora do M1.
- Guardar desde o M1 o histórico dos eventos de entrada e saída considerados
  no cálculo, para permitir a conferência pelo jogador quando a exibição
  estiver disponível no M1.5.
- Proposta para cada registro: momento na sessão, origem ou motivo, item e
  quantidade quando aplicável, valor somado ou deduzido.

O total combina moedas recebidas e o valor estimado dos itens, descontando as
despesas consideradas na sessão. Não representa apenas o aumento do saldo de
dinheiro do personagem: total = entradas consideradas − saídas consideradas.

### M1.5 — Exibição do histórico da sessão

- Exibir o histórico de entradas e saídas já guardado pelo M1, permitindo
  ao jogador conferir o que foi considerado no cálculo.
- Adicionar a opção **Details** somente ao menu Options do tracker Gold,
  entre **Settings** e **Announce**. Ordem: Reset → Settings → Details → Announce.
- Abrir um painel **Gold Details** com o mesmo estilo do painel de Settings.
- Abrir o mesmo Details também ao clicar com o botão esquerdo no corpo ou valor
  do tracker Gold. Mostrar **Left-click: Details** no tooltip. Arrastar mantém
  apenas a movimentação; Start/Pause, Options e Close mantêm suas ações.
- Exibir um resumo da sessão com entradas, saídas e saldo estimado.
- Usar **Item prices: TSM > Auctionator > Vendor; vendor minimum.** no tooltip do Gold e em uma nota
  discreta abaixo da lista no Details. O tooltip também avisa quando há preços
  de itens pendentes.
- Empilhar **Loot & rewards**, **Expenses & items used** e **Estimated net profit**
  no resumo, com fonte normal e rótulos alinhados ao texto dos eventos. Manter os
  totais alinhados à direita na coluna Value; entradas em branco do DS, despesas
  em vermelho do DS e lucro em dourado do DS. Os títulos **Time**, **Event** e
  **Value** ficam abaixo do resumo, sem separador. Preservar o tamanho da janela
  e a altura da área de rolagem. Acrescentar 15 px de margem apenas à esquerda,
  sem deslocar os valores ou a barra à direita.
- A lista de eventos terá rolagem e mostrará os registros mais recentes primeiro.
- Usar uma borda inferior em cobre em todas as linhas, com RGB `0.72, 0.45, 0.40`,
  3 px e 20% de opacidade definidos no DS. Adicionar a mesma borda acima da
  primeira linha visível, fixa no topo da lista e oculta quando vazia. Aplicar
  cor sólida para manter o cobre visível. O fundo continua uniforme, sem interação
  na borda.
- Centralizar texto, setas e ícones nos 23 px úteis entre as bordas, sem contar
  os 3 px do separador inferior. A altura total da linha continua em 26 px.
- Usar três colunas: **Tempo**, **Evento** e **Valor**. Cada evento ocupa uma
  única linha, sem repetir a origem em uma coluna ou linha secundária.
- Mostrar a hora local do evento (`HH:MM:SS`), guardada ao registrá-lo. Registros
  antigos sem horário exibem `—`, sem migração ou reconstrução.
- Usar **Looted** para moedas coletadas e uma bolsinha nativa de loot
  (`INV_Misc_Bag_10`) para dinheiro, no lugar da moeda de prata.
- Incluir a quantidade no nome somente quando maior que um, como `Item x2`.
- Usar ícones nativos em meia escala, com cerca de 18,5 px, e fontes padrão.
  A janela terá 560 px de largura, como Settings.
- Apenas o ícone mostra o tooltip do item; o nome é passivo. Quando houver `questID`, inserir
  um `!` nativo entre o ícone e o nome, com o tooltip da quest no marcador.
  Reservar o espaço do `!` para alinhar os nomes e usar uma área de hover maior
  que o símbolo. Indicar preços ainda pendentes.
- A bolsinha de loot exibe um tooltip com o valor recebido, tanto no loot quanto
  nas recompensas em dinheiro de quests. Transporte e reparos não terão tooltip;
  manter os tooltips nativos de itens e do marcador de quest e os nomes passivos.
- Adicionar uma seta nativa de entrada (up, verde do DS) ou saída (down, vermelho
  do DS) atrás da borda inicial do ícone. Sem interação ou tooltip na seta.
- Exibir o valor sem sinais de `+` ou `-` e usar vermelho do DS nas saídas,
  preservando a apresentação normal dos nomes dos itens.
- Atualizar a lista enquanto o painel estiver aberto, preservando a posição
  de rolagem de quem estiver consultando registros anteriores.
- Permitir a consulta durante a pausa. Uma sessão sem registros exibirá uma
  mensagem de ausência de eventos.

### M2 — Provedores opcionais de preço

- Prioridade interna fixa: **TSM → Auctionator → Vendor**, sem seletor de fonte.
- Usar DBMarket no TSM e o último preço de scan do Auctionator. A primeira fonte
  válida vence; vendor é o piso. Fontes ausentes, sem dados ou com erro permitem
  consultar a seguinte. Ambos os addons são dependências opcionais.
- Separar provedores, escolha de preço, alocação dos valores e eventos do Gold.
  Consultar apenas APIs públicas locais, sem scans ou chamadas de rede.
- Guardar fonte, métrica e valor unitário por registro, sem reavaliar o histórico
  ao atualizar scans, carregar outro addon ou recarregar a UI.
- Ao consumir ou entregar itens, cancelar primeiro os valores das coletas
  registradas, em ordem FIFO por ID. Quantidades de estoque antigo sem entrada
  registrada usam uma nova cotação. Uma saída pode combinar vários preços e
  continuar sendo uma única linha, com as parcelas salvas.
- Mostrar fonte, valor e parcelas no tooltip do ícone, sem consultar os addons
  enquanto o jogador navega pelo histórico.
- Agrupar essas informações sob **Per Hour valuation:** em dourado do DS, com
  rótulos e valores em branco, incluindo as parcelas. Preservar o tooltip nativo
  acima dessa seção, sem recolorir as informações originais do item.
- Usar estimativas brutas, sem comissão da AH ou custo de depósito. Itens
  inegociáveis e de quest usam vendor; itens negociáveis com vendor zero podem
  ter valor de AH. Dados nativos ainda ausentes continuam pendentes.
- Manter registros antigos intactos, inclusive sua regra original de vendor
  para preços pendentes. Sem novas migrações de dados ou configurações.

### Pontos ainda em aberto

- No M3, definir se as opções abrangem somente dinheiro ou também itens e como
  evitar contar novamente recebimentos de vendas de itens já avaliados.

## Solução

### M1

Implementado na branch `feat/gold-tracking`, com validação no jogo pendente.
Detalhes e procedimento de validação em [Gold tracking](../gold-tracking.md).

- O painel Gold usa os controles, tempo ativo e persistência existentes.
- Entram moedas de loot, recompensas de quests e itens avaliados pelo vendor.
- Conforme aprovado, reparos pessoais e transporte são deduzidos pelo dinheiro
  gasto; consumíveis, inclusive os que já estavam nas bolsas, pelo valor de
  vendor ao usar. Compras de itens ficam fora para não descontar compra e consumo.
- O histórico é guardado no contexto da sessão até Reset, incluindo entradas
  com preço pendente. A exibição continua reservada ao M1.5.
- A implementação não cria migrações de dados ou configurações.

### M1.5

Implementado na branch `feat/gold-tracking`, com validação no jogo pendente.

- **Details** fica entre Settings e Announce apenas nas opções do Gold.
- O painel compartilha o estilo de Settings e exibe resumo e histórico em uma
  lista nativa com rolagem e linhas reutilizadas.
- A lista mantém o registro e a posição parcial da linha em consulta quando
  chegam novos eventos, inclusive após reabrir o painel.
- Fechar o painel não interrompe o tracker. Pause, Reset, preços pendentes e
  histórico restaurado acompanham os dados existentes, sem novas migrações.
