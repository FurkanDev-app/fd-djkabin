-- Ana event katmanı: senkron, kontrol aksiyonları, metadata raporları.

function BroadcastBooth(booth)
    TriggerClientEvent('fd-djkabin:client:boothState', -1, SerializeBooth(booth))
end

-- Geç katılan / reconnect olan oyuncular tam state ister
RegisterNetEvent('fd-djkabin:server:requestSync', function()
    local src = source
    if not BoothsLoaded then return end
    TriggerClientEvent('fd-djkabin:client:fullSync', src, SerializeAllBooths())
end)

-- Panel açma isteği: yetki kontrolü + playlistlerle birlikte cevap
RegisterNetEvent('fd-djkabin:server:tryOpen', function(boothId)
    local src = source
    local booth = Booths[boothId]
    if not booth then return end
    local player = GetPlayerPed(src)
    if #(GetEntityCoords(player) - booth.coords) > Config.InteractDistance + 5.0 then return end
    if not CanControlBooth(src, booth) then
        TriggerClientEvent('fd-djkabin:client:notify', src, L('no_permission'), 'error')
        return
    end
    TriggerClientEvent('fd-djkabin:client:openUI', src, SerializeBooth(booth), GetPlaylists(boothId))
end)

-- Şarkı metadata raporu (NUI player yüklenince ilk client gönderir)
RegisterNetEvent('fd-djkabin:server:reportMeta', function(boothId, playId, meta)
    local booth = Booths[boothId]
    if not booth or booth.state.playId ~= playId or not booth.state.track then return end
    local track = booth.state.track
    local changed = false
    if type(meta.duration) == 'number' and meta.duration > 0 and (track.duration or 0) == 0 then
        track.duration = meta.duration
        changed = true
    end
    if type(meta.title) == 'string' and meta.title ~= '' and track.title == track.url then
        track.title = meta.title:sub(1, 150)
        changed = true
    end
    if type(meta.artist) == 'string' and meta.artist ~= '' and (track.artist or '') == '' then
        track.artist = meta.artist:sub(1, 100)
        changed = true
    end
    if changed then BroadcastBooth(booth) end
end)

-- Client "şarkı bitti" raporu (YT player ENDED) - süre raporu gelmemişse yedek tetik
RegisterNetEvent('fd-djkabin:server:reportEnded', function(boothId, playId)
    local booth = Booths[boothId]
    if not booth or booth.state.playId ~= playId or not booth.state.playing then return end
    if GetBoothPosition(booth) < 5.0 then return end
    AdvanceQueue(booth)
end)

