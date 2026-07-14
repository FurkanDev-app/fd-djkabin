-- Booth yöneticisi: yükleme, oluşturma, silme, ayar kalıcılığı.
-- Booths[id] = {
--   id, label, coords, heading, jobs, public, fromConfig,
--   settings = { volume, radius, algorithm, accent, effects = { laser={...}, ... } },
--   state = { track, playing, startedAt(ms), position(s), repeatMode, shuffle, queue = {} },
-- }
Booths = {}

local function defaultEffects()
    return {
        laser     = { enabled = false, speed = 1.0, colorIndex = 1 },
        smoke     = { enabled = false },
        lights    = { enabled = false, speed = 1.0 },
        particles = { enabled = false },
        spotlight = { enabled = false },
    }
end

local function defaultSettings(overrides)
    local s = {
        volume = Config.BoothDefaults.volume,
        radius = Config.BoothDefaults.radius,
        algorithm = Config.BoothDefaults.algorithm,
        accent = Config.BoothDefaults.accent,
        effects = defaultEffects(),
    }
    for k, v in pairs(overrides or {}) do
        if k ~= 'effects' then s[k] = v end
    end
    return s
end

local function defaultState()
    return {
        track = nil,
        playing = false,
        startedAt = 0,
        position = 0.0,
        repeatMode = false,
        shuffle = false,
        queue = {},
        playId = 0,
    }
end

local function registerBooth(data)
    Booths[data.id] = {
        id = data.id,
        label = data.label,
        coords = data.coords,
        heading = data.heading or 0.0,
        jobs = data.jobs or {},
        public = data.public or false,
        fromConfig = data.fromConfig or false,
        settings = data.settings,
        state = defaultState(),
    }
    return Booths[data.id]
end

--- Booth ayarlarını DB'ye yazar (debounce yok; ayar değişimleri seyrek)
function SaveBoothSettings(booth)
    MySQL.update('UPDATE fd_djkabin_booths SET settings = ? WHERE id = ?', {
        json.encode(booth.settings), booth.id,
    })
end

--- Yeni booth oluşturur (admin komutu) ve DB'ye yazar
function CreateBooth(id, label, coords, heading)
    if Booths[id] then return nil, 'exists' end
    local booth = registerBooth({
        id = id, label = label, coords = coords, heading = heading,
        jobs = {}, public = false, fromConfig = false,
        settings = defaultSettings(),
    })
    MySQL.insert('INSERT INTO fd_djkabin_booths (id, label, x, y, z, heading, settings, jobs, public, from_config) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        id, label, coords.x, coords.y, coords.z, heading,
        json.encode(booth.settings), json.encode(booth.jobs), booth.public and 1 or 0, 0,
    })
    return booth
end

function DeleteBooth(id)
    local booth = Booths[id]
    if not booth then return false end
    Booths[id] = nil
    MySQL.update('DELETE FROM fd_djkabin_booths WHERE id = ?', { id })
    MySQL.update('DELETE FROM fd_djkabin_playlists WHERE booth_id = ?', { id })
    return true
end

function MoveBooth(id, coords, heading)
    local booth = Booths[id]
    if not booth then return false end
    booth.coords = coords
    booth.heading = heading
    MySQL.update('UPDATE fd_djkabin_booths SET x = ?, y = ?, z = ?, heading = ? WHERE id = ?', {
        coords.x, coords.y, coords.z, heading, id,
    })
    return true
end

--- Client'a gönderilecek tekil booth verisi
function SerializeBooth(booth)
    local pos = GetBoothPosition(booth)
    return {
        id = booth.id,
        label = booth.label,
        coords = { x = booth.coords.x, y = booth.coords.y, z = booth.coords.z },
        heading = booth.heading,
        settings = booth.settings,
        state = {
            track = booth.state.track,
            playing = booth.state.playing,
            position = pos,
            repeatMode = booth.state.repeatMode,
            shuffle = booth.state.shuffle,
            queue = booth.state.queue,
            playId = booth.state.playId,
        },
    }
end

