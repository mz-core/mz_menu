local MZMenu = {}

local ContextStore = {}
local PendingRequests = {}
local RequestCounter = 0
local NuiReady = false
local CurrentContextId = nil
local NuiFocused = false
local NuiDialogOpen = false
local LastFocusToggleAt = 0
local MovementEnabled = false
local LastMovementToggleAt = 0
local ActivePlayerSelector = nil
local shouldUseOx

local THEME_MIN_WIDTH = 320
local THEME_MAX_WIDTH = 640
local THEME_POSITIONS = {
  left = true,
  right = true,
  center = true
}

local MENU_LAYOUTS = {
  context = true,
  dashboard = true
}

local function sanitizeLayout(value)
  value = tostring(value or 'context'):lower()
  return MENU_LAYOUTS[value] and value or 'context'
end

local function cfg()
  return MZMenuConfig or {}
end

local function validFunctionKey(value)
  value = tostring(value or ''):upper()
  local number = tonumber(value:match('^F(%d+)$'))
  if number and number >= 1 and number <= 12 then return value end
  return nil
end

local function movementToggleKey()
  local config = cfg()
  return validFunctionKey(config.MovementToggleKey)
    or validFunctionKey(config.FocusToggleKey)
    or 'F6'
end

local function movementToggleEnabled()
  local config = cfg()
  if config.EnableMovementWhileOpen ~= nil then
    return config.EnableMovementWhileOpen ~= false
  end
  return config.EnableFocusToggle ~= false
end

local function defaultMovementEnabled()
  if not movementToggleEnabled() then return false end
  local configured = (cfg()).MovementEnabledByDefault
  if configured == nil then return false end
  return configured == true
end

local function actualMovementEnabled()
  return NuiFocused
    and CurrentContextId ~= nil
    and MovementEnabled
    and not NuiDialogOpen
end

local function applyMovementInput()
  local enabled = actualMovementEnabled()
  if type(SetNuiFocusKeepInput) == 'function' then
    SetNuiFocusKeepInput(enabled)
  end
  SendNUIMessage({
    action = 'movementMode',
    movementEnabled = enabled,
    contextOpen = CurrentContextId ~= nil,
    key = movementToggleKey(),
    toggleEnabled = movementToggleEnabled()
  })
  return enabled
end

local function setFocus(enabled)
  enabled = enabled == true
  NuiFocused = enabled
  SetNuiFocus(enabled, enabled)
  applyMovementInput()
end

function MZMenu.SetMovementEnabled(enabled)
  if not movementToggleEnabled() then return false, 'movement_toggle_disabled' end
  if shouldUseOx('context') then return false, 'unsupported_backend' end
  if not CurrentContextId then return false, 'context_not_open' end
  if NuiDialogOpen then return false, 'dialog_open' end

  MovementEnabled = enabled == true
  if not NuiFocused then
    setFocus(true)
  else
    applyMovementInput()
  end
  return true, MovementEnabled
end

function MZMenu.ToggleMovement()
  local now = GetGameTimer()
  if now - LastMovementToggleAt < 150 then return false, 'toggle_debounced' end
  LastMovementToggleAt = now
  return MZMenu.SetMovementEnabled(not MovementEnabled)
end

function MZMenu.IsMovementEnabled()
  return actualMovementEnabled()
end

local function restoreMovementAfterDialog(previousMovement)
  NuiDialogOpen = false
  MovementEnabled = previousMovement == true
  if CurrentContextId then
    setFocus(true)
  else
    setFocus(false)
  end
end

local function beginNuiDialog()
  local previousMovement = MovementEnabled
  NuiDialogOpen = true
  MovementEnabled = false
  setFocus(true)
  return previousMovement
end

local COMBAT_CONTROLS = {
  24, 25, 37, 44, 45,
  68, 69, 70, 91, 92,
  140, 141, 142, 143,
  257, 263, 264
}

CreateThread(function()
  while true do
    if actualMovementEnabled() then
      for _, control in ipairs(COMBAT_CONTROLS) do
        DisableControlAction(0, control, true)
      end
      Wait(0)
    else
      Wait(250)
    end
  end
end)

local function trim(value)
  return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')
end

local function debugPrint(...)
  if (cfg()).Debug == true then
    print('[mz_menu][debug]', ...)
  end
end

local function oxReady()
  return type(lib) == 'table'
end

local function contextReady()
  return oxReady()
    and type(lib.registerContext) == 'function'
    and type(lib.showContext) == 'function'
end

local function inputReady()
  return oxReady() and type(lib.inputDialog) == 'function'
end

local function alertReady()
  return oxReady() and type(lib.alertDialog) == 'function'
end

local function notifyReady()
  return oxReady() and type(lib.notify) == 'function'
end

local function nuiReady()
  return true -- ui_page é local; SendNUIMessage é seguro mesmo antes do callback ready.
end

shouldUseOx = function(kind)
  local backend = tostring((cfg()).Backend or 'nui')

  if backend == 'ox_lib' then
    if kind == 'context' then return contextReady() end
    if kind == 'input' then return inputReady() end
    if kind == 'alert' then return alertReady() end
    if kind == 'notify' then return notifyReady() end
    return oxReady()
  end

  if backend == 'auto' then
    return false -- NUI própria é prioridade. ox_lib só será usado se uma chamada NUI for desativada no futuro.
  end

  return false
