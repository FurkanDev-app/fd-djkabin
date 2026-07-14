import { useEffect, useRef, useState } from 'react';
import type { Booth } from '../types';

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
      <h2>♪ {t('ui_now_playing')}</h2>
      {track ? (
        <>
          <div className="np-track">
            {track.thumb ? (
              <img className="np-art" src={track.thumb} alt="" />
            ) : (
              <div className="np-art np-art-placeholder">♫</div>
            )}
            <div className="np-info">
              <span className="np-title" title={track.title}>{track.title}</span>
              <span className="np-artist">{track.artist || '—'}</span>
            </div>
          </div>
          <div className="np-progress" ref={barRef} onClick={seek}>
            <div className="np-progress-fill" style={{ width: `${progress}%` }} />
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
        <button className={shuffle ? 'ctl active' : 'ctl'} onClick={() => control('shuffle')} title={t('ui_shuffle')}>⇄</button>
        <button className="ctl" onClick={() => control('stop')} title="Stop">■</button>
        <button
          className="ctl ctl-main"
          onClick={() => control(playing ? 'pause' : 'resume')}
          title={playing ? 'Pause' : 'Play'}
        >
          {playing ? '⏸' : '▶'}
        </button>
        <button className="ctl" onClick={() => control('skip')} title="Next">⏭</button>
        <button className={repeatMode ? 'ctl active' : 'ctl'} onClick={() => control('repeat')} title={t('ui_repeat')}>↻</button>
      </div>
    </section>
  );
}
