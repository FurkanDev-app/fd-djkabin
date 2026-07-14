-- Admin komutları: /djbooth create <isim> | delete <id> | move <id> | list
-- Yetki kontrolü sunucu tarafında yapılır (fd-djkabin.admin ace).

RegisterCommand('djbooth', function(_, args)
    local op = args[1] and args[1]:lower() or nil

    if op == 'create' then
        local label = table.concat(args, ' ', 2)
        if label == '' then
            Bridge.Notify(L('usage_djbooth'), 'error')
            return
        end
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        TriggerServerEvent('fd-djkabin:server:adminBooth', 'create', {
            label = label,
            coords = { x = coords.x, y = coords.y, z = coords.z },
            heading = GetEntityHeading(ped),
        })

    elseif op == 'delete' and args[2] then
        TriggerServerEvent('fd-djkabin:server:adminBooth', 'delete', { id = args[2] })

    elseif op == 'move' and args[2] then
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        TriggerServerEvent('fd-djkabin:server:adminBooth', 'move', {
            id = args[2],
            coords = { x = coords.x, y = coords.y, z = coords.z },
            heading = GetEntityHeading(ped),
        })

    elseif op == 'list' then
        TriggerServerEvent('fd-djkabin:server:adminBooth', 'list', {})

    else
        Bridge.Notify(L('usage_djbooth'), 'inform')
    end
end, false)

TriggerEvent('chat:addSuggestion', '/djbooth', 'DJ kabini yonetimi (admin)', {
    { name = 'islem', help = 'create <isim> | delete <id> | move <id> | list' },
})
TriggerEvent('chat:addSuggestion', '/streamermode', 'Streamer modunu ac/kapat (muzik sustur, efektler kalsin)')
