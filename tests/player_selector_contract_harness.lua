local function read(path)
  local handle = assert(io.open(path, 'rb'))
  local content = handle:read('*a')
  handle:close()
  return content
end

local function expect(condition, message)
  if not condition then error(message, 2) end
end

local client = read('mz_menu/client/main.lua')
local html = read('mz_menu/web/index.html')
local app = read('mz_menu/web/app.js')
local css = read('mz_menu/web/style.css')

expect(client:find("exports('PlayerSelector', MZMenu.PlayerSelector)", 1, true), 'export PlayerSelector ausente')
expect(client:find("return nil, 'unsupported_backend'", 1, true) == nil, 'PlayerSelector falha quando contextos usam ox_lib')
expect(client:find("lib.hideContext(false)", 1, true), 'contexto ox_lib nao e ocultado durante o seletor')
expect(client:find("local providerExport = sanitizeSelectorText(options.provider, 64)", 1, true), 'provider export do consumer ausente')
expect(client:find("GetInvokingResource()", 1, true), 'provider nao fica restrito ao resource consumidor')
expect(client:find("provider[providerExport](provider, query, filter, page, pageSize)", 1, true), 'provider dinamico nao preserva argumentos no proxy FiveM')
expect(client:find("RegisterNUICallback('playerSelectorSearch'", 1, true), 'callback de busca ausente')
expect(client:find("RegisterNUICallback('playerSelectorSelect'", 1, true), 'callback de selecao ausente')
expect(client:find('local selected = selector.items[key]', 1, true), 'selecao nao usa DTO armazenado no client')
expect(client:find('result = selectorDisplayResult(normalized)', 1, true), 'DTO tecnico foi enviado diretamente a NUI')
expect(client:find('selector.allowedFilters[filter]', 1, true), 'filtros permitidos nao sao revalidados')
expect(client:find('selector.generation ~= generation', 1, true), 'resposta de busca stale nao e descartada')
expect(client:find('math.min(50', 1, true), 'pageSize do seletor nao possui limite')

expect(html:find('id="selectorFilters"', 1, true), 'filtros do seletor ausentes')
expect(html:find('id="selectorSummary"', 1, true), 'resumo do seletor ausente')
expect(app:find('setTimeout(() => requestPlayerSelectorPage(1, false), 250)', 1, true), 'debounce da busca remota ausente')
expect(app:find("event.key === 'Backspace'", 1, true), 'navegacao Backspace ausente')
expect(app:find("event.key === 'Escape'", 1, true), 'navegacao Escape ausente')
expect(app:find('cancelPlayerSelector(false)', 1, true), 'fechamento do seletor nao distingue voltar de fechar')
expect(app:find("event.key === 'ArrowDown'", 1, true), 'navegacao ArrowDown ausente')
expect(app:find("event.key === 'ArrowUp'", 1, true), 'navegacao ArrowUp ausente')
expect(app:find("event.key === 'Enter'", 1, true), 'navegacao Enter ausente')
expect(css:lower():find('#009fe3', 1, true), 'identidade visual azul MZ ausente')
expect(css:lower():find('#090c11', 1, true), 'dark base MZ ausente')

print('mz_menu player selector contract harness: PASS')
