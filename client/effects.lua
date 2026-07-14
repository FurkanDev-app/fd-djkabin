-- Efekt render katmanı: laser, smoke, club lights, confetti, spotlight,
-- strobe, fireworks, fire jets, sky beams, dance floor.
-- Tümü client-side çizilir; durumlar sunucudan booth.settings.effects ile gelir.

local EFFECT_RENDER_DIST = 120.0
local smokeHandles = {}   -- boothId -> { ptfx handle, ... }
local lastBurst = {}      -- boothId..':'..efekt -> son burst zamanı (ms)
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

--- Booth heading'ine göre yerel offseti dünya koordinatına çevirir
local function rotatedOffset(booth, offset)
    local rad = math.rad(booth.heading or 0.0)
    local cosH, sinH = math.cos(rad), math.sin(rad)
    return vec3(
        offset.x * cosH - offset.y * sinH,
        offset.x * sinH + offset.y * cosH,
        offset.z
    )
end

local function effectColor(cfg, eff)
    local colors = cfg.colors
    if not colors then return 255, 255, 255 end
    local c = colors[eff.colorIndex or 1] or colors[1]
    return c[1], c[2], c[3]
end

-- ---- Smoke (looped ptfx durum makinesi) ----

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
        local o = rotatedOffset(booth, offset)
        UseParticleFxAsset(cfg.asset)
        local handle = StartParticleFxLoopedAtCoord(cfg.effect,
            base.x + o.x, base.y + o.y, base.z + o.z,
            0.0, 0.0, booth.heading, cfg.scale, false, false, false, false)
        if handle and handle ~= 0 then handles[#handles + 1] = handle end
    end
    smokeHandles[id] = handles
end

-- ---- Aralıklı ptfx patlamaları (confetti / fireworks / fire jets) ----

--- interval'e (hız çarpanına bölünmüş) göre non-looped ptfx tetikler
local function intervalBurst(id, effectName, booth, eff, points)
    local cfg = Config.Effects[effectName]
    local key = id .. ':' .. effectName
    local now = GetGameTimer()
    local interval = math.floor(cfg.interval / math.max(0.2, eff.speed or 1.0))
    if (lastBurst[key] or 0) + interval > now then return end
    if not requestPtfx(cfg.asset) then return end
    lastBurst[key] = now
    local base = boothVec(booth)
    for _, point in ipairs(points) do
        UseParticleFxAsset(cfg.asset)
        StartParticleFxNonLoopedAtCoord(cfg.effect,
            base.x + point.x, base.y + point.y, base.z + point.z,
            0.0, 0.0, 0.0, cfg.scale, false, false, false)
    end
end

local function fireConfetti(id, booth, eff)
    local cfg = Config.Effects.particles
    intervalBurst(id, 'particles', booth, eff, { cfg.offset })
end

local function fireFireworks(id, booth, eff)
    local cfg = Config.Effects.fireworks
    intervalBurst(id, 'fireworks', booth, eff, {
        vec3((math.random() - 0.5) * 2 * cfg.spread, (math.random() - 0.5) * 2 * cfg.spread, cfg.height),
    })
end

local function fireFlameJets(id, booth, eff)
    local cfg = Config.Effects.firejets
    local points = {}
    for _, offset in ipairs(cfg.offsets) do
        points[#points + 1] = rotatedOffset(booth, offset)
    end
    intervalBurst(id, 'firejets', booth, eff, points)
end

-- ---- Işık efektleri (her frame çizilir) ----

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

local function drawStrobe(booth, eff)
    local cfg = Config.Effects.strobe
    local interval = math.floor(cfg.interval / math.max(0.2, eff.speed or 1.0))
    -- Döngünün ilk yarısında açık, ikinci yarısında kapalı
    if (GetGameTimer() % interval) < interval / 2 then
        local base = boothVec(booth)
        DrawLightWithRange(base.x, base.y, base.z + cfg.height,
            255, 255, 255, cfg.range, cfg.intensity)
    end
end

local function drawSkyBeams(booth, eff)
    local cfg = Config.Effects.skybeams
    local base = boothVec(booth)
    local t = GetGameTimer() / 1000.0 * (eff.speed or cfg.defaultSpeed) * 0.6
    local r, g, b = effectColor(cfg, eff)
    for i = 1, cfg.beamCount do
        local angle = t + (i / cfg.beamCount) * math.pi * 2
        local src = vec3(
            base.x + math.cos(angle) * cfg.radius,
            base.y + math.sin(angle) * cfg.radius,
            base.z + cfg.height
        )
        -- Hafif salınan, gökyüzüne bakan projektör kolonu
        local sway = 0.25 * math.sin(t * 1.4 + i)
        local dir = vec3(math.cos(angle) * sway, math.sin(angle) * sway, 1.0)
        DrawSpotLight(src.x, src.y, src.z, dir.x, dir.y, dir.z,
            r, g, b, 80.0, cfg.brightness, 2.0, 10.0, 1.0)
    end
end

local function drawDanceFloor(booth, eff)
    local cfg = Config.Effects.dancefloor
    local base = boothVec(booth)
    local o = rotatedOffset(booth, cfg.offset)
    local t = GetGameTimer() / 1000.0 * (eff.speed or cfg.defaultSpeed)
    -- Nabız: yarıçap ve parlaklık sinüsle atar
    local pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2)
    local scale = cfg.radius * (0.7 + 0.3 * pulse)
    local r, g, b = effectColor(cfg, eff)
    local alpha = math.floor(120 + 100 * pulse)
    DrawMarker(27, base.x + o.x, base.y + o.y, base.z + o.z - 0.98,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        scale, scale, 1.0,
        r, g, b, alpha, false, false, 2, false, nil, nil, false)
    DrawLightWithRange(base.x + o.x, base.y + o.y, base.z + o.z + 0.5,
        r, g, b, cfg.radius * 1.5, 0.6 + 0.8 * pulse)
end

-- ---- Ana efekt döngüsü ----
-- Yakında aktif efekt varsa her frame çizim yapılır, yoksa uzun bekleme ile
-- CPU kullanımı sıfıra yakın tutulur.
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
                    if effects.strobe and effects.strobe.enabled then
                        drawStrobe(booth, effects.strobe)
                        anyActive = true
                    end
                    if effects.skybeams and effects.skybeams.enabled then
                        drawSkyBeams(booth, effects.skybeams)
                        anyActive = true
                    end
                    if effects.dancefloor and effects.dancefloor.enabled then
                        drawDanceFloor(booth, effects.dancefloor)
                        anyActive = true
                    end
                    if effects.particles and effects.particles.enabled then
                        fireConfetti(id, booth, effects.particles)
                        anyActive = true
                    end
                    if effects.fireworks and effects.fireworks.enabled then
                        fireFireworks(id, booth, effects.fireworks)
                        anyActive = true
                    end
                    if effects.firejets and effects.firejets.enabled then
                        fireFlameJets(id, booth, effects.firejets)
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
