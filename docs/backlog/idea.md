# Catálogo rápido de ideias

## Ideia crua

- nas estatisticas de mouse over, colocar um lvl up estimation, pra xp seria lvl up in 2h 13m, pra rep um honored in 1h 23m, e para honor eu ainda não tive uma ideia... vamos manter minutos como unidade minima.

## Ideia pensada

### 1. Tempo estimado até o próximo objetivo

Ao passar o mouse sobre um tracker, mostrar quanto tempo de acompanhamento ativo
falta para atingir o próximo marco, caso o ritmo médio da sessão seja mantido.
A previsão complementa os totais e as taxas: além de saber quanto está ganhando
por hora, o jogador consegue decidir se vale continuar por mais um tempo.

- **Experience:** estimar o tempo até o próximo nível, usando o XP que ainda
  falta no nível atual. Exemplo: `Level 43 in 2h 13m`.
- **Reputation:** estimar o tempo até o próximo patamar da facção acompanhada.
  Exemplo: estando em Friendly, mostrar `Honored in 1h 23m`.
- **Honor:** deixar sem previsão nesta primeira versão. Uma evolução possível
  seria uma meta de pontos escolhida pelo jogador, como juntar o valor necessário
  para comprar um item. Essa meta precisaria de uma definição própria antes de
  entrar no escopo.

A previsão usa a média da sessão, não o último ganho,
e representa tempo de jogo no mesmo ritmo, sem prometer um horário de conclusão.

### Regras propostas

- **Base do cálculo:** quantidade restante até o objetivo dividida pela taxa
  média da sessão. Usar a precisão do cálculo, antes do arredondamento visual
  das taxas. O tempo pausado fica fora da média; o tempo sem ganhos enquanto
  o tracker está rodando continua contando, como nas taxas atuais.
- **Unidade mínima de um minuto:** exibir `1m`, `23m`, `2h 13m` ou `25h`.
  Arredondar o tempo restante para cima em minutos, sem segundos ou `0m` para
  uma meta ainda não atingida. Por exemplo, 2h 12m 10s vira `2h 13m`.
- **Início da sessão:** aguardar ao menos um minuto de acompanhamento ativo e
  uma taxa positiva antes de calcular. Até lá, mostrar `Estimating…`.
- **Sem progresso positivo:** depois desse primeiro minuto, uma taxa zero ou
  negativa mostra `No estimate available`, sem divisão por zero ou tempo negativo.
- **Pausa:** mostrar `Paused` no lugar da previsão. Ao retomar, recalcular usando
  o progresso atual e a média da sessão, sem incluir a pausa.
- **Mudança de objetivo:** ao subir de nível ou de patamar, passar a prever o
  próximo marco, mantendo a sessão. Ao trocar a facção acompanhada, seguir o
  reset que o tracker de reputação já faz, sem misturar taxas entre facções.
- **Limite atingido:** mostrar `Max level reached` ou `Exalted reached`, conforme
  o caso. Não prever um próximo marco que não existe.
- **Dados indisponíveis:** mostrar `No estimate available` quando não for possível
  obter um progresso e um próximo marco válidos. Reputações com progressão
  especial ficam fora do escopo inicial até que seu comportamento seja validado.

## Solução

Implementação na branch `feat/estimates`, com validação no jogo ainda pendente:

- Acrescentar `Estimate` como a primeira seção do tooltip de Experience e
  Reputation, após o cabeçalho de identificação e status. A ordem das seções
  será `Estimate`, `Session` e `Rates`. Manter o painel compacto e atualizar a
  previsão enquanto o tooltip estiver aberto, acompanhando a atualização das
  estatísticas atuais.
- Cada tracker fornece seu objetivo e a quantidade restante; a apresentação
  compartilha as regras de cálculo, disponibilidade e formatação do tempo.
- Derivar a previsão do progresso atual e dos dados da sessão, sem persistir
  o resultado do cálculo ou criar migrações.
- Em `General`, oferecer `Show estimates` (Exibir estimativas), desativado por
  padrão e salvo por personagem. Quando ativado, mostrar a previsão pequena,
  e centralizada abaixo da taxa nos painéis de XP e reputação, com a mesma cor
  do indicador do botão: cinza antes de iniciar, verde em execução e amarelo
  quando pausado. O status é compartilhado e suas cores ficam no DS. A linha
  também funciona com o velocímetro e reserva seu próprio espaço vertical.
  A opção controla o texto no painel; a previsão continua disponível no tooltip.

Exemplo da nova seção, no tooltip de Experience:

```text
Estimate
Level 43 in 2h 13m
```

**Critérios para considerar a ideia pronta:** conferir cálculo e arredondamento,
sessão recém-iniciada, taxa zero ou negativa, pausa e retomada, passagem de nível
ou patamar, troca de facção, limite máximo e dados indisponíveis. Na implementação,
validar esses cenários na simulação e conferir a leitura e atualização do tooltip
no WoW Forever, registrando as duas validações separadamente.