end

local function chat(message, color)
  TriggerEvent('chat:addMessage', {
    color = color or { 120, 190, 255 },
    args = { tostring((cfg()).ChatPrefix or 'mz_menu'), tostring(message or '') }
  })
end

function MZMenu.SetContextFocus(enabled)
  if (cfg()).EnableFocusToggle == false then return false, 'focus_toggle_disabled' end
  if shouldUseOx('context') then return false, 'unsupported_backend' end
  if not CurrentContextId then return false, 'context_not_open' end
  if NuiDialogOpen then return false, 'dialog_open' end

  enabled = enabled == true
  if NuiFocused == enabled then return true, enabled end
  setFocus(enabled)
  return true, enabled
end

function MZMenu.ToggleContextFocus()
  local now = GetGameTimer()
  if now - LastFocusToggleAt < 150 then return false, 'toggle_debounced' end
  LastFocusToggleAt = now
  return MZMenu.SetContextFocus(not NuiFocused)
end

function MZMenu.IsContextFocused()
  return CurrentContextId ~= nil and NuiFocused == true
end

local function nextRequestId(prefix)
  RequestCounter = RequestCounter + 1
  return ('%s_%s_%s'):format(prefix or 'req', GetGameTimer(), RequestCounter)
end

local function awaitNui(requestId)
  local p = promise.new()
  PendingRequests[requestId] = p
  return Citizen.Await(p)
end

local function resolveRequest(requestId, result)
  requestId = trim(requestId)
  local p = PendingRequests[requestId]
  if not p then
    return false
  end

  PendingRequests[requestId] = nil
  p:resolve(result)
  return true
end

local function sanitizeSelectorText(value, maximum)
  value = tostring(value or ''):gsub('%c', ' '):gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
  return value:sub(1, maximum or 128)
end

local function sanitizeSelectorItem(item, index)
  if type(item) ~= 'table' then return nil end
  local source = tonumber(item.source)
  if source then source = math.floor(source) end
  local citizenid = sanitizeSelectorText(item.citizenid, 64)
  local accountId = tonumber(item.accountId or item.account_id)
  local characterId = tonumber(item.characterId or item.character_id)
  local key = sanitizeSelectorText(item.key, 128)
  if key == '' then
    key = source and ('source:%d:%s'):format(source, citizenid)
      or (citizenid ~= '' and ('character:%s'):format(citizenid) or ('item:%d'):format(index))
  end

  return {
    key = key,
    source = source,
    citizenid = citizenid ~= '' and citizenid or nil,
    accountId = accountId and math.floor(accountId) or nil,
    characterId = characterId and math.floor(characterId) or nil,
    name = sanitizeSelectorText(item.name, 96),
    characterName = sanitizeSelectorText(item.characterName or item.character_name, 128),
    online = item.online == true and source ~= nil,
    self = item.self == true,
    ping = math.max(0, math.floor(tonumber(item.ping) or 0))
  }
end

