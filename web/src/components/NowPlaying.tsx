import { useEffect, useRef, useState } from 'react';
import type { Booth } from '../types';
import { IconMusic, IconNext, IconPause, IconPlay, IconRepeat, IconShuffle, IconStop } from './icons';

export function formatTime(sec: number): string {
  if (!isFinite(sec) || sec < 0) sec = 0;
  const m = Math.floor(sec / 60);
  const s = Math.floor(sec % 60);
  return `${m}:${s.toString().padStart(2, '0')}`;
}

interface Props {
  booth: Booth;
  receivedAt: number;
  t: (key: string) => string;
  control: (action: string, data?: unknown) => void;
}

export default function NowPlaying({ booth, receivedAt, t, control }: Props) {
  const { track, playing, position, repeatMode, shuffle } = booth.state;
  const [pos, setPos] = useState(position);
  const barRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const tick = () => {
      const extra = playing ? (Date.now() - receivedAt) / 1000 : 0;
      let p = position + extra;
      if (track && track.duration > 0) p = Math.min(p, track.duration);
      setPos(p);
    };
    tick();
    const id = setInterval(tick, 500);
    return () => clearInterval(id);
  }, [position, playing, receivedAt, track]);

  const seek = (e: React.MouseEvent) => {
    if (!track || track.duration <= 0 || !barRef.current) return;
    const rect = barRef.current.getBoundingClientRect();
    const frac = Math.min(1, Math.max(0, (e.clientX - rect.left) / rect.width));
    control('seek', { position: frac * track.duration });
  };

  const progress = track && track.duration > 0 ? Math.min(100, (pos / track.duration) * 100) : 0;

  return (
    <section className="card">
      <h2>{t('ui_now_playing')}</h2>
      {track ? (
        <>
          <div className="np-track">
            {track.thumb ? (
              <img className="np-art" src={track.thumb} alt="" />
            ) : (
              <div className="np-art np-art-placeholder"><IconMusic size={24} /></div>
            )}
            <div className="np-info">
              <span className="np-title" title={track.title}>{track.title}</span>
              <span className="np-artist">{track.artist || '—'}</span>
            </div>
          </div>
          <div
            className="np-progress"
            ref={barRef}
            onClick={seek}
            role="slider"
            aria-label={t('ui_now_playing')}
            aria-valuemin={0}
            aria-valuemax={track.duration > 0 ? Math.round(track.duration) : 0}
            aria-valuenow={Math.round(pos)}
          >
            <div className="np-progress-track">
              <div className="np-progress-fill" style={{ width: `${progress}%` }} />
            </div>
          </div>
          <div className="np-times">
            <span>{formatTime(pos)}</span>
            <span>{track.duration > 0 ? formatTime(track.duration) : '--:--'}</span>
          </div>
        </>
      ) : (
        <p className="muted">{t('ui_nothing_playing')}</p>
      )}
      <div className="np-controls">
        <button
          className={shuffle ? 'ctl active' : 'ctl'}
          onClick={() => control('shuffle')}
          aria-label={t('ui_shuffle')}
          aria-pressed={shuffle}
          title={t('ui_shuffle')}
        >
          <IconShuffle />
        </button>
        <button className="ctl" onClick={() => control('stop')} aria-label="Stop" title="Stop">
          <IconStop />
        </button>
        <button
          className="ctl ctl-main"
          onClick={() => control(playing ? 'pause' : 'resume')}
          aria-label={playing ? 'Pause' : 'Play'}
          title={playing ? 'Pause' : 'Play'}
        >
          {playing ? <IconPause size={20} /> : <IconPlay size={20} />}
        </button>
        <button className="ctl" onClick={() => control('skip')} aria-label="Next" title="Next">
          <IconNext />
        </button>
        <button
          className={repeatMode ? 'ctl active' : 'ctl'}
          onClick={() => control('repeat')}
          aria-label={t('ui_repeat')}
          aria-pressed={repeatMode}
          title={t('ui_repeat')}
        >
          <IconRepeat />
        </button>
      </div>
    </section>
  );
}
