// Tarayıcı dev modu: oyun olmadan paneli test etmek için sahte veri enjekte eder.
import type { Booth, Playlist } from './types';

export function installMock(): void {
  const booth: Booth = {
    id: 'bahama',
    label: 'Bahama Mamas',
    coords: { x: 0, y: 0, z: 0 },
    heading: 0,
    settings: {
      volume: 80,
      radius: 60,
      algorithm: 'quadratic',
      accent: '#e24bd1',
      effects: {
        laser: { enabled: true, speed: 1.2, colorIndex: 1 },
        smoke: { enabled: false },
        lights: { enabled: true, speed: 1.0 },
        particles: { enabled: false },
        spotlight: { enabled: false },
      },
    },
    state: {
      track: {
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        videoId: 'dQw4w9WgXcQ',
        kind: 'yt',
        title: 'FUNK UNIVERSO (Slowed)',
        artist: 'Irokz',
        duration: 149,
        thumb: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      },
      playing: true,
      position: 66,
      repeatMode: false,
      shuffle: false,
      queue: [
        { url: 'https://youtu.be/a1', videoId: 'a1', kind: 'yt', title: 'DIA DELÍCIA - Nakama', artist: 'Nakama', duration: 95 },
        { url: 'https://youtu.be/a2', videoId: 'a2', kind: 'yt', title: 'MONTAGEM TOMADA (Slowed)', artist: 'DJ', duration: 84 },
        { url: 'https://youtu.be/a3', videoId: 'a3', kind: 'yt', title: 'LUNA BALA (Slowed)', artist: 'DJ', duration: 124 },
      ],
      playId: 1,
    },
  };

  const playlists: Playlist[] = [
    { id: 1, name: 'Classic', tracks: new Array(14).fill(booth.state.track!) },
    { id: 2, name: 'Slowed', tracks: new Array(8).fill(booth.state.track!) },
    { id: 3, name: 'Midnight Beats', tracks: new Array(11).fill(booth.state.track!) },
  ];

  setTimeout(() => {
    window.dispatchEvent(
      new MessageEvent('message', {
        data: {
          action: 'open',
          booth,
          playlists,
          locale: {
            ui_now_playing: 'ŞİMDİ ÇALIYOR', ui_nothing_playing: 'Şu an bir şey çalmıyor',
            ui_settings: 'AYARLAR', ui_music_volume: 'Müzik Sesi', ui_music_radius: 'Ses Menzili',
            ui_effects: 'KULÜP EFEKTLERİ', ui_queue: 'SIRA', ui_queue_empty: 'Sıra boş',
            ui_clear_queue: 'Sırayı Temizle', ui_add_song: 'Şarkı Ekle',
            ui_add_song_placeholder: 'YouTube veya ses linki yapıştır...',
            ui_playlists: 'PLAYLISTLER', ui_new_playlist: 'Yeni Playlist',
            ui_playlist_name: 'Playlist adı...', ui_songs: 'şarkı', ui_soundboard: 'SOUNDBOARD',
            ui_play_now: 'Şimdi Çal', ui_add_to_queue: 'Sıraya Ekle', ui_load_playlist: 'Sıraya Yükle',
            ui_add_current: 'Çalanı Ekle', ui_delete: 'Sil', ui_repeat: 'Tekrar', ui_shuffle: 'Karışık',
            ui_speed: 'Hız', ui_color: 'Renk', ui_toggle: 'Aç/Kapat', ui_close: 'Kapat',
            ui_control_panel: 'MÜZİK VE EFEKT KONTROLÜ',
          },
          soundboard: [
            { id: 'airhorn', label: 'Air Horn', icon: '📯', url: '' },
            { id: 'applause', label: 'Applause', icon: '👏', url: '' },
            { id: 'siren', label: 'Siren', icon: '🚨', url: '' },
            { id: 'drop', label: 'Drop', icon: '💥', url: '' },
            { id: 'rewind', label: 'Rewind', icon: '⏪', url: '' },
            { id: 'letsgo', label: "Let's Go!", icon: '🔥', url: '' },
          ],
          effectsConfig: {
            laser: { label: 'Lasers', hasSpeed: true, hasColor: true, colors: [[255, 0, 80], [0, 120, 255], [0, 255, 120], [255, 200, 0], [180, 0, 255]] },
            smoke: { label: 'Smoke' },
            lights: { label: 'Club Lights', hasSpeed: true },
            particles: { label: 'Particles' },
            spotlight: { label: 'Spot Light' },
          },
          streamerMode: false,
        },
      }),
    );
  }, 200);
}
