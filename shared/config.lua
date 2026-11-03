MZMenuConfig = MZMenuConfig or {}

MZMenuConfig.BrandName = 'MZ Menu'
MZMenuConfig.DefaultPosition = 'top-right'
MZMenuConfig.DefaultDuration = 5000

-- Backend:
-- 'nui'    = usa a NUI própria do mz_menu.
-- 'auto'   = tenta NUI própria primeiro e usa ox_lib se lib estiver disponível.
-- 'ox_lib' = força ox_lib, se lib estiver disponível neste resource.
MZMenuConfig.Backend = 'nui'
MZMenuConfig.UseOxFallback = true

-- Permite movimentar o personagem enquanto o contexto continua interativo.
-- A tecla alterna apenas o movimento; teclado e mouse permanecem no mz_menu.
-- Use uma tecla de funcao (F1 a F12) para que NUI e key mapping reconhecam o mesmo valor.
MZMenuConfig.EnableMovementWhileOpen = true
MZMenuConfig.MovementToggleKey = 'F6'
MZMenuConfig.MovementEnabledByDefault = false

-- Nomes legados preservados para consumidores que ja os consultam.
MZMenuConfig.EnableFocusToggle = true
MZMenuConfig.FocusToggleKey = 'F6'

-- Visual da NUI própria.
MZMenuConfig.Theme = {
  accent = '#009FE3',
  accent2 = '#67C9F1',
  position = 'left', -- left | right | center
  width = 380,
}

-- Deixe true em desenvolvimento para testar o menu com /mz_menu_test.
MZMenuConfig.EnableTestCommand = false
MZMenuConfig.TestCommand = 'mz_menu_test'

-- Prefixo usado quando precisar cair em fallback via chat.
MZMenuConfig.ChatPrefix = 'mz_menu'
