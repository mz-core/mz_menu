# Contrato de interação e movimento do contexto

## Objetivo

Um contexto da NUI própria permanece interativo enquanto o jogador se movimenta.
Teclado e mouse continuam operando o `mz_menu`; o movimento do jogo é repassado
com `SetNuiFocusKeepInput(true)`.

Por padrão, uma nova sessão de menu abre com movimento travado. `F6` e o botão do rodapé
alternam somente entre:

- **movimento liberado**: o menu continua utilizável e o jogador pode andar ou dirigir;
- **movimento travado**: o menu continua utilizável, mas os controles do jogo não recebem input.

## Configuração

```lua
MZMenuConfig.EnableMovementWhileOpen = true
MZMenuConfig.MovementToggleKey = 'F6'
MZMenuConfig.MovementEnabledByDefault = false
```

`MovementToggleKey` aceita teclas de função de `F1` a `F12`. Uma alteração exige
restart do resource para atualizar o key mapping.

`EnableFocusToggle` e `FocusToggleKey` permanecem disponíveis como aliases legados.
Novos consumidores devem usar os nomes relacionados a movimento.

## Regras

- o primeiro `OpenContext` ou `ShowContext` de uma sessão usa `MovementEnabledByDefault`;
- submenus e contextos de outros resources preservam o estado escolhido enquanto o menu permanecer aberto;
- fechar o menu encerra a sessão; a próxima abertura volta ao padrão travado;
- travar ou liberar movimento não fecha, recria ou desfoca o contexto;
- setas, `Enter`, mouse e `Esc` continuam operando o menu nos dois estados;
- `InputDialog`, `AlertDialog` e `Confirm` travam temporariamente o movimento;
- ao encerrar um diálogo, o estado anterior de movimento é restaurado;
- ataques, mira, troca/recarregamento de arma e golpes são bloqueados enquanto o movimento é repassado;
- fechar o contexto ou parar `mz_menu` sempre remove foco e `keep input`;
- o modo não congela ped ou veículo;
- o modo não cria autorização, permissão ou regra de negócio.

## Exports de movimento

```lua
exports['mz_menu']:SetMovementEnabled(true)
exports['mz_menu']:SetMovementEnabled(false)
exports['mz_menu']:ToggleMovement()
exports['mz_menu']:IsMovementEnabled()
```

Os exports antigos, inclusive os exports de foco introduzidos anteriormente,
permanecem disponíveis. No backend `ox_lib`, a alternância de movimento retorna
`unsupported_backend`.

## Posicionamento de garagens

O `G` do assistente de garagens tem outra responsabilidade: congelar temporariamente
o ped ou veículo para capturar uma coordenada precisa. Ele não substitui o controle
global de movimento do `mz_menu`.

## Teste runtime

1. Reinicie `mz_menu` e abra `/admin`, `/stafforg` ou `/mz_menu_test`.
2. Sem pressionar outra tecla, use `WASD`; o jogador não deve andar.
3. Pressione `F6`; o movimento deve ser liberado sem fechar ou desfocar o menu.
4. Ainda andando, use setas, `Enter` ou mouse para entrar em seções e módulos; o movimento deve continuar liberado.
5. Pressione `F6` novamente; o movimento deve travar e o rodapé deve indicar `liberar movimento`.
6. Libere novamente com `F6` e confirme que ataque, mira e golpes não são executados.
7. Abra um input ou confirmação; `WASD` não deve mover o jogador durante o diálogo.
8. Feche o diálogo; o estado de movimento anterior deve ser restaurado.
9. Pare `mz_menu` com um contexto aberto e confirme que teclado e mouse não ficam presos.
