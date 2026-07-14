import type { SoundboardItem } from '../types';

interface Props {
  items: SoundboardItem[];
  t: (key: string) => string;
  control: (action: string, data?: unknown) => void;
}

export default function Soundboard({ items, t, control }: Props) {
  if (items.length === 0) return null;
  return (
    <section className="card">
      <h2>{t('ui_soundboard')}</h2>
      <div className="sfx-grid">
        {items.map((sfx) => (
          <button
            key={sfx.id}
            className="sfx-btn"
            onClick={() => control('soundboard', { id: sfx.id })}
            aria-label={sfx.label}
          >
            <span className="sfx-icon material-symbol" aria-hidden>{sfx.icon}</span>
            <span>{sfx.label}</span>
          </button>
        ))}
      </div>
    </section>
  );
}
