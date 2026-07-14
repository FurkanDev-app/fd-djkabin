-- Queue + otomatik geçiş. Şarkı süresi client raporuyla öğrenilir
-- (fd-djkabin:server:reportMeta); süre dolunca sunucu sıradakini başlatır,
-- böylece DJ offline olsa bile müzik devam eder.

local nextPlayId = 0

local function isYouTube(url)
    local id = url:match('youtu%.be/([%w%-_]+)')
        or url:match('[?&]v=([%w%-_]+)')
        or url:match('youtube%.com/embed/([%w%-_]+)')
        or url:match('youtube%.com/shorts/([%w%-_]+)')
    return id
end

--- URL'den track objesi üretir; geçersizse nil
function BuildTrack(url)
    url = tostring(url or ''):gsub('%s+', '')
    if not url:match('^https?://') then return nil end
    local videoId = isYouTube(url)
    if videoId then
        return {
            url = url,
            videoId = videoId,
            kind = 'yt',
            title = url,
            artist = '',
            duration = 0,
            thumb = ('https://i.ytimg.com/vi/%s/mqdefault.jpg'):format(videoId),
        }
    end
    return { url = url, kind = 'direct', title = url:match('([^/]+)$') or url, artist = '', duration = 0, thumb = nil }
end

--- Bir track'i booth'ta hemen başlatır ve herkese yayınlar
function PlayTrack(booth, track, position)
    nextPlayId = nextPlayId + 1
    booth.state.track = track
    booth.state.playing = true
    booth.state.position = position or 0.0
    booth.state.startedAt = GetGameTimer() - math.floor((position or 0.0) * 1000)
    booth.state.playId = nextPlayId
    BroadcastBooth(booth)
end

function StopBooth(booth)
    booth.state.track = nil
    booth.state.playing = false
    booth.state.position = 0.0
    booth.state.playId = 0
    BroadcastBooth(booth)
end

--- Sıradaki şarkıya geçer. Repeat açıksa aynı şarkı, shuffle açıksa rastgele.
function AdvanceQueue(booth)
    local st = booth.state
    if st.repeatMode and st.track then
        PlayTrack(booth, st.track, 0.0)
        return
    end
    if #st.queue == 0 then
        StopBooth(booth)
        return
    end
    local index = 1
    if st.shuffle and #st.queue > 1 then
        index = math.random(1, #st.queue)
    end
    local nextTrack = table.remove(st.queue, index)
    PlayTrack(booth, nextTrack, 0.0)
end

function QueueAdd(booth, track)
    booth.state.queue[#booth.state.queue + 1] = track
    -- Hiçbir şey çalmıyorsa direkt başlat
    if not booth.state.track then
        AdvanceQueue(booth)
    else
        BroadcastBooth(booth)
    end
end

-- Süre dolunca otomatik geçiş
CreateThread(function()
    while true do
        Wait(1000)
        for _, booth in pairs(Booths) do
            local st = booth.state
            if st.playing and st.track and (st.track.duration or 0) > 0 then
                local pos = GetBoothPosition(booth)
                if pos >= st.track.duration + 1.5 then
                    AdvanceQueue(booth)
                end
            end
        end
    end
end)

-- Süresi bilinmeyen bir şarkı (metadata hiç rapor edilmemiş) sonsuza kadar
-- "çalıyor" görünmesin: 6 saat sonra otomatik durdur.
CreateThread(function()
    while true do
        Wait(60000)
        for _, booth in pairs(Booths) do
            local st = booth.state
            if st.playing and st.track and (st.track.duration or 0) == 0 then
                if GetBoothPosition(booth) > 21600 then
                    AdvanceQueue(booth)
                end
            end
        end
    end
end)
