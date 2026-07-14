-- Efekt render katmanı: laser, smoke, club lights, particles, spotlight.
-- Tümü client-side çizilir; durumlar sunucudan booth.settings.effects ile gelir.

local EFFECT_RENDER_DIST = 120.0
local smokeHandles = {}   -- boothId -> { ptfx handle, ... }
local lastParticle = {}   -- boothId -> son burst zamanı
local assetRequested = {}

local function requestPtfx(asset)
    if assetRequested[asset] then return HasNamedPtfxAssetLoaded(asset) end
    assetRequested[asset] = true
    RequestNamedPtfxAsset(asset)
    return HasNamedPtfxAssetLoaded(asset)
end

local function boothVec(booth)
    return vec3(booth.coords.x, booth.coords.y, booth.coords.z)
end

local function stopSmoke(id)
    if smokeHandles[id] then
        for _, handle in ipairs(smokeHandles[id]) do
            StopParticleFxLooped(handle, false)
        end
        smokeHandles[id] = nil
    end
end

local function startSmoke(id, booth)
    if smokeHandles[id] then return end
    local cfg = Config.Effects.smoke
    if not requestPtfx(cfg.asset) then return end
    local base = boothVec(booth)
    local handles = {}
    for _, offset in ipairs(cfg.offsets) do
        UseParticleFxAsset(cfg.asset)
        local handle = StartParticleFxLoopedAtCoord(cfg.effect,
            base.x + offset.x, base.y + offset.y, base.z + offset.z,
            0.0, 0.0, booth.heading, cfg.scale, false, false, false, false)
        if handle and handle ~= 0 then handles[#handles + 1] = handle end
    end
    smokeHandles[id] = handles
end

local function fireParticleBurst(id, booth)
    local cfg = Config.Effects.particles
    local now = GetGameTimer()
    if (lastParticle[id] or 0) + cfg.interval > now then return end
    if not requestPtfx(cfg.asset) then return end
    lastParticle[id] = now
    local base = boothVec(booth)
    UseParticleFxAsset(cfg.asset)
    StartParticleFxNonLoopedAtCoord(cfg.effect,
        base.x + cfg.offset.x, base.y + cfg.offset.y, base.z + cfg.offset.z,
        0.0, 0.0, 0.0, cfg.scale, false, false, false)
end

local function drawLasers(booth, eff)
    local cfg = Config.Effects.laser
    local base = boothVec(booth)
    local src = vec3(base.x, base.y, base.z + cfg.height)
    local t = GetGameTimer() / 1000.0 * (eff.speed or cfg.defaultSpeed)
    local colors = cfg.colors
    for i = 1, cfg.beamCount do
        local angle = t + (i / cfg.beamCount) * math.pi * 2
        local pitch = 0.35 + 0.25 * math.sin(t * 1.7 + i)
        local dir = vec3(math.cos(angle) * math.cos(pitch), math.sin(angle) * math.cos(pitch), -math.sin(pitch))
        local target = src + dir * cfg.length
        local c = colors[((i - 1) % #colors) + 1]
        DrawLine(src.x, src.y, src.z, target.x, target.y, target.z, c[1], c[2], c[3], 220)
    end
end

local function drawClubLights(booth, eff)
    local cfg = Config.Effects.lights
    local base = boothVec(booth)
    local src = vec3(base.x, base.y, base.z + cfg.height)
    local t = GetGameTimer() / 1000.0 * (eff.speed or cfg.defaultSpeed)
    local colors = cfg.colors
    for i = 1, 3 do
        local angle = t * 1.3 + (i / 3) * math.pi * 2
        local dir = vec3(math.cos(angle) * 0.6, math.sin(angle) * 0.6, -0.8)
        local cIndex = (math.floor(t + i) % #colors) + 1
        local c = colors[cIndex]
        DrawSpotLightWithShadow(src.x, src.y, src.z, dir.x, dir.y, dir.z,
            c[1], c[2], c[3], cfg.radius, 6.0, 1.0, 18.0, 1.0, i)
    end
end

local function drawSpotlight(booth)
    local cfg = Config.Effects.spotlight
    local base = boothVec(booth)
    DrawSpotLight(base.x, base.y, base.z + cfg.height, 0.0, 0.0, -1.0,
        cfg.color[1], cfg.color[2], cfg.color[3], 20.0, cfg.intensity, 4.0, 14.0, 1.0)
end

-- Ana efekt döngüsü: yakında aktif efekt varsa her frame çizim yapılır,
-- yoksa uzun bekleme ile CPU kullanımı sıfıra yakın tutulur.
CreateThread(function()
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        local anyActive = false

        for id, booth in pairs(ClientBooths) do
            local effects = booth.settings and booth.settings.effects
            if effects then
                local dist = #(coords - boothVec(booth))
                local inRange = dist <= EFFECT_RENDER_DIST

                -- Smoke: durum makinesi (looped ptfx başlat/durdur)
                if effects.smoke and effects.smoke.enabled and inRange then
                    startSmoke(id, booth)
                else
                    stopSmoke(id)
                end

                if inRange then
                    if effects.laser and effects.laser.enabled then
                        drawLasers(booth, effects.laser)
                        anyActive = true
                    end
                    if effects.lights and effects.lights.enabled then
                        drawClubLights(booth, effects.lights)
                        anyActive = true
                    end
                    if effects.spotlight and effects.spotlight.enabled then
                        drawSpotlight(booth)
                        anyActive = true
                    end
                    if effects.particles and effects.particles.enabled then
                        fireParticleBurst(id, booth)
                        anyActive = true
                    end
                    if effects.smoke and effects.smoke.enabled then
                        anyActive = true
                    end
                end
            end
        end

        Wait(anyActive and 0 or 750)
    end
end)

-- Booth silindiğinde/listesi yenilendiğinde artık var olmayanların smoke'unu kapat
AddEventHandler('fd-djkabin:client:boothsRefreshed', function()
    for id in pairs(smokeHandles) do
        if not ClientBooths[id] then stopSmoke(id) end
    end
end)
