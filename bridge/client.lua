Bridge = {}

--- ox_target kullanılabilir mi
function Bridge.HasOxTarget()
    return Config.UseOxTarget and GetResourceState('ox_target') == 'started'
end

--- Basit bildirim (framework'e göre düşer, yoksa chat)
function Bridge.Notify(msg, ntype)
    ntype = ntype or 'inform'
    if GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({ description = msg, type = ntype == 'inform' and 'inform' or ntype })
    elseif GetResourceState('qb-core') == 'started' then
        TriggerEvent('QBCore:Notify', msg, ntype == 'inform' and 'primary' or ntype)
    elseif GetResourceState('es_extended') == 'started' then
        TriggerEvent('esx:showNotification', msg)
    else
        TriggerEvent('chat:addMessage', { args = { '^5[DJ]^7', msg } })
    end
end
