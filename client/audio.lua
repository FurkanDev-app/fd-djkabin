-- Ses motoru köprüsü: booth state'lerini tutar, mesafeye göre volume hesaplar
-- ve NUI'daki player'ları (YouTube IFrame / HTML5 Audio) sürer.

ClientBooths = {}

-- Menzil dışına bu kadar taşma payı bırakılır; ötesinde player yok edilir
local DESTROY_BUFFER = 1.25

local function stateReceived(booth)
    booth.receivedAt = GetGameTimer()
    return booth
end

--- Şarkının şu anda olması gereken pozisyonu (yerel ekstrapolasyon)
function GetExpectedPosition(booth)
    local st = booth.state
    if not st.track then return 0.0 end
    if st.playing then
        return st.position + (GetGameTimer() - booth.receivedAt) / 1000.0
    end
    return st.position
end

RegisterNetEvent('fd-djkabin:client:fullSync', function(booths)
    local fresh = {}
    for _, booth in ipairs(booths) do
        fresh[booth.id] = stateReceived(booth)
    end
    ClientBooths = fresh
    TriggerEvent('fd-djkabin:client:boothsRefreshed')
end)

RegisterNetEvent('fd-djkabin:client:boothState', function(booth)
    local isNew = ClientBooths[booth.id] == nil
    ClientBooths[booth.id] = stateReceived(booth)
    if isNew then TriggerEvent('fd-djkabin:client:boothsRefreshed') end
    SendNUIMessage({ action = 'boothState', booth = booth })
end)

RegisterNetEvent('fd-djkabin:client:boothRemoved', function(boothId)
    ClientBooths[boothId] = nil
    SendNUIMessage({ action = 'destroyPlayer', boothId = boothId })
    TriggerEvent('fd-djkabin:client:boothsRefreshed')
end)

RegisterNetEvent('fd-djkabin:client:soundboard', function(boothId, url)
    local booth = ClientBooths[boothId]
    if not booth or StreamerMode then return end
    local coords = GetEntityCoords(PlayerPedId())
    local dist = #(coords - vec3(booth.coords.x, booth.coords.y, booth.coords.z))
    local radius = booth.settings.radius + 0.0
    if dist > radius then return end
    local atten = Config.Attenuation[booth.settings.algorithm] or Config.Attenuation.linear
    local vol = math.max(0.0, math.min(1.0, atten(dist, radius))) * (booth.settings.volume / 100.0)
    SendNUIMessage({ action = 'sfx', url = url, volume = vol })
end)

-- Ana ses döngüsü: her tick aktif booth'lar için NUI player'ı senkronlar
CreateThread(function()
    while true do
        Wait(Config.AudioTickRate)
        local coords = GetEntityCoords(PlayerPedId())
        for id, booth in pairs(ClientBooths) do
            local st = booth.state
            if st.track then
                local dist = #(coords - vec3(booth.coords.x, booth.coords.y, booth.coords.z))
                local radius = booth.settings.radius + 0.0
                if dist <= radius * DESTROY_BUFFER then
                    local vol = 0.0
                    if dist <= radius and not StreamerMode then
                        local atten = Config.Attenuation[booth.settings.algorithm] or Config.Attenuation.linear
                        vol = math.max(0.0, math.min(1.0, atten(dist, radius))) * (booth.settings.volume / 100.0)
                    end
                    SendNUIMessage({
                        action = 'audioSync',
                        boothId = id,
                        playId = st.playId,
                        track = st.track,
                        playing = st.playing,
                        position = GetExpectedPosition(booth),
                        volume = vol,
                        drift = Config.DriftTolerance,
                    })
                else
                    SendNUIMessage({ action = 'destroyPlayer', boothId = id })
                end
            else
                SendNUIMessage({ action = 'destroyPlayer', boothId = id })
            end
        end
    end
end)

-- NUI: player metadata raporu (başlık/sanatçı/süre)
RegisterNUICallback('reportMeta', function(data, cb)
    if data.boothId and data.playId then
        TriggerServerEvent('fd-djkabin:server:reportMeta', data.boothId, data.playId, {
            title = data.title, artist = data.artist, duration = tonumber(data.duration),
        })
    end
    cb('ok')
end)

-- NUI: şarkı bitti (YT ENDED eventi) - yedek otomatik geçiş tetiği
RegisterNUICallback('trackEnded', function(data, cb)
    if data.boothId and data.playId then
        TriggerServerEvent('fd-djkabin:server:reportEnded', data.boothId, data.playId)
    end
    cb('ok')
end)

-- Spawn/reconnect sonrası tam senkron iste
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('fd-djkabin:server:requestSync')
end)

CreateThread(function()
    Wait(2000)
    TriggerServerEvent('fd-djkabin:server:requestSync')
end)
