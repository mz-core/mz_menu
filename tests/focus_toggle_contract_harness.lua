local function expect(condition, message)
  if not condition then error(message, 2) end
end

local function read(path)
  local file, err = io.open(path, 'rb')
  if not file then error(err, 2) end
  local content = file:read('*a')
  file:close()
  return content
end

local client = read('mz_menu/client/main.lua')
local config = read('mz_menu/shared/config.lua')
local app = read('mz_menu/web/app.js')
local html = read('mz_menu/web/index.html')

for _, exportName in ipairs({
  'Notify', 'OpenContext', 'OpenMenu', 'RegisterContext', 'RegisterSimpleMenu',
  'ShowContext', 'CloseContext', 'CloseMenu', 'HideContext', 'InputDialog',
  'AlertDialog', 'Confirm', 'IsReady', 'GetBackend'
}) do
  expect(
    client:find(("exports('%s'"):format(exportName), 1, true) ~= nil,
    'export legado ausente: ' .. exportName
  )
end

for _, exportName in ipairs({
  'SetContextFocus', 'ToggleContextFocus', 'IsContextFocused',
  'SetMovementEnabled', 'ToggleMovement', 'IsMovementEnabled'
}) do
  expect(
    client:find(("exports('%s'"):format(exportName), 1, true) ~= nil,
    'export de interacao ausente: ' .. exportName
  )
end

expect(
  config:find('MZMenuConfig.EnableMovementWhileOpen = true', 1, true) ~= nil,
  'movimento global nao inicia habilitado'
)
expect(
  config:find("MZMenuConfig.MovementToggleKey = 'F6'", 1, true) ~= nil,
  'tecla padrao de movimento nao e F6'
)
expect(
  config:find('MZMenuConfig.MovementEnabledByDefault = false', 1, true) ~= nil,
  'nova sessao de menu nao inicia com movimento travado'
)
expect(
  config:find('MZMenuConfig.EnableFocusToggle = true', 1, true) ~= nil
    and config:find("MZMenuConfig.FocusToggleKey = 'F6'", 1, true) ~= nil,
  'aliases legados de foco foram removidos'
)

expect(client:find('function MZMenu.SetMovementEnabled', 1, true) ~= nil, 'setter de movimento ausente')
expect(client:find('function MZMenu.ToggleMovement', 1, true) ~= nil, 'toggle de movimento ausente')
expect(client:find('function MZMenu.IsMovementEnabled', 1, true) ~= nil, 'consulta de movimento ausente')
expect(
  client:find("RegisterNUICallback('toggleMovement'", 1, true) ~= nil,
  'callback NUI de movimento ausente'
)
expect(
  client:find("'mz_menu_movement_toggle'", 1, true) ~= nil
    and client:find('RegisterKeyMapping(', 1, true) ~= nil,
  'key mapping de movimento ausente'
)
expect(
  client:find('SetNuiFocusKeepInput(enabled)', 1, true) ~= nil,
  'keep input nao acompanha o estado real do movimento'
)
expect(
  client:find('local MovementEnabled = false', 1, true) ~= nil
    and client:find('local contextAlreadyOpen = CurrentContextId ~= nil', 1, true) ~= nil
    and client:find('if not contextAlreadyOpen then', 1, true) ~= nil
    and client:find('MovementEnabled = defaultMovementEnabled()', 1, true) ~= nil,
  'estado de movimento nao inicia travado ou nao e preservado entre contextos'
)
expect(
  client:find('local previousMovement = beginNuiDialog()', 1, true) ~= nil
    and client:find('restoreMovementAfterDialog(previousMovement)', 1, true) ~= nil,
  'dialogo nao trava e restaura o movimento'
)
expect(
  client:find('DisableControlAction(0, control, true)', 1, true) ~= nil
    and client:find('local COMBAT_CONTROLS = {', 1, true) ~= nil,
  'controles de combate nao sao protegidos durante o repasse de input'
)
expect(html:find('id="focusToggleBtn"', 1, true) ~= nil, 'botao de rodape ausente')
expect(app:find("post('toggleMovement')", 1, true) ~= nil, 'frontend nao solicita alternancia de movimento')
expect(app:find("data.action === 'movementMode'", 1, true) ~= nil, 'frontend nao reflete o movimento')
expect(app:find('let movementEnabled = false;', 1, true) ~= nil, 'frontend nao inicia visualmente travado')
expect(
  app:find('setMovementMode(true, movementToggleKey);', 1, true) == nil,
  'frontend reinicia movimento ao trocar de contexto'
)
expect(
  app:find("movementEnabled ? 'travar movimento' : 'liberar movimento'", 1, true) ~= nil,
  'frontend nao informa corretamente a acao do toggle'
)
expect(client:find('HasGlobalPermission', 1, true) == nil, 'mz_menu recebeu regra de permissao')
expect(client:find('staff%.', 1) == nil, 'mz_menu recebeu capability Staff')

print('mz_menu movement passthrough contract harness: PASS')
