import type { Booth, EffectConfig } from '../types';

interface Props {
  booth: Booth;
  config: Record<string, EffectConfig>;
  t: (key: string) => string;
  control: (action: string, data?: unknown) => void;
}

const EFFECT_ICONS: Record<string, string> = {
  laser: '⚡', smoke: '🌫', lights: '💡', particles: '✨', spotlight: '🔦',
};

export default function Effects({ booth, config, t, control }: Props) {
  const effects = booth.settings.effects ?? {};
  return (
    <section className="card">
      <h2>✦ {t('ui_effects')}</h2>
      {Object.entries(config).map(([name, cfg]) => {
        const state = effects[name] ?? { enabled: false };
        return (
          <div className="effect-row" key={name}>
            <div className="effect-head">
              <span className="effect-label">{EFFECT_ICONS[name] ?? '•'} {cfg.label}</span>
              <button
                className={state.enabled ? 'switch on' : 'switch'}
                onClick={() => control('effect', { name, enabled: !state.enabled })}
                title={t('ui_toggle')}
              >
                <span className="knob" />
              </button>
            </div>
            {state.enabled && cfg.hasSpeed && (
              <label className="slider-row small">
                <span>{t('ui_speed')}</span>
                <input
                  type="range" min={0.2} max={3} step={0.1}
                  defaultValue={state.speed ?? 1}
                  onMouseUp={(e) => control('effect', { name, speed: Number((e.target as HTMLInputElement).value) })}
                />
              </label>
            )}
            {state.enabled && cfg.hasColor && cfg.colors && (
              <div className="color-row">
                <span>{t('ui_color')}</span>
                {cfg.colors.map((c, i) => (
                  <button
                    key={i}
                    className={state.colorIndex === i + 1 ? 'swatch selected' : 'swatch'}
                    style={{ background: `rgb(${c[0]},${c[1]},${c[2]})` }}
                    onClick={() => control('effect', { name, colorIndex: i + 1 })}
                  />
                ))}
              </div>
            )}
          </div>
        );
      })}
    </section>
  );
}
