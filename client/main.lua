-- Booth etkileşimi (E tuşu / ox_target) ve NUI panel yönetimi.

local panelOpen = false
local targetZones = {}

local function openBooth(boothId)
    TriggerServerEvent('fd-djkabin:server:tryOpen', boothId)
end

RegisterNetEvent('fd-djkabin:client:notify', function(msg, ntype)
    Bridge.Notify(msg, ntype)
end)

-- Panelde gösterilecek efekt listesi Config.Effects'ten türetilir;
-- sıra Config.EffectOrder ile sabitlenir (dizi olarak gönderilir).
local function buildEffectsConfig()
    local out = {}
    for _, name in ipairs(Config.EffectOrder) do
        local cfg = Config.Effects[name]
        if cfg then
            out[#out + 1] = {
                name = name,
                label = cfg.label,
                colors = cfg.colors,
                hasSpeed = cfg.ui and cfg.ui.speed or false,
                hasColor = cfg.ui and cfg.ui.color or false,
            }
        end
    end
    return out
end

RegisterNetEvent('fd-djkabin:client:openUI', function(booth, playlists)
    panelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        booth = booth,
        playlists = playlists,
        locale = GetLocaleDict(),
        soundboard = Config.Soundboard,
        effectsConfig = buildEffectsConfig(),
        streamerMode = StreamerMode,
    })
end)

RegisterNetEvent('fd-djkabin:client:playlists', function(boothId, playlists)
    SendNUIMessage({ action = 'playlists', boothId = boothId, playlists = playlists })
end)

RegisterNUICallback('close', function(_, cb)
    panelOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('control', function(data, cb)
    if data.boothId and data.action then
        TriggerServerEvent('fd-djkabin:server:control', data.boothId, data.action, data.data or {})
    end
    cb('ok')
end)

-- ox_target entegrasyonu (varsa); yoksa 3D text + E tuşu
local function refreshTargets()
    if not Bridge.HasOxTarget() then return end
    for _, zoneId in ipairs(targetZones) do
        exports.ox_target:removeZone(zoneId)
    end
    targetZones = {}
    for id, booth in pairs(ClientBooths) do
        local zoneId = exports.ox_target:addSphereZone({
            coords = vec3(booth.coords.x, booth.coords.y, booth.coords.z),
            radius = Config.InteractDistance,
            options = {
                {
                    name = 'fd_djkabin_' .. id,
                    icon = 'fa-solid fa-music',
                    label = ('%s - %s'):format(L('open_booth'), booth.label),
                    onSelect = function() openBooth(id) end,
                },
            },
        })
        targetZones[#targetZones + 1] = zoneId
    end
end

AddEventHandler('fd-djkabin:client:boothsRefreshed', refreshTargets)

local function drawText3D(coords, text)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 230)
    SetTextOutline()
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

-- Keypress etkileşim döngüsü (ox_target yoksa)
CreateThread(function()
    while true do
        local sleep = 500
        if not Bridge.HasOxTarget() and not panelOpen then
            local coords = GetEntityCoords(PlayerPedId())
            for id, booth in pairs(ClientBooths) do
                local bpos = vec3(booth.coords.x, booth.coords.y, booth.coords.z)
                local dist = #(coords - bpos)
                if dist <= Config.InteractDistance then
                    sleep = 0
                    drawText3D(vec3(bpos.x, bpos.y, bpos.z + 1.0), ('%s ~c~- %s'):format(L('press_to_open'), booth.label))
                    if IsControlJustReleased(0, Config.InteractKey) then
                        openBooth(id)
                    end
                    break
                elseif dist <= 15.0 then
                    sleep = 250
                end
            end
        end
        Wait(sleep)
    end
end)
