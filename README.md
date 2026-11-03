# mz_menu

`mz_menu` é a camada visual reutilizável dos resources MZ Core.

A partir da versão `0.3.0`, ele possui **NUI própria baseada no layout aprovado no v0**, convertida para HTML/CSS/JS puro de NUI FiveM. Não usa Node, Next, React ou build em produção. A API antiga foi mantida para resources como `mz_houses`.

Ele não valida permissão, não salva banco e não executa regra de negócio. A segurança continua sempre no resource que chamou o menu.

## Ideia

```txt
mz_menu = visual / menu / input / alert / notify
mz_houses, mz_org, mz_vehicles = lógica / permissão / banco / logs
```

## Ordem no server.cfg

```txt
ensure mz_menu
```

Se outro resource usa o menu:

```lua
dependency 'mz_menu'
```

`ox_lib` não é mais dependência obrigatória do `mz_menu`. A NUI própria é o backend principal.

## Backend

Em `shared/config.lua`:

```lua
MZMenuConfig.Backend = 'nui'
```

Valores:

```txt
nui    = usa a NUI própria do mz_menu
ox_lib = força ox_lib, se você habilitar/importar ox_lib neste resource
auto   = reservado para fallback automático; a prioridade continua sendo NUI
```

Atenção: para usar `ox_lib` como backend real dentro do `mz_menu`, você precisa importar `@ox_lib/init.lua` no `fxmanifest.lua`. Por padrão, isso fica comentado para o `mz_menu` não ser dependente de ox_lib.

## Visual

Arquivos editáveis da NUI própria:

```txt
web/index.html
web/style.css
web/app.js
```

Os ícones ficam embutidos em `web/app.js` em formato SVG local. Isso evita depender de CDN/web externa dentro da NUI do FiveM.

Config visual:

```lua
MZMenuConfig.Theme = {
  accent = '#009FE3',
  accent2 = '#67C9F1',
  position = 'left',
  width = 380
}
```

`blur` fica `false` por padrão porque `backdrop-filter` pode pesar ou causar problemas em NUI FiveM.

## Exports client-side

```lua
exports['mz_menu']:Notify('Mensagem', 'success')

exports['mz_menu']:OpenContext({
  id = 'meu_menu',
  title = 'Meu Menu',
  options = {
    {
      title = 'Opção local',
      description = 'Chama evento client',
      icon = 'home',
      event = 'meu_resource:client:acao',
      args = { id = 1 }
    },
    {
      title = 'Opção server',
      description = 'Chama evento server',
      icon = 'server',
      serverEvent = 'meu_resource:server:acao',
      args = { id = 1 }
    },
    {
      title = 'Opção com função local',
      icon = 'check',
      onSelect = function()
        print('selecionado')
      end
    }
  }
})
```

Observação importante: `onSelect = function()` funciona quando o menu é montado e executado no mesmo resource. Para menus passados entre resources, prefira `event + args`.

## Input

```lua
local result = exports['mz_menu']:InputDialog('Criar imóvel', {
  { type = 'input', label = 'Código', required = true },
  { type = 'input', label = 'Nome', required = true },
  { type = 'input', label = 'Shell', default = 'shell_test' },
  {
    type = 'select',
    label = 'Tipo',
    default = 'house',
    options = {
      { value = 'house', label = 'Casa' },
      { value = 'apartment', label = 'Apartamento' }
    }
  }
})

if result then
  print(result[1], result[2], result[3], result[4])
end
```

Tipos suportados no MVP:

```txt
input
number
textarea
checkbox
select
color
date
time
```

## Alert / Confirm

```lua
exports['mz_menu']:AlertDialog({
  header = 'Informações',
  content = 'Texto do alerta',
  centered = true,
  cancel = false
})

local ok = exports['mz_menu']:Confirm('Confirmar', 'Deseja continuar?')
```

## Player Selector

O `mz_menu` renderiza e orquestra o seletor; o resource consumidor continua responsavel
pela busca, permissao e revalidacao server-side:

```lua
local player = exports['mz_menu']:PlayerSelector({
  title = 'Selecionar jogador',
  filters = { 'all', 'online', 'offline' },
  defaultFilter = 'all',
  pageSize = 25,
  searchPlaceholder = 'Nome, Character, citizenid ou source...',
  provider = 'SearchPlayersForSelector'
})

exports('SearchPlayersForSelector', function(query, filter, page, pageSize)
  return MinhaBuscaAutorizada(query, filter, page, pageSize)
end)
```

