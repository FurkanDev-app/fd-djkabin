Config = {}

-- 'tr' veya 'en'
Config.Locale = 'tr'

-- Etkileşim tuşu (E)
Config.InteractKey = 38

-- Booth etkileşim mesafesi (panel açma)
Config.InteractDistance = 2.5

-- ox_target varsa keypress yerine target kullanılsın mı
Config.UseOxTarget = true

-- Ses güncelleme aralığı (ms) - mesafe/volume hesabı
Config.AudioTickRate = 250

-- Senkron sapma toleransı (saniye). Bunun üzerinde sapma varsa client seek ile düzeltir.
Config.DriftTolerance = 2.0

-- Admin yetkisi (ace). Konsoldan: add_ace group.admin fd-djkabin.admin allow
Config.AdminAce = 'fd-djkabin.admin'

-- Varsayılan booth ayarları (yeni booth oluşturulurken kullanılır)
Config.BoothDefaults = {
    volume = 100,          -- 0-100 temel ses
    radius = 50.0,         -- duyulma yarıçapı (metre)
    algorithm = 'linear',  -- 'linear' | 'quadratic' | 'exponential'
    accent = '#e24bd1',    -- panel vurgu rengi
}

-- Config üzerinden gelen sabit booth'lar. Oyun içinden /djbooth create ile
-- eklenenler veritabanına yazılır; buradakiler her başlangıçta senkronlanır.
-- jobs = { ['jobadi'] = minGrade } -> boş bırakılırsa sadece admin kullanabilir.
-- public = true -> herkes kullanabilir (jobs yok sayılır).
Config.Booths = {
    {
        id = 'bahama',
        label = 'Bahama Mamas',
        coords = vec3(-1380.55, -618.62, 30.82),
        heading = 120.0,
        jobs = { ['bahama'] = 0 },
        public = false,
        settings = { volume = 100, radius = 60.0, algorithm = 'quadratic', accent = '#ff7ad9' },
    },
    {
        id = 'vanilla',
        label = 'Vanilla Unicorn',
        coords = vec3(120.98, -1281.12, 29.48),
        heading = 300.0,
        jobs = { ['unicorn'] = 0 },
        public = false,
        settings = { volume = 100, radius = 45.0, algorithm = 'quadratic', accent = '#c04bf0' },
    },
    {
        id = 'beach',
        label = 'Beach Party',
        coords = vec3(-1620.45, -1013.87, 13.12),
        heading = 40.0,
        jobs = {},
        public = true,
        settings = { volume = 100, radius = 90.0, algorithm = 'exponential', accent = '#4bd1e2' },
    },
}

-- Efekt tanımları. Client tarafında booth konumuna göre render edilir.
-- ui = { speed = bool, color = bool } -> panelde hangi ayarlar gösterilir.
-- Panel sırası Config.EffectOrder ile belirlenir.
Config.EffectOrder = { 'laser', 'lights', 'strobe', 'skybeams', 'dancefloor', 'smoke', 'particles', 'fireworks', 'firejets', 'spotlight' }