function SerializeAllBooths()
    local out = {}
    for _, booth in pairs(Booths) do
        out[#out + 1] = SerializeBooth(booth)
    end
    return out
end

--- Şarkının şu anki pozisyonu (saniye)
function GetBoothPosition(booth)
    if booth.state.playing then
        return (GetGameTimer() - booth.state.startedAt) / 1000.0
    end
    return booth.state.position
end

-- Başlangıçta DB + config booth'larını yükle
CreateThread(function()
    -- Tablolar yoksa oluştur (sql/install.sql çalıştırılmamışsa da script çalışsın)
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `fd_djkabin_booths` (
        `id` VARCHAR(50) NOT NULL, `label` VARCHAR(100) NOT NULL,
        `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL,
        `heading` FLOAT NOT NULL DEFAULT 0.0,
        `settings` LONGTEXT NULL, `jobs` LONGTEXT NULL,
        `public` TINYINT(1) NOT NULL DEFAULT 0,
        `from_config` TINYINT(1) NOT NULL DEFAULT 0,
        PRIMARY KEY (`id`))]])
    MySQL.query.await([[CREATE TABLE IF NOT EXISTS `fd_djkabin_playlists` (
        `id` INT NOT NULL AUTO_INCREMENT, `booth_id` VARCHAR(50) NULL,
        `owner` VARCHAR(80) NULL, `name` VARCHAR(100) NOT NULL,
        `tracks` LONGTEXT NOT NULL, PRIMARY KEY (`id`), KEY `booth_id` (`booth_id`))]])

    local rows = MySQL.query.await('SELECT * FROM fd_djkabin_booths') or {}
    local dbById = {}
    for _, row in ipairs(rows) do dbById[row.id] = row end

    -- Config booth'ları: konum/yetki config'ten, ayarlar (varsa) DB'den gelir
    for _, cfg in ipairs(Config.Booths) do
        local row = dbById[cfg.id]
        local settings = defaultSettings(cfg.settings)
        if row and row.settings then
            local ok, saved = pcall(json.decode, row.settings)
            if ok and type(saved) == 'table' then
                for k, v in pairs(saved) do settings[k] = v end
                settings.effects = settings.effects or defaultEffects()
                -- runtime'a taşınmaması gereken bir alan yok; efekt enabled durumları restart'ta kapatılır
                for _, eff in pairs(settings.effects) do eff.enabled = false end
            end
        end
        registerBooth({
            id = cfg.id, label = cfg.label, coords = cfg.coords, heading = cfg.heading,
            jobs = cfg.jobs, public = cfg.public, fromConfig = true, settings = settings,
        })
        if row then
            MySQL.update('UPDATE fd_djkabin_booths SET label = ?, x = ?, y = ?, z = ?, heading = ?, jobs = ?, public = ?, from_config = 1 WHERE id = ?', {
                cfg.label, cfg.coords.x, cfg.coords.y, cfg.coords.z, cfg.heading,
                json.encode(cfg.jobs or {}), cfg.public and 1 or 0, cfg.id,
            })
        else
            MySQL.insert('INSERT INTO fd_djkabin_booths (id, label, x, y, z, heading, settings, jobs, public, from_config) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)', {
                cfg.id, cfg.label, cfg.coords.x, cfg.coords.y, cfg.coords.z, cfg.heading,
                json.encode(settings), json.encode(cfg.jobs or {}), cfg.public and 1 or 0,
            })
        end
    end

    -- Oyun içinden oluşturulmuş (config'te olmayan) booth'lar
    for id, row in pairs(dbById) do
        if not Booths[id] then
            local settings = defaultSettings()
            if row.settings then
                local ok, saved = pcall(json.decode, row.settings)
                if ok and type(saved) == 'table' then
                    for k, v in pairs(saved) do settings[k] = v end
                    settings.effects = settings.effects or defaultEffects()
                    for _, eff in pairs(settings.effects) do eff.enabled = false end
                end
            end
            local jobs = {}
            if row.jobs then
                local ok, saved = pcall(json.decode, row.jobs)
                if ok and type(saved) == 'table' then jobs = saved end
            end
            registerBooth({
                id = id, label = row.label,
                coords = vec3(row.x, row.y, row.z), heading = row.heading,
                jobs = jobs, public = row.public == 1, fromConfig = false, settings = settings,
            })
        end
    end

    BoothsLoaded = true
    print(('[fd-djkabin] %d booth loaded'):format(#SerializeAllBooths()))
    TriggerClientEvent('fd-djkabin:client:fullSync', -1, SerializeAllBooths())
end)
