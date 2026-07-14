import { useCallback, useEffect, useRef, useState } from 'react';
import type { Booth, EffectConfig, Locale, Playlist, SoundboardItem, Track } from './types';
import { fetchNui, sendControl } from './nui';
import { handleAudioSync, handleDestroyPlayer, playSfx } from './playerManager';
import NowPlaying from './components/NowPlaying';
import Settings from './components/Settings';
import Effects from './components/Effects';
import Queue from './components/Queue';
import Playlists from './components/Playlists';
import Soundboard from './components/Soundboard';
import { IconClose } from './components/icons';

export default function App() {
  const [visible, setVisible] = useState(false);
  const [booth, setBooth] = useState<Booth | null>(null);
  const [playlists, setPlaylists] = useState<Playlist[]>([]);
  const [locale, setLocale] = useState<Locale>({});
  const [soundboard, setSoundboard] = useState<SoundboardItem[]>([]);
  const [effectsConfig, setEffectsConfig] = useState<EffectConfig[]>([]);
  const [streamerMode, setStreamerMode] = useState(false);
  const receivedAt = useRef(Date.now());
  const boothRef = useRef<Booth | null>(null);
  boothRef.current = booth;

  const t = useCallback(
    (key: string) => locale[key] ?? key,
    [locale],
  );

  const close = useCallback(() => {
    setVisible(false);
    void fetchNui('close');
  }, []);

  useEffect(() => {
    const onMessage = (e: MessageEvent) => {
      const msg = e.data;
      if (!msg || typeof msg !== 'object') return;
      switch (msg.action) {
        case 'open':
          setBooth(msg.booth);
          receivedAt.current = Date.now();
          setPlaylists(msg.playlists ?? []);
          setLocale(msg.locale ?? {});
          setSoundboard(msg.soundboard ?? []);
          setEffectsConfig(msg.effectsConfig ?? []);
          setStreamerMode(!!msg.streamerMode);
          setVisible(true);
          break;
        case 'boothState':
          if (boothRef.current && msg.booth?.id === boothRef.current.id) {
            setBooth(msg.booth);
            receivedAt.current = Date.now();
          }
          break;
        case 'playlists':
          if (boothRef.current && msg.boothId === boothRef.current.id) {
            setPlaylists(msg.playlists ?? []);
          }
          break;
        case 'audioSync':
          handleAudioSync(msg);
          break;
        case 'destroyPlayer':
          handleDestroyPlayer(msg.boothId);
          break;
        case 'sfx':
          playSfx(msg.url, msg.volume);
          break;
        case 'streamerMode':
          setStreamerMode(!!msg.enabled);
          break;
      }
    };
    window.addEventListener('message', onMessage);
    return () => window.removeEventListener('message', onMessage);
  }, []);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [close]);

  if (!visible || !booth) return null;

  const control = (action: string, data?: unknown) => sendControl(booth.id, action, data);
  const addTrackToPlaylist = (playlistId: number, track: Track) =>
    control('playlistAddTrack', { id: playlistId, track });

  return (
    <div className="overlay" style={{ ['--accent' as string]: booth.settings.accent }}>
      <div className="panel">
        <header className="panel-header">
          <div>
            <h1>{booth.label}</h1>
            <span className="subtitle">{t('ui_control_panel')}</span>
          </div>
          {streamerMode && <span className="streamer-badge">STREAMER</span>}
          <button className="close-btn" onClick={close} aria-label={t('ui_close')} title={t('ui_close')}>
            <IconClose size={15} />
          </button>
        </header>
        <div className="columns">
          <div className="col">
            <NowPlaying booth={booth} receivedAt={receivedAt.current} t={t} control={control} />
            <Settings booth={booth} t={t} control={control} />
          </div>
          <div className="col">
            <Effects booth={booth} config={effectsConfig} t={t} control={control} />
            <Soundboard items={soundboard} t={t} control={control} />
          </div>
          <div className="col">
            <Queue booth={booth} t={t} control={control} />
            <Playlists
              booth={booth}
              playlists={playlists}
              t={t}
              control={control}
              onAddCurrent={addTrackToPlaylist}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
