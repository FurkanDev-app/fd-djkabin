-- Playlist CRUD - playlistler booth'a bağlıdır; booth yetkisi olan herkes yönetebilir.

function GetPlaylists(boothId)
    local rows = MySQL.query.await('SELECT id, name, tracks FROM fd_djkabin_playlists WHERE booth_id = ?', { boothId }) or {}
    local out = {}
    for _, row in ipairs(rows) do
        local ok, tracks = pcall(json.decode, row.tracks)
        out[#out + 1] = {
            id = row.id,
            name = row.name,
            tracks = (ok and type(tracks) == 'table') and tracks or {},
        }
    end
    return out
end

function CreatePlaylist(src, boothId, name)
    name = tostring(name or ''):sub(1, 100)
    if name == '' then return nil end
    local id = MySQL.insert.await('INSERT INTO fd_djkabin_playlists (booth_id, owner, name, tracks) VALUES (?, ?, ?, ?)', {
        boothId, Bridge.GetIdentifier(src), name, '[]',
    })
    return id
end

function DeletePlaylist(boothId, playlistId)
    MySQL.update.await('DELETE FROM fd_djkabin_playlists WHERE id = ? AND booth_id = ?', { playlistId, boothId })
end

local function getPlaylistRow(boothId, playlistId)
    local rows = MySQL.query.await('SELECT tracks FROM fd_djkabin_playlists WHERE id = ? AND booth_id = ?', { playlistId, boothId })
    if not rows or not rows[1] then return nil end
    local ok, tracks = pcall(json.decode, rows[1].tracks)
    return (ok and type(tracks) == 'table') and tracks or {}
end

function PlaylistAddTrack(boothId, playlistId, track)
    local tracks = getPlaylistRow(boothId, playlistId)
    if not tracks then return false end
    tracks[#tracks + 1] = track
    MySQL.update.await('UPDATE fd_djkabin_playlists SET tracks = ? WHERE id = ?', { json.encode(tracks), playlistId })
    return true
end

function PlaylistRemoveTrack(boothId, playlistId, index)
    local tracks = getPlaylistRow(boothId, playlistId)
    if not tracks or not tracks[index] then return false end
    table.remove(tracks, index)
    MySQL.update.await('UPDATE fd_djkabin_playlists SET tracks = ? WHERE id = ?', { json.encode(tracks), playlistId })
    return true
end

function GetPlaylistTracks(boothId, playlistId)
    return getPlaylistRow(boothId, playlistId)
end
