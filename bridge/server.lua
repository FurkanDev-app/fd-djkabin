Bridge = {}
Bridge.Framework = 'standalone'

local QBCore, ESX

CreateThread(function()
    if GetResourceState('qbx_core') == 'started' then
        Bridge.Framework = 'qbox'
    elseif GetResourceState('qb-core') == 'started' then
        Bridge.Framework = 'qbcore'
        QBCore = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        Bridge.Framework = 'esx'
        ESX = exports['es_extended']:getSharedObject()
    end
    print(('[fd-djkabin] Framework: %s'):format(Bridge.Framework))
end)

--- Oyuncunun job bilgisini döndürür: { name = string, grade = number } | nil
function Bridge.GetJob(src)
    if Bridge.Framework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(src)
        if player and player.PlayerData.job then
            return { name = player.PlayerData.job.name, grade = player.PlayerData.job.grade.level or 0 }
        end
    elseif Bridge.Framework == 'qbcore' then
        local player = QBCore and QBCore.Functions.GetPlayer(src)
        if player and player.PlayerData.job then
            return { name = player.PlayerData.job.name, grade = player.PlayerData.job.grade.level or 0 }
        end
    elseif Bridge.Framework == 'esx' then
        local xPlayer = ESX and ESX.GetPlayerFromId(src)
        if xPlayer then
            local job = xPlayer.getJob()
            return { name = job.name, grade = job.grade or 0 }
        end
    end
    return nil
end

--- Kalıcı oyuncu kimliği (playlist sahipliği için)
function Bridge.GetIdentifier(src)
    if Bridge.Framework == 'qbox' then
        local player = exports.qbx_core:GetPlayer(src)
        if player then return player.PlayerData.citizenid end
    elseif Bridge.Framework == 'qbcore' then
        local player = QBCore and QBCore.Functions.GetPlayer(src)
        if player then return player.PlayerData.citizenid end
    elseif Bridge.Framework == 'esx' then
        local xPlayer = ESX and ESX.GetPlayerFromId(src)
        if xPlayer then return xPlayer.getIdentifier() end
    end
    return GetPlayerIdentifierByType(src, 'license') or ('src:%d'):format(src)
end
