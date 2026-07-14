import { useState } from 'react';
import type { Booth } from '../types';
import { formatTime } from './NowPlaying';
import { IconPlay, IconPlus, IconTrash } from './icons';

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
    <section className="card grow">
      <h2>{t('ui_queue')}</h2>
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
            <button
              className="mini-btn danger"
              onClick={() => control('queueRemove', { index: i + 1 })}
              aria-label={`${t('ui_delete')}: ${track.title}`}
              title={t('ui_delete')}
            >
              <IconTrash size={14} />
            </button>
          </div>
        ))}
      </div>
      {queue.length > 0 && (
        <button className="wide-btn" onClick={() => control('queueClear')}>
          <IconTrash size={14} /> {t('ui_clear_queue')}
        </button>
      )}
      <div className="add-song">
        <input
          type="text"
          placeholder={t('ui_add_song_placeholder')}
          aria-label={t('ui_add_song')}
          value={url}
          onChange={(e) => setUrl(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && submit('queueAdd')}
        />
        <div className="add-song-btns">
          <button className="wide-btn accent" onClick={() => submit('play')}>
            <IconPlay size={13} /> {t('ui_play_now')}
          </button>
          <button className="wide-btn" onClick={() => submit('queueAdd')}>
            <IconPlus size={14} /> {t('ui_add_to_queue')}
          </button>
        </div>
      </div>
    </section>
  );
}
