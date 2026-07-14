import { useEffect, useState } from 'react';
import type { Booth } from '../types';

interface Props {
  booth: Booth;
  t: (key: string) => string;
  control: (action: string, data?: unknown) => void;
}

export default function Settings({ booth, t, control }: Props) {
  const [volume, setVolume] = useState(booth.settings.volume);
  const [radius, setRadius] = useState(booth.settings.radius);

  useEffect(() => setVolume(booth.settings.volume), [booth.settings.volume]);
  useEffect(() => setRadius(booth.settings.radius), [booth.settings.radius]);

  return (
    <section className="card">
      <h2>⚙ {t('ui_settings')}</h2>
      <label className="slider-row">
        <span>{t('ui_music_volume')}</span>
        <input
          type="range" min={0} max={100} value={volume}
          onChange={(e) => setVolume(Number(e.target.value))}
          onMouseUp={() => control('volume', { value: volume })}
          onTouchEnd={() => control('volume', { value: volume })}
        />
        <span className="slider-val">{volume}%</span>
      </label>
      <label className="slider-row">
        <span>{t('ui_music_radius')}</span>
        <input
          type="range" min={5} max={300} value={radius}
          onChange={(e) => setRadius(Number(e.target.value))}
          onMouseUp={() => control('radius', { value: radius })}
          onTouchEnd={() => control('radius', { value: radius })}
        />
        <span className="slider-val">{Math.round(radius)}m</span>
      </label>
      <label className="slider-row">
        <span>Falloff</span>
        <select
          value={booth.settings.algorithm}
          onChange={(e) => control('algorithm', { value: e.target.value })}
        >
          <option value="linear">Linear</option>
          <option value="quadratic">Quadratic</option>
          <option value="exponential">Exponential</option>
        </select>
      </label>
    </section>
  );
}