local function sanitizeSelectorResult(result, page, pageSize)
  result = type(result) == 'table' and result or {}
  local items = {}
  for index, item in ipairs(type(result.items) == 'table' and result.items or {}) do
    local sanitized = sanitizeSelectorItem(item, index)
    if sanitized then items[#items + 1] = sanitized end
  end
  return {
    items = items,
    page = math.max(1, math.floor(tonumber(result.page) or page or 1)),
    pageSize = math.max(1, math.min(50, math.floor(tonumber(result.pageSize) or pageSize or 25))),
    total = math.max(0, math.floor(tonumber(result.total) or #items)),
    hasMore = result.hasMore == true,
    hint = sanitizeSelectorText(result.hint, 160)
  }
end

local function selectorDisplayResult(result)
  local items = {}
  for _, item in ipairs(result.items) do
    items[#items + 1] = {
      key = item.key,
      source = item.online and item.source or nil,
      name = item.name,
      characterName = item.characterName,
      online = item.online,
      self = item.self,
      ping = item.ping
    }
  end
  return {
    items = items,
    page = result.page,
    pageSize = result.pageSize,
    total = result.total,
    hasMore = result.hasMore,
    hint = result.hint
  }
end

local function loadPlayerSelectorPage(query, filter, page, append)
  local selector = ActivePlayerSelector
  if not selector then return end
  selector.generation = selector.generation + 1
  local generation = selector.generation

  CreateThread(function()
    local ok, result = pcall(selector.fetch, query, filter, page, selector.pageSize)
    if ActivePlayerSelector ~= selector or selector.generation ~= generation then return end
    if not ok then
      debugPrint('player selector fetch falhou:', result)
      result = { items = {}, page = page, pageSize = selector.pageSize, hint = 'Falha ao buscar jogadores.' }
    end

    local normalized = sanitizeSelectorResult(result, page, selector.pageSize)
    if append ~= true then selector.items = {} end
    for _, item in ipairs(normalized.items) do selector.items[item.key] = item end
    SendNUIMessage({
      action = 'playerSelectorResults',
      requestId = selector.requestId,
      result = selectorDisplayResult(normalized),
      append = append == true
    })
  end)
end

local function finishPlayerSelector(selected, restorePrevious)
  local selector = ActivePlayerSelector
  if not selector then return false end
  ActivePlayerSelector = nil
  SendNUIMessage({ action = 'close' })
  setFocus(false)
  selector.promise:resolve(selected)
  if restorePrevious == true and selector.previousContextId then
    SetTimeout(0, function()
      if not ActivePlayerSelector and CurrentContextId == selector.previousContextId then
        MZMenu.ShowContext(selector.previousContextId)
      end
    end)
  end
  return true
end

local function notifyPayload(messageOrData, kind, duration, extra)
  local data

  if type(messageOrData) == 'table' then
    data = messageOrData
  else
    data = type(extra) == 'table' and extra or {}
    data.description = data.description or tostring(messageOrData or '')
    data.type = data.type or kind or 'inform'
    data.duration = data.duration or duration or (cfg()).DefaultDuration or 5000
  end

  if data.type == 'info' then
    data.type = 'inform'
  end

  data.title = data.title or (cfg()).BrandName or 'MZ Menu'
  data.position = data.position or (cfg()).DefaultPosition or 'top-right'
  data.duration = tonumber(data.duration) or (cfg()).DefaultDuration or 5000

  return data
end

local function validHexColor(value)
  return type(value) == 'string' and value:match('^#%x%x%x%x%x%x$') ~= nil
end

local function sanitizeThemePatch(theme)
  if type(theme) ~= 'table' then return nil end

  local sanitized = {}
  if validHexColor(theme.accent) then sanitized.accent = theme.accent end
  if validHexColor(theme.accent2) then sanitized.accent2 = theme.accent2 end

  local position = type(theme.position) == 'string' and theme.position:lower() or nil
  if position and THEME_POSITIONS[position] then sanitized.position = position end

  local width = tonumber(theme.width)
  if width then
    sanitized.width = math.floor(math.max(THEME_MIN_WIDTH, math.min(THEME_MAX_WIDTH, width)))
  end

  return next(sanitized) and sanitized or nil
end

local function mergeTheme(base, patch)
  local merged = {}
  for key, value in pairs(type(base) == 'table' and base or {}) do merged[key] = value end
  for key, value in pairs(type(patch) == 'table' and patch or {}) do merged[key] = value end
  return merged
end

local function globalTheme()
  return mergeTheme({
    accent = '#009FE3',
    accent2 = '#67C9F1',
    position = 'left',
    width = 380
  }, sanitizeThemePatch((cfg()).Theme))
end

local function resolveContextVisual(id)
  local chain, seen = {}, {}
  local currentId = trim(id)

  while currentId ~= '' and not seen[currentId] and #chain < 32 do
    seen[currentId] = true
    local context = ContextStore[currentId]
    if not context then break end
    table.insert(chain, 1, context)
    currentId = trim(context.menu)
  end

  local theme = globalTheme()
  local brand = (cfg()).BrandName or 'MZ Menu'
  local headerIcon, badge
  for _, context in ipairs(chain) do
    theme = mergeTheme(theme, context.theme)
    if trim(context.brand) ~= '' then brand = tostring(context.brand) end
    if trim(context.headerIcon) ~= '' then headerIcon = tostring(context.headerIcon) end
    if trim(context.badge) ~= '' then badge = tostring(context.badge) end
  end

  return theme, brand, headerIcon, badge
end

local function sendTheme(theme, brand)
  SendNUIMessage({
    action = 'theme',
    theme = theme or globalTheme(),
    brand = brand or (cfg()).BrandName or 'MZ Menu'
  })
end

local function sendCurrentTheme()
  if CurrentContextId then
    local theme, brand = resolveContextVisual(CurrentContextId)
    sendTheme(theme, brand)
    return
  end
  sendTheme()
end

function MZMenu.Notify(messageOrData, kind, duration, extra)
  local data = notifyPayload(messageOrData, kind, duration, extra)

  if shouldUseOx('notify') then
    lib.notify(data)
    return true, 'ox_lib'
  end

  if nuiReady() then
    sendCurrentTheme()
    SendNUIMessage({ action = 'notify', data = data })
    return true, 'nui'
  end

  chat(data.description or data.title or 'Notificacao', data.type == 'error' and { 255, 100, 100 } or nil)
  return false, 'chat_fallback'
end

local function executeOption(option)
  option = type(option) == 'table' and option or {}
  local args = option.args

  if option.disabled == true or option.readOnly == true then
    return
  end

  if type(option.onSelect) == 'function' then
    option.onSelect(args, option)
    return
  end

  if trim(option.menu) ~= '' then
    MZMenu.ShowContext(option.menu)
    return
  end

  if trim(option.event) ~= '' then
    TriggerEvent(option.event, args, option)
    return
  end

  if trim(option.serverEvent) ~= '' then
    TriggerServerEvent(option.serverEvent, args, option)
    return
  end

  if trim(option.command) ~= '' then
    ExecuteCommand(option.command)
    return
  end

  if type(option.params) == 'table' then
    local params = option.params
    if trim(params.event) ~= '' then
      if params.isServer == true or params.type == 'server' then
        TriggerServerEvent(params.event, params.args, option)
      elseif params.type == 'command' then
        ExecuteCommand(params.event)
      else
        TriggerEvent(params.event, params.args, option)
      end
      return
    end
  end
end

local function executeLifecycle(context, callbackName)
  context = type(context) == 'table' and context or {}
  local callback = context[callbackName]
  if type(callback) == 'function' then
    callback()
    return true
  end

  local eventName = trim(context[callbackName .. 'Event'])
  if eventName ~= '' then
    TriggerEvent(eventName, context[callbackName .. 'Args'], context)
    return true
  end

  return false
end

local function uiOption(option, index)
  option = type(option) == 'table' and option or {}
  local optionType = tostring(option.type or 'action'):lower()
  if optionType ~= 'section' then optionType = 'action' end

  return {
    index = index,
    type = optionType,
    label = option.label,
    title = tostring(option.title or option.label or 'Opcao'),
    description = option.description,
    icon = option.icon,
    iconColor = option.iconColor,
    image = option.image,
    disabled = option.disabled == true,
    readOnly = option.readOnly == true or optionType == 'section',
    metadata = option.metadata,
    progress = option.progress,
    colorScheme = option.colorScheme,
    arrow = option.arrow,
    menu = option.menu,
    values = option.values,
    checked = option.checked,
    close = option.close,
    iconAnimation = option.iconAnimation,
    badge = option.badge,
    badgeVariant = option.badgeVariant,
    status = option.status,
    statusVariant = option.statusVariant,
    shortcut = option.shortcut,
    destructive = option.destructive == true,
    tone = option.tone
  }
end

local function oxOption(option)
  option = type(option) == 'table' and option or {}

  local normalized = {}
  local passthrough = {
    'title', 'description', 'icon', 'iconColor', 'image', 'disabled', 'readOnly',
    'metadata', 'progress', 'colorScheme', 'arrow', 'menu', 'event', 'serverEvent',
    'args', 'values', 'checked', 'close', 'iconAnimation'
  }

  for _, key in ipairs(passthrough) do
    if option[key] ~= nil then
      normalized[key] = option[key]
    end
  end

  normalized.title = tostring(normalized.title or 'Opcao')

  if type(option.onSelect) == 'function'
    or trim(option.event) ~= ''
    or trim(option.serverEvent) ~= ''
    or trim(option.command) ~= ''
    or type(option.params) == 'table'
    or trim(option.menu) ~= ''
  then
    normalized.onSelect = function()
      executeOption(option)
    end
  elseif type(option.onSelect) ~= 'nil' then
    debugPrint('onSelect ignorado: tipo invalido em', normalized.title)
  end

  return normalized
end

local function normalizeMenu(menu)
  menu = type(menu) == 'table' and menu or {}

  local id = trim(menu.id)
  if id == '' then
    id = ('mz_menu_%s'):format(GetGameTimer())
  end

  local stored = {
    id = id,
    title = tostring(menu.title or menu.header or 'Menu'),
    subtitle = menu.subtitle or menu.description or menu.brand,
    brand = menu.brand,
    headerIcon = menu.headerIcon,
    badge = menu.badge,
    layout = sanitizeLayout(menu.layout),
    searchable = menu.searchable == true,
    searchPlaceholder = menu.searchPlaceholder,
    user = type(menu.user) == 'table' and menu.user or nil,
    stats = type(menu.stats) == 'table' and menu.stats or nil,
    theme = sanitizeThemePatch(menu.theme),
    menu = menu.menu,
    canClose = menu.canClose,
    onExit = menu.onExit,
    onBack = menu.onBack,
    onExitEvent = menu.onExitEvent,
    onExitArgs = menu.onExitArgs,
    onBackEvent = menu.onBackEvent,
    onBackArgs = menu.onBackArgs,
    options = {}
  }

  local ui = {
    id = stored.id,
    title = stored.title,
    subtitle = stored.subtitle,
    brand = stored.brand,
    headerIcon = stored.headerIcon,
    badge = stored.badge,
    layout = stored.layout,
    searchable = stored.searchable,
    searchPlaceholder = stored.searchPlaceholder,
    user = stored.user,
    stats = stored.stats,
    menu = stored.menu,
    canClose = stored.canClose ~= false,
    options = {}
  }

  local ox = {
    id = stored.id,
    title = stored.title,
    subtitle = stored.subtitle,
    menu = stored.menu,
    canClose = stored.canClose,
    onExit = (type(stored.onExit) == 'function' or trim(stored.onExitEvent) ~= '') and function()
      executeLifecycle(stored, 'onExit')
    end or nil,
    onBack = (type(stored.onBack) == 'function' or trim(stored.onBackEvent) ~= '') and function()
      executeLifecycle(stored, 'onBack')
    end or nil,
    options = {}
  }

  if type(menu.options) == 'table' then
    for index, option in ipairs(menu.options) do
      stored.options[index] = option
      ui.options[#ui.options + 1] = uiOption(option, index)
      ox.options[#ox.options + 1] = oxOption(option)
    end
  end

  return stored, ui, ox
end

function MZMenu.RegisterContext(menu)
  local stored, ui, ox = normalizeMenu(menu)
  ContextStore[stored.id] = stored

  if shouldUseOx('context') then
    lib.registerContext(ox)
    return true, stored.id, 'ox_lib'
  end

  return true, stored.id, 'nui'
end

function MZMenu.ShowContext(id)
  id = trim(id)
  if id == '' then
    return false, 'invalid_context_id'
  end

  local stored = ContextStore[id]
  if not stored then
    return false, 'context_not_registered'
  end

  if shouldUseOx('context') then
    if not contextReady() then
      MZMenu.Notify('ox_lib context indisponivel. Use os comandos como fallback.', 'error')
      return false, 'ox_lib_context_unavailable'
    end

    CurrentContextId = id
    lib.showContext(id)
    return true, 'ox_lib'
  end

  local _, ui = normalizeMenu(stored)
  local contextAlreadyOpen = CurrentContextId ~= nil
  CurrentContextId = id
  if not contextAlreadyOpen then
    MovementEnabled = defaultMovementEnabled()
  end
  local theme, brand, inheritedHeaderIcon, inheritedBadge = resolveContextVisual(id)
  ui.brand = ui.brand or brand
  ui.headerIcon = ui.headerIcon or inheritedHeaderIcon
  ui.badge = ui.badge or inheritedBadge
  sendTheme(theme, brand)
  SendNUIMessage({ action = 'openContext', menu = ui })
  setFocus(true)
  return true, 'nui'
end

function MZMenu.OpenContext(menu)
  local ok, idOrErr = MZMenu.RegisterContext(menu)
  if not ok then
    return false, idOrErr
  end

  return MZMenu.ShowContext(idOrErr)
end

function MZMenu.OpenMenu(menu)
  return MZMenu.OpenContext(menu)
end

function MZMenu.RegisterSimpleMenu(id, title, options, parent)
  return MZMenu.RegisterContext({
    id = id,
    title = title,
    menu = parent,
    options = options or {}
  })
end

function MZMenu.CloseContext()
  if ActivePlayerSelector then finishPlayerSelector(nil, false) end

  if shouldUseOx('context') and oxReady() and type(lib.hideContext) == 'function' then
    lib.hideContext(true)
  end

  CurrentContextId = nil
  MovementEnabled = false
  SendNUIMessage({ action = 'close' })
  sendTheme()
  setFocus(false)
  return true
end

local function nuiInputDialog(title, rows, options)
  local requestId = nextRequestId('input')
  local previousMovement = beginNuiDialog()
  sendCurrentTheme()
  SendNUIMessage({
    action = 'inputDialog',
    requestId = requestId,
    title = tostring(title or 'Input'),
    rows = type(rows) == 'table' and rows or {},
    options = type(options) == 'table' and options or {}
  })
  local response = awaitNui(requestId)
  restoreMovementAfterDialog(previousMovement)

  if not response or response.cancelled then
    return nil
  end

  return response.values
end

function MZMenu.InputDialog(title, rows, options)
  if shouldUseOx('input') then
    title = tostring(title or 'Input')
    rows = type(rows) == 'table' and rows or {}
    options = type(options) == 'table' and options or {}

    local ok, result = pcall(function()
      return lib.inputDialog(title, rows, options)
    end)

    if not ok then
      MZMenu.Notify(('Falha no inputDialog: %s'):format(tostring(result)), 'error')
      return nil, tostring(result)
    end

    return result
  end

  return nuiInputDialog(title, rows, options)
end

local function normalizeAlert(dataOrTitle, content, options)
  local data
  if type(dataOrTitle) == 'table' then
    data = dataOrTitle
  else
    data = type(options) == 'table' and options or {}
    data.header = data.header or tostring(dataOrTitle or 'Alerta')
    data.content = data.content or tostring(content or '')
  end

  if data.centered == nil then
    data.centered = true
  end

  return data
end

local function nuiAlertDialog(data)
  local requestId = nextRequestId('alert')
  local previousMovement = beginNuiDialog()
  sendCurrentTheme()
  SendNUIMessage({
    action = 'alertDialog',
    requestId = requestId,
    data = data
  })
  local response = awaitNui(requestId)
  restoreMovementAfterDialog(previousMovement)

  if not response or response.cancelled then
    return 'cancel'
  end

  return response.result or 'confirm'
end

function MZMenu.AlertDialog(dataOrTitle, content, options)
  local data = normalizeAlert(dataOrTitle, content, options)

  if shouldUseOx('alert') then
    local ok, result = pcall(function()
      return lib.alertDialog(data)
    end)

    if not ok then
      MZMenu.Notify(('Falha no alertDialog: %s'):format(tostring(result)), 'error')
      return nil, tostring(result)
    end

    return result
  end

  return nuiAlertDialog(data)
end

function MZMenu.Confirm(title, content, options)
  options = type(options) == 'table' and options or {}
  options.header = options.header or tostring(title or 'Confirmar')
  options.content = options.content or tostring(content or 'Confirmar acao?')
  options.centered = options.centered ~= false
  options.cancel = options.cancel ~= false

  local result = MZMenu.AlertDialog(options)
  return result == 'confirm'
end

function MZMenu.PlayerSelector(options)
  options = type(options) == 'table' and options or {}
  if not nuiReady() then return nil, 'nui_unavailable' end
  if ActivePlayerSelector then return nil, 'selector_busy' end

  local fetch = options.fetch
  local providerExport = sanitizeSelectorText(options.provider, 64)
  if providerExport ~= '' then
    local invokingResource = type(GetInvokingResource) == 'function' and GetInvokingResource() or nil
    if type(invokingResource) ~= 'string' or invokingResource == ''
      or not providerExport:match('^[%w:_-]+$') then
      return nil, 'invalid_provider'
    end

    fetch = function(query, filter, page, pageSize)
      if GetResourceState(invokingResource) ~= 'started' then
        error('player_selector_provider_unavailable')
      end
      local provider = exports[invokingResource]
      return provider[providerExport](provider, query, filter, page, pageSize)
    end
  end
  if type(fetch) ~= 'function' then return nil, 'fetch_required' end

  local requestId = nextRequestId('player_selector')
  local pending = promise.new()
  local filters = type(options.filters) == 'table' and options.filters or { 'all', 'online', 'offline' }
  local allowedFilters = {}
  local allowedFilterSet = {}
  for _, value in ipairs(filters) do
    value = tostring(value or ''):lower()
    if (value == 'all' or value == 'online' or value == 'offline') and not allowedFilterSet[value] then
      allowedFilters[#allowedFilters + 1] = value
      allowedFilterSet[value] = true
    end
  end
  if #allowedFilters == 0 then
    allowedFilters = { 'all', 'online', 'offline' }
    allowedFilterSet = { all = true, online = true, offline = true }
  end
  local defaultFilter = tostring(options.defaultFilter or allowedFilters[1]):lower()
  if not allowedFilterSet[defaultFilter] then defaultFilter = allowedFilters[1] end

  ActivePlayerSelector = {
    requestId = requestId,
    promise = pending,
    fetch = fetch,
    pageSize = math.max(1, math.min(50, math.floor(tonumber(options.pageSize) or 25))),
    allowedFilters = allowedFilterSet,
    defaultFilter = defaultFilter,
    previousContextId = CurrentContextId,
    generation = 0,
    items = {}
  }

  if shouldUseOx('context') and oxReady() and type(lib.hideContext) == 'function' then
    lib.hideContext(false)
  end

  sendCurrentTheme()
  SendNUIMessage({
    action = 'openPlayerSelector',
    selector = {
      requestId = requestId,
      title = sanitizeSelectorText(options.title or 'Selecionar jogador', 96),
      subtitle = sanitizeSelectorText(options.subtitle or 'Online agora; pesquise para localizar Characters offline.', 160),
      brand = sanitizeSelectorText(options.brand or (cfg()).BrandName or 'MZ Menu', 64),
      filters = allowedFilters,
      defaultFilter = defaultFilter,
      searchPlaceholder = sanitizeSelectorText(options.searchPlaceholder or 'Nome, Character, citizenid ou source...', 128),
      minimumOfflineSearch = math.max(1, math.min(8, math.floor(tonumber(options.minimumOfflineSearch) or 2)))
    }
  })
  setFocus(true)
  loadPlayerSelectorPage('', defaultFilter, 1, false)

  return Citizen.Await(pending)
end

function MZMenu.IsReady()
  if tostring((cfg()).Backend or 'nui') == 'ox_lib' then
    return contextReady() and inputReady() and alertReady()
  end

  return nuiReady()
end

function MZMenu.GetBackend()
  local backend = tostring((cfg()).Backend or 'nui')
  if backend == 'ox_lib' and contextReady() and inputReady() and alertReady() then
    return 'ox_lib'
  end
  if backend == 'ox_lib' then
    return 'fallback'
  end
  return 'nui'
end

exports('Notify', MZMenu.Notify)
exports('OpenContext', MZMenu.OpenContext)
exports('OpenMenu', MZMenu.OpenMenu)
exports('RegisterContext', MZMenu.RegisterContext)
exports('RegisterSimpleMenu', MZMenu.RegisterSimpleMenu)
exports('ShowContext', MZMenu.ShowContext)
exports('CloseContext', MZMenu.CloseContext)
exports('CloseMenu', MZMenu.CloseContext)
exports('HideContext', MZMenu.CloseContext)
exports('InputDialog', MZMenu.InputDialog)
exports('AlertDialog', MZMenu.AlertDialog)
exports('Confirm', MZMenu.Confirm)
exports('PlayerSelector', MZMenu.PlayerSelector)
exports('IsReady', MZMenu.IsReady)
exports('GetBackend', MZMenu.GetBackend)
exports('SetContextFocus', MZMenu.SetContextFocus)
exports('ToggleContextFocus', MZMenu.ToggleContextFocus)
exports('IsContextFocused', MZMenu.IsContextFocused)
exports('SetMovementEnabled', MZMenu.SetMovementEnabled)
exports('ToggleMovement', MZMenu.ToggleMovement)
exports('IsMovementEnabled', MZMenu.IsMovementEnabled)

RegisterNetEvent('mz_menu:client:notify', function(messageOrData, kind, duration, extra)
  MZMenu.Notify(messageOrData, kind, duration, extra)
end)

RegisterNetEvent('mz_menu:client:openContext', function(menu)
  MZMenu.OpenContext(menu)
end)

RegisterNetEvent('mz_menu:client:alert', function(dataOrTitle, content, options)
  MZMenu.AlertDialog(dataOrTitle, content, options)
end)

RegisterNetEvent('mz_menu:client:close', function()
  MZMenu.CloseContext()
end)

RegisterNUICallback('ready', function(_, cb)
  NuiReady = true
  sendTheme()
  cb({ ok = true })
end)

RegisterNUICallback('toggleFocus', function(_, cb)
  local ok, stateOrError = MZMenu.ToggleContextFocus()
  cb({
    ok = ok == true,
    focused = ok == true and stateOrError or NuiFocused,
    error = ok == true and nil or stateOrError
  })
end)

RegisterNUICallback('toggleMovement', function(_, cb)
  local ok, stateOrError = MZMenu.ToggleMovement()
  cb({
    ok = ok == true,
    movementEnabled = ok == true and stateOrError or actualMovementEnabled(),
    error = ok == true and nil or stateOrError
  })
end)

RegisterNUICallback('select', function(data, cb)
  cb({ ok = true })

  local id = trim(data and data.id)
  local index = tonumber(data and data.index)
  local context = ContextStore[id]
  if not context or not index or not context.options[index] then
    return
  end

  executeOption(context.options[index])
end)

RegisterNUICallback('playerSelectorSearch', function(data, cb)
  local selector = ActivePlayerSelector
  if not selector or tostring(data and data.requestId or '') ~= selector.requestId then
    cb({ ok = false, error = 'selector_not_active' })
    return
  end
  local query = sanitizeSelectorText(data and data.query, 64)
  local filter = tostring(data and data.filter or 'all'):lower()
  if not selector.allowedFilters[filter] then filter = selector.defaultFilter end
  local page = math.max(1, math.floor(tonumber(data and data.page) or 1))
  cb({ ok = true })
  loadPlayerSelectorPage(query, filter, page, data and data.append == true)
end)

RegisterNUICallback('playerSelectorSelect', function(data, cb)
  local selector = ActivePlayerSelector
  if not selector or tostring(data and data.requestId or '') ~= selector.requestId then
    cb({ ok = false, error = 'selector_not_active' })
    return
  end
  local key = sanitizeSelectorText(data and data.key, 128)
  local selected = selector.items[key]
  if not selected then
    cb({ ok = false, error = 'invalid_selection' })
    return
  end
  cb({ ok = true })
  finishPlayerSelector(selected, false)
end)

RegisterNUICallback('playerSelectorCancel', function(data, cb)
  local selector = ActivePlayerSelector
  if not selector or tostring(data and data.requestId or '') ~= selector.requestId then
    cb({ ok = false, error = 'selector_not_active' })
    return
  end
  cb({ ok = true })
  local restorePrevious = data and data.restorePrevious ~= false
  finishPlayerSelector(nil, restorePrevious)
  if not restorePrevious then
    CurrentContextId = nil
    MovementEnabled = false
    sendTheme()
  end
end)

RegisterNUICallback('back', function(data, cb)
  cb({ ok = true })

  local id = trim(data and data.id)
  local context = ContextStore[id]

  if context and executeLifecycle(context, 'onBack') then
    return
  end

  if context and trim(context.menu) ~= '' then
    MZMenu.ShowContext(context.menu)
    return
  end
end)

RegisterNUICallback('close', function(_, cb)
  cb({ ok = true })

  if ActivePlayerSelector then
    finishPlayerSelector(nil, true)
    return
  end

  local context = CurrentContextId and ContextStore[CurrentContextId]
  CurrentContextId = nil
  MovementEnabled = false
  setFocus(false)
  sendTheme()

  if context then executeLifecycle(context, 'onExit') end
end)

RegisterNUICallback('inputSubmit', function(data, cb)
  cb({ ok = true })
  resolveRequest(data and data.requestId, { values = data and data.values or {}, keepFocus = CurrentContextId ~= nil })
end)

RegisterNUICallback('inputCancel', function(data, cb)
  cb({ ok = true })
  resolveRequest(data and data.requestId, { cancelled = true, keepFocus = CurrentContextId ~= nil })
end)

RegisterNUICallback('alertSubmit', function(data, cb)
  cb({ ok = true })
  resolveRequest(data and data.requestId, { result = data and data.result or 'confirm', keepFocus = CurrentContextId ~= nil })
end)

RegisterCommand('mz_menu_focus_toggle', function()
  MZMenu.ToggleMovement()
end, false)

RegisterCommand('mz_menu_movement_toggle', function()
  MZMenu.ToggleMovement()
end, false)

RegisterKeyMapping(
  'mz_menu_movement_toggle',
  'Travar ou liberar movimento com o menu aberto',
  'keyboard',
  movementToggleKey()
)

CreateThread(function()
  Wait(750)
  sendTheme()
  debugPrint(('backend=%s ready=%s nuiReady=%s'):format(MZMenu.GetBackend(), tostring(MZMenu.IsReady()), tostring(NuiReady)))
end)

if (cfg()).EnableTestCommand ~= false then
  RegisterCommand((cfg()).TestCommand or 'mz_menu_test', function()
    MZMenu.OpenContext({
      id = 'mz_menu_test_main',
      title = 'MZ Menu - Teste',
      subtitle = 'Compatibilidade + layout dashboard',
      brand = 'MZ Interface',
      headerIcon = 'shield',
      badge = 'TEST',
      layout = 'dashboard',
      searchable = true,
      searchPlaceholder = 'Buscar uma acao de teste...',
      user = { name = GetPlayerName(PlayerId()) or 'Player', role = 'TESTER' },
      stats = {
        { label = 'Backend', value = MZMenu.GetBackend(), variant = 'info' },
        { label = 'Movimento', value = movementToggleKey(), variant = 'success' },
        { label = 'API', value = 'LEGACY OK', variant = 'success' }
      },
      options = {
        {
          title = 'Notificacao de sucesso',
          description = 'Testa exports/notify usando NUI propria.',
          icon = 'bell',
          onSelect = function()
            MZMenu.Notify('Notificacao funcionando.', 'success')
          end
        },
        {
          title = 'Input dialog',
          description = 'Testa InputDialog padronizado.',
          icon = 'keyboard',
          onSelect = function()
            local input = MZMenu.InputDialog('Teste de Input', {
              { type = 'input', label = 'Codigo', required = true, default = 'teste_01' },
              { type = 'input', label = 'Nome', required = true, default = 'Teste 01' },
              { type = 'number', label = 'Numero', required = false, default = 1 },
              { type = 'checkbox', label = 'Ativo', checked = true },
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

            if input then
              MZMenu.Notify(('Input recebido: %s'):format(json.encode(input)), 'inform', 8000)
            else
              MZMenu.Notify('Input cancelado.', 'warning')
            end
          end
        },
        {
          title = 'Confirmacao',
          description = 'Testa AlertDialog com confirmar/cancelar.',
          icon = 'circle-check',
          onSelect = function()
            local confirmed = MZMenu.Confirm('Confirmar teste', 'Deseja confirmar esta acao?')
            MZMenu.Notify(confirmed and 'Confirmado.' or 'Cancelado.', confirmed and 'success' or 'warning')
          end
        },
        {
          title = 'Submenu',
          description = 'Exemplo de submenu registrado antes de abrir.',
          icon = 'layers',
          menu = 'mz_menu_test_sub'
        },
        {
          title = 'Fechar',
          icon = 'x',
          onSelect = function()
            MZMenu.CloseContext()
          end
        }
      }
    })

    MZMenu.RegisterContext({
      id = 'mz_menu_test_sub',
      title = 'Submenu de teste',
      menu = 'mz_menu_test_main',
      options = {
        { title = 'Voltar pelo botão superior', description = 'Use ESC ou voltar.', icon = 'arrow-left' },
        { title = 'Notify info', icon = 'info', onSelect = function() MZMenu.Notify('Submenu OK.', 'inform') end }
      }
    })
  end, false)
end

if (cfg()).EnableTestCommand ~= false then
  RegisterCommand('mz_menu_theme_test', function()
    local profiles = {
      { key = 'job', label = 'Job', icon = 'shield', accent = '#009FE3', accent2 = '#67C9F1' },
      { key = 'gang', label = 'Gang', icon = 'skull', accent = '#DC2626', accent2 = '#7C3AED' },
      { key = 'business', label = 'Business', icon = 'briefcase', accent = '#D97706', accent2 = '#FACC15' },
      { key = 'government', label = 'Government', icon = 'landmark', accent = '#0F766E', accent2 = '#22C55E' },
      { key = 'vip', label = 'VIP', icon = 'crown', accent = '#7C3AED', accent2 = '#D946EF' },
      { key = 'event', label = 'Event', icon = 'calendar', accent = '#DB2777', accent2 = '#F97316' },
      { key = 'staff', label = 'Staff', icon = 'settings', accent = '#334155', accent2 = '#0EA5E9' }
    }

    local selectorOptions = {}
    for index, profile in ipairs(profiles) do
      local rootId = 'mz_menu_theme_test:' .. profile.key
      local childId = rootId .. ':child'
      local position = index % 3 == 1 and 'left' or (index % 3 == 2 and 'right' or 'center')

      MZMenu.RegisterContext({
        id = childId,
        title = profile.label .. ' - Submenu',
        subtitle = 'Tema herdado do contexto pai',
        menu = rootId,
        options = {
          {
            title = 'Heranca ativa',
            description = 'Este submenu nao declarou theme, brand, headerIcon ou badge.',
            icon = 'check',
            readOnly = true
          }
        }
      })

      MZMenu.RegisterContext({
        id = rootId,
        title = profile.label .. ' Theme',
        subtitle = ('Perfil %s / posicao %s'):format(profile.key, position),
        brand = 'MZ Context Themes',
        headerIcon = profile.icon,
        badge = profile.key:upper(),
        menu = 'mz_menu_theme_test:selector',
        theme = {
          accent = profile.accent,
          accent2 = profile.accent2,
          position = position,
          width = 360 + (index * 12)
        },
        options = {
          {
            title = 'Abrir submenu sem tema proprio',
            description = 'Valida a heranca visual do contexto pai.',
            icon = 'layers',
            menu = childId
          },
          {
            title = 'Fechar e restaurar tema global',
            icon = 'x',
            onSelect = function() MZMenu.CloseContext() end
          }
        }
      })

      selectorOptions[#selectorOptions + 1] = {
        title = profile.label,
        description = profile.accent .. ' / ' .. profile.accent2,
        icon = profile.icon,
        menu = rootId
      }
    end

    MZMenu.OpenContext({
      id = 'mz_menu_theme_test:selector',
      title = 'Context Theme Test',
      subtitle = 'Selecione um dos sete perfis visuais',
      brand = 'MZ Menu',
      headerIcon = 'layers',
      badge = 'TEST',
      options = selectorOptions
    })
  end, false)
end

_G.MZMenu = MZMenu

AddEventHandler('onResourceStop', function(resourceName)
  if resourceName ~= GetCurrentResourceName() then return end
  if ActivePlayerSelector then finishPlayerSelector(nil, false) end
  CurrentContextId = nil
  NuiDialogOpen = false
  MovementEnabled = false
  setFocus(false)
end)
