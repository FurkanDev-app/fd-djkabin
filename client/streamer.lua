-- Streamer mode: müzik + soundboard mute edilir, efektler çalışmaya devam eder.
-- Tercih KVP'de saklanır, yeniden bağlanınca hatırlanır.

StreamerMode = GetResourceKvpInt('fd_djkabin_streamer') == 1

RegisterCommand('streamermode', function()
    StreamerMode = not StreamerMode
    SetResourceKvpInt('fd_djkabin_streamer', StreamerMode and 1 or 0)
    Bridge.Notify(L(StreamerMode and 'streamer_on' or 'streamer_off'), StreamerMode and 'success' or 'inform')
    SendNUIMessage({ action = 'streamerMode', enabled = StreamerMode })
end, false)
