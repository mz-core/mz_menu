# Contrato de tema por contexto do `mz_menu`

## Escopo

O `mz_menu` aceita identidade visual opcional em cada contexto sem conhecer organizacoes, cargos ou permissoes. Todos os exports anteriores continuam disponiveis e menus sem os novos campos usam o tema global de `MZMenuConfig.Theme`.

## Payload

```lua
exports['mz_menu']:OpenContext({
  id = 'consumer:context:root',
  title = 'Titulo',
  subtitle = 'Descricao curta',
  brand = 'Nome do produto',
  headerIcon = 'shield',
  badge = 'JOB',
  theme = {
    accent = '#009FE3',
    accent2 = '#67C9F1',
    position = 'left',
    width = 400
  },
  options = {}
})
```

Todos os campos novos sao opcionais.

| Campo | Contrato |
| --- | --- |
| `theme.accent` | Cor hexadecimal `#RRGGBB`. Valor invalido e ignorado. |
| `theme.accent2` | Cor hexadecimal `#RRGGBB`. Valor invalido e ignorado. |
| `theme.position` | `left`, `right` ou `center`. Valor invalido e ignorado. |
| `theme.width` | Numero normalizado para o intervalo seguro de 320 a 640 pixels. |
| `brand` | Texto visual exibido no cabecalho. Nao representa autoridade. |
| `headerIcon` | Nome de icone do catalogo local; nome desconhecido usa o icone generico. |
| `badge` | Texto curto exibido ao lado do titulo. |

A NUI repete a validacao de cor, posicao e largura como defesa visual. A validacao principal do payload acontece no client Lua antes do envio para a NUI.

## Resolucao e heranca

A resolucao ocorre nesta ordem:

1. tema global sanitizado de `MZMenuConfig.Theme`;
2. tema do primeiro contexto ancestral registrado;
3. temas dos submenus intermediarios;
4. tema proprio do contexto aberto.

Temas parciais sao mesclados. Um submenu sem `theme` herda integralmente o tema do pai. `brand`, `headerIcon` e `badge` tambem reutilizam o valor ancestral mais proximo quando omitidos, mantendo uma identidade consistente durante a navegacao.

O vinculo de heranca usa o campo `menu` do submenu. Ciclos sao interrompidos e a busca tem limite de profundidade.

## Ciclo de vida

- `RegisterContext` armazena somente valores visuais sanitizados.
- `ShowContext` resolve a cadeia visual e aplica o resultado antes de abrir.
- dialogs e notificacoes abertos sobre um contexto preservam o tema ativo.
- `CloseContext`, `CloseMenu`, `HideContext`, ESC e o botao de fechar restauram explicitamente o tema global.
- abrir um contexto legado depois de fechar um contexto tematico nao recebe cores residuais.

## Compatibilidade

Permanecem exportados:

- `Notify`;
- `OpenContext`;
- `OpenMenu`;
- `RegisterContext`;
- `RegisterSimpleMenu`;
- `ShowContext`;
- `CloseContext`;
- `CloseMenu`;
- `HideContext`;
- `InputDialog`;
- `AlertDialog`;
- `Confirm`;
- `IsReady`;
- `GetBackend`.

Eventos client existentes tambem permanecem. No backend `ox_lib`, o payload continua aceito, mas a aparencia final depende das capacidades visuais do proprio `ox_lib`; o contrato completo e renderizado pela NUI nativa do `mz_menu`.

## Limite de responsabilidade

Tema, marca, icone e badge sao metadados exclusivamente visuais. O `mz_menu` nao deve decidir membership, capability, permissao Staff, status de organizacao ou acesso a dados.

## Teste manual

Com `MZMenuConfig.EnableTestCommand = true`:

```text
/mz_menu_theme_test
```

O seletor cobre `job`, `gang`, `business`, `government`, `vip`, `event` e `staff`. Cada perfil possui um submenu sem tema proprio para validar heranca e uma acao de fechamento para validar a restauracao global.