Config.Effects = {
    laser = {
        label = 'Lasers',
        ui = { speed = true, color = true },
        colors = { { 255, 0, 80 }, { 0, 120, 255 }, { 0, 255, 120 }, { 255, 200, 0 }, { 180, 0, 255 } },
        beamCount = 6,
        defaultSpeed = 1.0,   -- panelden 0.2 - 3.0 arası ayarlanır
        height = 3.0,         -- booth üzerindeki kaynak yüksekliği
        length = 25.0,
    },
    smoke = {
        label = 'Smoke',
        ui = {},
        asset = 'scr_ba_club',
        effect = 'scr_ba_club_smoke_machine',
        offsets = { vec3(-2.0, 0.0, 0.0), vec3(2.0, 0.0, 0.0) },
        scale = 1.5,
    },
    lights = {
        label = 'Club Lights',
        ui = { speed = true },
        colors = { { 255, 0, 80 }, { 0, 120, 255 }, { 0, 255, 120 }, { 255, 120, 0 } },
        defaultSpeed = 1.0,
        height = 6.0,
        radius = 18.0,
    },
    particles = {
        label = 'Confetti',
        ui = { speed = true },
        asset = 'scr_ba_club',
        effect = 'scr_ba_club_confetti_burst',
        interval = 4000, -- ms (hız çarpanıyla bölünür)
        offset = vec3(0.0, 0.0, 4.0),
        scale = 2.0,
    },
    spotlight = {
        label = 'Spot Light',
        ui = {},
        height = 8.0,
        color = { 255, 255, 255 },
        intensity = 8.0,
    },
    strobe = {
        label = 'Strobe',
        ui = { speed = true },
        height = 4.0,
        range = 25.0,
        intensity = 3.0,
        interval = 120, -- ms (bir aç+kapa döngüsü; hız çarpanıyla bölünür)
    },
    fireworks = {
        label = 'Fireworks',
        ui = { speed = true },
        asset = 'scr_indep_fireworks',
        effect = 'scr_indep_firework_starburst',
        interval = 5000, -- ms
        height = 20.0,
        spread = 10.0,   -- patlama noktası yatay rastgelelik
        scale = 1.5,
    },
    firejets = {
        label = 'Fire Jets',
        ui = { speed = true },
        asset = 'scr_indep_fireworks',
        effect = 'scr_indep_firework_fountain',
        interval = 3000, -- ms
        offsets = { vec3(-3.0, 1.5, 0.0), vec3(3.0, 1.5, 0.0) },
        scale = 1.2,
    },
    skybeams = {
        label = 'Sky Beams',
        ui = { speed = true, color = true },
        colors = { { 255, 255, 255 }, { 255, 0, 80 }, { 0, 120, 255 }, { 0, 255, 120 }, { 180, 0, 255 } },
        beamCount = 4,
        defaultSpeed = 1.0,
        height = 5.0,
        radius = 14.0,   -- kolonların booth çevresindeki dağılım yarıçapı
        brightness = 10.0,
    },
    dancefloor = {
        label = 'Dance Floor',
        ui = { speed = true, color = true },
        colors = { { 226, 75, 209 }, { 0, 120, 255 }, { 0, 255, 120 }, { 255, 200, 0 }, { 255, 0, 80 } },
        offset = vec3(0.0, 3.5, 0.0), -- booth önü (heading'e göre döndürülür)
        radius = 5.0,
        defaultSpeed = 1.0,
    },
}

-- Soundboard - url olarak dış link ya da NUI içi dosya kullanılabilir.
-- Kendi ses dosyalarını web/public/sfx/ altına koyup 'sfx/dosya.mp3' yazabilirsin.
-- icon: Google Material Symbols ikon adı (https://fonts.google.com/icons)
Config.Soundboard = {
    { id = 'airhorn',  label = 'Air Horn',   icon = 'campaign',              url = 'https://www.myinstants.com/media/sounds/dj-airhorn-sound-effect-kingbeatz_1.mp3' },
    { id = 'applause', label = 'Applause',   icon = 'celebration',           url = 'https://www.myinstants.com/media/sounds/applause-2.mp3' },
    { id = 'siren',    label = 'Siren',      icon = 'e911_emergency',        url = 'https://www.myinstants.com/media/sounds/air-raid-siren.mp3' },
    { id = 'drop',     label = 'Drop',       icon = 'graphic_eq',            url = 'https://www.myinstants.com/media/sounds/bass-drop.mp3' },
    { id = 'rewind',   label = 'Rewind',     icon = 'fast_rewind',           url = 'https://www.myinstants.com/media/sounds/dj-rewind.mp3' },
    { id = 'letsgo',   label = "Let's Go!",  icon = 'local_fire_department', url = 'https://www.myinstants.com/media/sounds/lets-go_mMundI4.mp3' },
}

-- Ses yayılım algoritmaları (client'ta kullanılır)
-- d: mesafe, r: yarıçap -> 0.0-1.0 çarpan
Config.Attenuation = {
    linear = function(d, r) return 1.0 - (d / r) end,
    quadratic = function(d, r) local x = 1.0 - (d / r) return x * x end,
    exponential = function(d, r) local x = 1.0 - (d / r) return x * x * x * x end,
}
