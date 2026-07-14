import { useState } from 'react';
import type { Booth, Playlist, Track } from '../types';
import { formatTime } from './NowPlaying';
import { IconLoad, IconPlay, IconPlus, IconTrash } from './icons';

interface Props {
  booth: Booth;
  playlists: Playlist[];
  t: (key: string) => string;
  control: (action: string, data?: unknown) => void;
  onAddCurrent: (playlistId: number, track: Track) => void;
}

export default function Playlists({ booth, playlists, t, control, onAddCurrent }: Props) {
  const [name, setName] = useState('');
  const [expanded, setExpanded] = useState<number | null>(null);
  const current = booth.state.track;

  const create = () => {
    const trimmed = name.trim();
    if (!trimmed) return;
    control('playlistCreate', { name: trimmed });
    setName('');
  };

  return (
    <section className="card grow">
      <h2>{t('ui_playlists')}</h2>
      <div className="add-song-btns">
        <input
          type="text"
          placeholder={t('ui_playlist_name')}
          aria-label={t('ui_new_playlist')}
          value={name}
          onChange={(e) => setName(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && create()}
        />
        <button className="wide-btn accent fit" onClick={create}>
          <IconPlus size={14} /> {t('ui_new_playlist')}
        </button>
      </div>
      <div className="playlist-list">
        {playlists.length === 0 && <p className="muted">{t('ui_no_playlists')}</p>}
        {playlists.map((pl) => (
          <div className="playlist-item" key={pl.id}>
            <div
              className="playlist-head"
              onClick={() => setExpanded(expanded === pl.id ? null : pl.id)}
              role="button"
              tabIndex={0}
              onKeyDown={(e) => e.key === 'Enter' && setExpanded(expanded === pl.id ? null : pl.id)}
              aria-expanded={expanded === pl.id}
            >
              <span className="playlist-name">{pl.name}</span>
              <span className="playlist-count">{pl.tracks.length} {t('ui_songs')}</span>
            </div>
            <div className="playlist-actions">
              <button
                className="mini-btn"
                onClick={() => control('playlistLoad', { id: pl.id })}
                aria-label={`${t('ui_load_playlist')}: ${pl.name}`}
                title={t('ui_load_playlist')}
              >
                <IconLoad size={14} />
              </button>
              {current && (
                <button
                  className="mini-btn"
                  onClick={() => onAddCurrent(pl.id, current)}
                  aria-label={`${t('ui_add_current')}: ${pl.name}`}
                  title={t('ui_add_current')}
                >
                  <IconPlus size={14} />
                </button>
              )}
              <button
                className="mini-btn danger"
                onClick={() => control('playlistDelete', { id: pl.id })}
                aria-label={`${t('ui_delete')}: ${pl.name}`}
                title={t('ui_delete')}
              >
                <IconTrash size={14} />
              </button>
            </div>
            {expanded === pl.id && pl.tracks.length > 0 && (
              <div className="playlist-tracks">
                {pl.tracks.map((track, i) => (
                  <div className="queue-item small" key={`${track.url}-${i}`}>
                    <span className="queue-num">{i + 1}</span>
                    <div className="queue-info">
                      <span className="queue-title" title={track.title}>{track.title}</span>
                    </div>
                    <span className="queue-dur">{track.duration > 0 ? formatTime(track.duration) : ''}</span>
                    <button
                      className="mini-btn"
                      onClick={() => control('playTrack', { track })}
                      aria-label={`${t('ui_play_now')}: ${track.title}`}
                      title={t('ui_play_now')}
                    >
                      <IconPlay size={13} />
                    </button>
                    <button
                      className="mini-btn danger"
                      onClick={() => control('playlistRemoveTrack', { id: pl.id, index: i + 1 })}
                      aria-label={`${t('ui_delete')}: ${track.title}`}
                      title={t('ui_delete')}
                    >
                      <IconTrash size={13} />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        ))}
      </div>
    </section>
  );
}