O provider retorna `{ items, total, page, pageSize, hasMore, hint }`. Cada item pode
conter `source`, `citizenid`, `accountId`, `characterId`, `name`, `characterName` e
`online`. A NUI devolve somente uma chave; o payload selecionado vem da copia validada
mantida no client Lua. Identidade, sessao e permissao precisam ser verificadas novamente
no servidor antes de qualquer acao.

`provider` identifica um client export do proprio resource consumidor. Isso evita manter
uma funcao Lua de outro resource dentro do seletor bloqueante. `fetch = function (...)`
continua aceito para chamadas locais e compatibilidade.

## Exports server-side

```lua
exports['mz_menu']:Notify(source, 'Mensagem para o jogador', 'inform')

exports['mz_menu']:OpenContext(source, {
  id = 'server_menu_exemplo',
  title = 'Menu aberto pelo server',
  options = {
    {
      title = 'Ação server',
      serverEvent = 'meu_resource:server:acao',
      args = { code = 'teste' }
    }
  }
})
```

## Teste

Com `MZMenuConfig.EnableTestCommand = true`:

```txt
/mz_menu_test
```

## Movimento com o menu aberto

Nos contextos da NUI propria, o movimento inicia travado. `F6` e o botao do rodape
liberam ou travam somente o movimento, sem fechar o menu ou perder a interacao com
teclado e mouse. O estado escolhido permanece ao navegar entre submenus e modulos
registrados por outros resources; ao fechar o menu, a proxima abertura volta travada.

```lua
exports['mz_menu']:SetMovementEnabled(false)
exports['mz_menu']:SetMovementEnabled(true)
exports['mz_menu']:ToggleMovement()
exports['mz_menu']:IsMovementEnabled()
```

Input, confirmacao e alerta travam o movimento temporariamente e restauram o estado
anterior quando terminam. Os exports antigos de foco continuam disponiveis por
compatibilidade. Consulte `docs/INTERACTION_FOCUS_CONTRACT.md`.

## Segurança

Errado:

```txt
Confiar que o menu só aparece para admin.
```

Certo:

```lua
RegisterNetEvent('meu_resource:server:acao', function(payload)
  local src = source
  if not IsPlayerAceAllowed(src, 'group.mz_owner') then
    return
  end

  -- executar ação segura aqui
end)
```

O `mz_menu` é só a camada visual.


## Layout v0 convertido

O visual desta versão foi adaptado do protótipo `menu-administrativo-five-m` gerado no v0, porém sem manter a stack Node/Next/React.

Em produção o FiveM carrega apenas:

```txt
web/index.html
web/style.css
web/app.js
```

A API continua a mesma:

```lua
exports['mz_menu']:OpenContext({...})
exports['mz_menu']:InputDialog(...)
exports['mz_menu']:AlertDialog(...)
exports['mz_menu']:Confirm(...)
exports['mz_menu']:PlayerSelector(...)
exports['mz_menu']:Notify(...)
```

O `ox_lib` continua opcional/fallback manual. O backend padrão é `nui`.

### Subtítulo opcional

Agora o menu aceita `subtitle` no payload:

```lua
exports['mz_menu']:OpenContext({
  id = 'mhouse_admin',
  title = 'Gerenciar Imóveis',
  subtitle = 'mz_houses • Admin',
  options = {}
})
```

Se `subtitle` não for enviado, o menu usa `MZMenuConfig.BrandName`.

## Layout dashboard (0.4.0-test)

O contrato antigo continua valido. O layout novo e opcional:

```lua
exports['mz_menu']:OpenContext({
  id = 'admin:root',
  title = 'Administracao',
  brand = 'MZ Admin',
  layout = 'dashboard',
  searchable = true,
  searchPlaceholder = 'Buscar ferramenta...',
  user = {
    name = 'Mateus',
    subtitle = 'Sessao administrativa autenticada',
    role = 'STAFF',
    variant = 'info'
  },
  stats = {
    { label = 'Areas', value = '7', variant = 'info' },
    { label = 'BanGuard', value = 'ONLINE', variant = 'success' }
  },
  options = {}
})
```

Menus que nao enviam `layout` continuam no modo `context`, preservando o comportamento compacto anterior.

Opcoes tambem aceitam metadados visuais opcionais como `badge`, `badgeVariant`, `status`, `statusVariant`, `shortcut`, `destructive` e `tone`. Esses campos nao concedem permissao nem alteram a regra de negocio.
