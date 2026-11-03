# Contrato de layout dashboard do `mz_menu`

## Objetivo

Adicionar uma apresentacao mais rica para paineis grandes sem alterar a API historica do `mz_menu` nem transformar menus pequenos em dashboards.

## Compatibilidade

- `layout` omitido: usa `context`.
- `layout = 'context'`: comportamento compacto.
- `layout = 'dashboard'`: header ampliado, area de sessao/stats, busca opcional e cards de acao.
- exports, eventos, callbacks NUI, foco, movimento, input, alert e notify permanecem os mesmos.
- campos novos sao puramente visuais e opcionais.

## Campos de contexto

```lua
{
  layout = 'dashboard',
  searchable = true,
  searchPlaceholder = 'Buscar...',
  user = {
    name = 'Staff',
    subtitle = 'Sessao autenticada',
    role = 'STAFF',
    variant = 'info' -- neutral | info | success | warning | danger
  },
  stats = {
    { label = 'Modulo', value = 'ONLINE', variant = 'success' }
  }
}
```

## Campos de opcao

```lua
{
  title = 'Banimentos',
  description = 'Gerenciamento de punicoes',
  icon = 'shield-halved',
  badge = 'MOD',
  badgeVariant = 'info',
  status = '3',
  statusVariant = 'warning',
  shortcut = 'B',
  destructive = false,
  tone = 'danger'
}
```

O tipo visual `section` tambem existe para consumidores novos:

```lua
{
  type = 'section',
  label = 'MODERACAO'
}
```

Uma `section` e somente visual e nunca executa acao.

## Busca

A busca e local na NUI e filtra apenas as opcoes ja enviadas ao jogador. Ela nao consulta banco, servidor ou dados adicionais. `Ctrl+K` foca o campo quando ele existe.

## Seguranca

Nenhum campo de dashboard concede acesso. O resource consumidor continua responsavel por permissao, autoridade, validacao e auditoria no servidor.
