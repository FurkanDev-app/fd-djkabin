local loaded = {}

local function loadLocale(lang)
    if loaded[lang] then return loaded[lang] end
    local raw = LoadResourceFile(GetCurrentResourceName(), ('locales/%s.json'):format(lang))
    if not raw then return nil end
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then return nil end
    loaded[lang] = data
    return data
end

--- Locale metni döndürür. Bulunamazsa İngilizce'ye, o da yoksa anahtarın kendisine düşer.
---@param key string
---@param ... any format argümanları
function L(key, ...)
    local dict = loadLocale(Config.Locale) or {}
    local fallback = loadLocale('en') or {}
    local str = dict[key] or fallback[key] or key
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, str, ...)
        if ok then return formatted end
    end
    return str
end

--- NUI'a gönderilecek tüm locale sözlüğü
function GetLocaleDict()
    return loadLocale(Config.Locale) or loadLocale('en') or {}
end
