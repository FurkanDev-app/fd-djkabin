import { Fragment } from 'react';
import type { Booth, EffectConfig } from '../types';

interface Props {
  booth: Booth;
  config: EffectConfig[];
  t: (key: string) => string;
  control: (action: string, data?: unknown) => void;
}

export default function Effects({ booth, config, t, control }: Props) {
  const effects = booth.settings.effects ?? {};
  return (
    <section className="card grow">
      <h2>{t('ui_effects')}</h2>
      <div className="effects-grid">
        {config.map((cfg) => {
          const state = effects[cfg.name] ?? { enabled: false };
          const hasSettings = state.enabled && (cfg.hasSpeed || (cfg.hasColor && cfg.colors));
          return (
            <Fragment key={cfg.name}>
              <div className={state.enabled ? 'effect-cell on' : 'effect-cell'}>
                <span className="effect-label">{cfg.label}</span>
                <button
                  className={state.enabled ? 'switch on' : 'switch'}
                  onClick={() => control('effect', { name: cfg.name, enabled: !state.enabled })}
                  role="switch"
                  aria-checked={state.enabled}
                  aria-label={cfg.label}
                >
                  <span className="knob" />
                </button>
              </div>
              {hasSettings && (
                <div className="effect-settings">
                  {cfg.hasSpeed && (
                    <label className="slider-row small">
                      <span>{t('ui_speed')}</span>
                      <input
                        type="range" min={0.2} max={3} step={0.1}
                        defaultValue={state.speed ?? 1}
                        aria-label={`${cfg.label} ${t('ui_speed')}`}
                        onMouseUp={(e) => control('effect', { name: cfg.name, speed: Number((e.target as HTMLInputElement).value) })}
                      />
                    </label>
                  )}
                  {cfg.hasColor && cfg.colors && (
                    <div className="color-row">
                      <span>{t('ui_color')}</span>
                      {cfg.colors.map((c, i) => (
                        <button
                          key={i}
                          className={state.colorIndex === i + 1 ? 'swatch selected' : 'swatch'}
                          style={{ background: `rgb(${c[0]},${c[1]},${c[2]})` }}
                          aria-label={`${cfg.label} ${t('ui_color')} ${i + 1}`}
                          aria-pressed={state.colorIndex === i + 1}
                          onClick={() => control('effect', { name: cfg.name, colorIndex: i + 1 })}
                        />
                      ))}
                    </div>
                  )}
                </div>
              )}
            </Fragment>
          );
        })}
      </div>
    </section>
  );
}