-- Tüm DJ kontrol aksiyonları tek event üzerinden, sunucu tarafı yetki kontrolüyle
RegisterNetEvent('fd-djkabin:server:control', function(boothId, action, data)
    local src = source
    local booth = Booths[boothId]
    if not booth or not CanControlBooth(src, booth) then return end
    data = type(data) == 'table' and data or {}
    local st = booth.state

    if action == 'play' then
        local track = BuildTrack(data.url)
        if not track then
            TriggerClientEvent('fd-djkabin:client:notify', src, L('invalid_url'), 'error')
            return
        end
        PlayTrack(booth, track, 0.0)

    elseif action == 'playTrack' then
        -- Playlist/queue'dan hazır track objesi (sunucu yeniden doğrular)
        local track = BuildTrack(type(data.track) == 'table' and data.track.url or nil)
        if not track then return end
        if type(data.track.title) == 'string' then track.title = data.track.title:sub(1, 150) end
        if type(data.track.artist) == 'string' then track.artist = data.track.artist:sub(1, 100) end
        if type(data.track.duration) == 'number' then track.duration = data.track.duration end
        PlayTrack(booth, track, 0.0)

    elseif action == 'pause' then
        if st.playing then
            st.position = GetBoothPosition(booth)
            st.playing = false
            BroadcastBooth(booth)
        end

    elseif action == 'resume' then
        if not st.playing and st.track then
            st.startedAt = GetGameTimer() - math.floor(st.position * 1000)
            st.playing = true
            BroadcastBooth(booth)
        end

    elseif action == 'stop' then
        StopBooth(booth)

    elseif action == 'seek' then
        if st.track and type(data.position) == 'number' and data.position >= 0 then
            local pos = data.position
            if (st.track.duration or 0) > 0 then pos = math.min(pos, st.track.duration) end
            if st.playing then
                st.startedAt = GetGameTimer() - math.floor(pos * 1000)
            else
                st.position = pos
            end
            BroadcastBooth(booth)
        end

    elseif action == 'skip' then
        AdvanceQueue(booth)

    elseif action == 'repeat' then
        st.repeatMode = not st.repeatMode
        BroadcastBooth(booth)

    elseif action == 'shuffle' then
        st.shuffle = not st.shuffle
        BroadcastBooth(booth)

    elseif action == 'volume' then
        local v = tonumber(data.value)
        if v then
            booth.settings.volume = math.max(0, math.min(100, math.floor(v)))
            SaveBoothSettings(booth)
            BroadcastBooth(booth)
        end

    elseif action == 'radius' then
        local v = tonumber(data.value)
        if v then
            booth.settings.radius = math.max(5.0, math.min(300.0, v))
            SaveBoothSettings(booth)
            BroadcastBooth(booth)
        end

    elseif action == 'algorithm' then
        if Config.Attenuation[data.value] then
            booth.settings.algorithm = data.value
            SaveBoothSettings(booth)
            BroadcastBooth(booth)
        end

    elseif action == 'queueAdd' then
        local track = BuildTrack(data.url)
        if not track then
            TriggerClientEvent('fd-djkabin:client:notify', src, L('invalid_url'), 'error')
            return
        end
        QueueAdd(booth, track)

    elseif action == 'queueRemove' then
        local index = tonumber(data.index)
        if index and st.queue[index] then
            table.remove(st.queue, index)
            BroadcastBooth(booth)
        end

    elseif action == 'queueClear' then
        st.queue = {}
        BroadcastBooth(booth)

    elseif action == 'effect' then
        local eff = booth.settings.effects[data.name]
        local cfg = Config.Effects[data.name]
        if eff and cfg then
            if data.enabled ~= nil then eff.enabled = data.enabled == true end
            if type(data.speed) == 'number' then eff.speed = math.max(0.2, math.min(3.0, data.speed)) end
            if type(data.colorIndex) == 'number' and cfg.colors and cfg.colors[math.floor(data.colorIndex)] then
                eff.colorIndex = math.floor(data.colorIndex)
            end
            SaveBoothSettings(booth)
            BroadcastBooth(booth)
        end

    elseif action == 'soundboard' then
        for _, sfx in ipairs(Config.Soundboard) do
            if sfx.id == data.id then
                TriggerClientEvent('fd-djkabin:client:soundboard', -1, boothId, sfx.url)
                break
            end
        end

    elseif action == 'playlistCreate' then
        CreatePlaylist(src, boothId, data.name)
        TriggerClientEvent('fd-djkabin:client:playlists', src, boothId, GetPlaylists(boothId))

    elseif action == 'playlistDelete' then
        DeletePlaylist(boothId, tonumber(data.id))
        TriggerClientEvent('fd-djkabin:client:playlists', src, boothId, GetPlaylists(boothId))

    elseif action == 'playlistAddTrack' then
        local track
        if type(data.track) == 'table' then
            track = BuildTrack(data.track.url)
            if track then
                if type(data.track.title) == 'string' then track.title = data.track.title:sub(1, 150) end
                if type(data.track.artist) == 'string' then track.artist = data.track.artist:sub(1, 100) end
                if type(data.track.duration) == 'number' then track.duration = data.track.duration end
            end
        else
            track = BuildTrack(data.url)
        end
        if not track then
            TriggerClientEvent('fd-djkabin:client:notify', src, L('invalid_url'), 'error')
            return
        end
        PlaylistAddTrack(boothId, tonumber(data.id), track)
        TriggerClientEvent('fd-djkabin:client:playlists', src, boothId, GetPlaylists(boothId))

    elseif action == 'playlistRemoveTrack' then
        PlaylistRemoveTrack(boothId, tonumber(data.id), tonumber(data.index))
        TriggerClientEvent('fd-djkabin:client:playlists', src, boothId, GetPlaylists(boothId))

    elseif action == 'playlistLoad' then
        local tracks = GetPlaylistTracks(boothId, tonumber(data.id))
        if tracks then
            for _, track in ipairs(tracks) do
                st.queue[#st.queue + 1] = track
            end
            if not st.track then
                AdvanceQueue(booth)
            else
                BroadcastBooth(booth)
            end
        end
    end
end)

-- Admin: booth oluştur/sil/taşı (client/admin.lua'dan çağrılır)
RegisterNetEvent('fd-djkabin:server:adminBooth', function(op, data)
    local src = source
    if not IsAdmin(src) then
        TriggerClientEvent('fd-djkabin:client:notify', src, L('not_admin'), 'error')
        return
    end
    data = type(data) == 'table' and data or {}

    if op == 'create' then
        local label = tostring(data.label or 'DJ Booth'):sub(1, 100)
        local id = label:lower():gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', '')
        if id == '' then id = 'booth' end
        local base, n = id, 1
        while Booths[id] do
            n = n + 1
            id = ('%s_%d'):format(base, n)
        end
        local coords = vec3(data.coords.x, data.coords.y, data.coords.z)
        local booth = CreateBooth(id, label, coords, data.heading or 0.0)
        if booth then
            TriggerClientEvent('fd-djkabin:client:boothState', -1, SerializeBooth(booth))
            TriggerClientEvent('fd-djkabin:client:notify', src, L('booth_created', ('%s (%s)'):format(label, id)), 'success')
        end

    elseif op == 'delete' then
        local id = tostring(data.id or '')
        if not Booths[id] then
            TriggerClientEvent('fd-djkabin:client:notify', src, L('booth_not_found', id), 'error')
            return
        end
        DeleteBooth(id)
        TriggerClientEvent('fd-djkabin:client:boothRemoved', -1, id)
        TriggerClientEvent('fd-djkabin:client:notify', src, L('booth_deleted', id), 'success')

    elseif op == 'move' then
        local id = tostring(data.id or '')
        if not Booths[id] then
            TriggerClientEvent('fd-djkabin:client:notify', src, L('booth_not_found', id), 'error')
            return
        end
        MoveBooth(id, vec3(data.coords.x, data.coords.y, data.coords.z), data.heading or 0.0)
        TriggerClientEvent('fd-djkabin:client:boothState', -1, SerializeBooth(Booths[id]))
        TriggerClientEvent('fd-djkabin:client:notify', src, L('booth_moved', id), 'success')

    elseif op == 'list' then
        local ids = {}
        for id in pairs(Booths) do ids[#ids + 1] = id end
        if #ids == 0 then
            TriggerClientEvent('fd-djkabin:client:notify', src, L('no_booths'), 'inform')
        else
            table.sort(ids)
            TriggerClientEvent('fd-djkabin:client:notify', src, L('booth_list', table.concat(ids, ', ')), 'inform')
        end
    end
end)
