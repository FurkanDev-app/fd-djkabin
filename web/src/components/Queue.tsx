import { useState } from 'react';
import type { Booth } from '../types';
import { formatTime } from './NowPlaying';

interface Props {
  booth: Booth;
  t: (key: string) => string;
  control: (action: string, data?: unknown) => void;
}

export default function Queue({ booth, t, control }: Props) {
  const [url, setUrl] = useState('');
  const queue = booth.state.queue ?? [];

  const submit = (action: 'play' | 'queueAdd') => {
    const trimmed = url.trim();
    if (!trimmed) return;
    control(action, { url: trimmed });
    setUrl('');
  };

  return (
    <section className="card">
      <h2>☰ {t('ui_queue')}</h2>
      <div className="queue-list">
        {queue.length === 0 && <p className="muted">{t('ui_queue_empty')}</p>}
        {queue.map((track, i) => (
          <div className="queue-item" key={`${track.url}-${i}`}>
            <span className="queue-num">{i + 1}</span>
            <div className="queue-info">
              <span className="queue-title" title={track.title}>{track.title}</span>
              <span className="queue-sub">{track.kind === 'yt' ? 'YouTube' : 'Audio'}</span>
            </div>
            <span className="queue-dur">{track.duration > 0 ? formatTime(track.duration) : ''}</span>
            <button className="mini-btn" onClick={() => control('queueRemove', { index: i + 1 })} title={t('ui_delete')}>🗑</button>
          </div>
        ))}
      </div>
      {queue.length > 0 && (
        <button className="wide-btn" onClick={() => control('queueClear')}>🗑 {t('ui_clear_queue')}</button>
      )}
      <div className="add-song">
        <input
          type="text"
          placeholder={t('ui_add_song_placeholder')}
          value={url}
          onChange={(e) => setUrl(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && submit('queueAdd')}
        />
        <div className="add-song-btns">
          <button className="wide-btn accent" onClick={() => submit('play')}>▶ {t('ui_play_now')}</button>
          <button className="wide-btn" onClick={() => submit('queueAdd')}>+ {t('ui_add_to_queue')}</button>
        </div>
      </div>
    </section>
  );
}
