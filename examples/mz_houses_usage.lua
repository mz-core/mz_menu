-- Exemplo de como um resource como mz_houses pode usar o mz_menu.
-- Isto é só referência. Não coloque este arquivo para rodar em produção sem adaptar.

RegisterCommand('exemplo_mhouse_admin_mz_menu', function()
  exports['mz_menu']:OpenContext({
    id = 'exemplo_mhouse_admin',
    title = 'Gerenciar Imoveis',
    options = {
      {
        title = 'Criar imovel aqui',
        description = 'Abre input e depois chama evento seguro do resource',
        icon = 'plus',
        onSelect = function()
          local input = exports['mz_menu']:InputDialog('Criar imovel', {
            { type = 'input', label = 'Codigo', required = true },
            { type = 'input', label = 'Nome', required = true },
            { type = 'input', label = 'Shell', default = 'shell_test' }
          })

          if not input then
            return
          end

          local ped = PlayerPedId()
          local coords = GetEntityCoords(ped)
          local heading = GetEntityHeading(ped)

          TriggerServerEvent('mz_houses:server:admin:createProperty', {
            code = input[1],
            label = input[2],
            shell = input[3],
            coords = { x = coords.x, y = coords.y, z = coords.z, w = heading }
          })
        end
      },
      {
        title = 'Buscar por codigo',
        icon = 'search',
        onSelect = function()
          local input = exports['mz_menu']:InputDialog('Buscar imovel', {
            { type = 'input', label = 'Codigo', required = true }
          })

          if input then
            TriggerServerEvent('mz_houses:server:admin:debugInfo', { code = input[1] })
          end
        end
      }
    }
  })
end, false)
