// Tutarlı ikon seti: 16px viewBox, 1.75 stroke, currentColor.
// Emoji karışımı yerine tek aile — panel genelinde aynı görsel dil.

interface IconProps {
  size?: number;
}

const base = (size = 16) => ({
  width: size,
  height: size,
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 2,
  strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
  'aria-hidden': true,
});

export const IconPlay = ({ size }: IconProps) => (
  <svg {...base(size)} fill="currentColor" stroke="none">
    <path d="M7 4.5v15a1 1 0 0 0 1.53.85l12-7.5a1 1 0 0 0 0-1.7l-12-7.5A1 1 0 0 0 7 4.5Z" />
  </svg>
);

export const IconPause = ({ size }: IconProps) => (
  <svg {...base(size)} fill="currentColor" stroke="none">
    <rect x="6" y="4" width="4" height="16" rx="1.2" />
    <rect x="14" y="4" width="4" height="16" rx="1.2" />
  </svg>
);

export const IconStop = ({ size }: IconProps) => (
  <svg {...base(size)} fill="currentColor" stroke="none">
    <rect x="5.5" y="5.5" width="13" height="13" rx="1.5" />
  </svg>
);

export const IconNext = ({ size }: IconProps) => (
  <svg {...base(size)} fill="currentColor" stroke="none">
    <path d="M5 5.14v13.72a1 1 0 0 0 1.5.86l11-6.86a1 1 0 0 0 0-1.72l-11-6.86a1 1 0 0 0-1.5.86Z" />
    <rect x="18" y="4" width="2.5" height="16" rx="1" />
  </svg>
);

export const IconShuffle = ({ size }: IconProps) => (
  <svg {...base(size)}>
    <path d="M2 18h2.5c1.5 0 2.9-.7 3.8-1.9l5.4-8.2A4.6 4.6 0 0 1 17.5 6H22" />
    <path d="M2 6h2.5c1.5 0 2.9.7 3.8 1.9l5.4 8.2a4.6 4.6 0 0 0 3.8 1.9H22" />
    <path d="m19 3 3 3-3 3" />
    <path d="m19 15 3 3-3 3" />
  </svg>
);

export const IconRepeat = ({ size }: IconProps) => (
  <svg {...base(size)}>
    <path d="m17 2 4 4-4 4" />
    <path d="M3 11v-1a4 4 0 0 1 4-4h14" />
    <path d="m7 22-4-4 4-4" />
    <path d="M21 13v1a4 4 0 0 1-4 4H3" />
  </svg>
);

export const IconTrash = ({ size }: IconProps) => (
  <svg {...base(size)}>
    <path d="M3 6h18" />
    <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6" />
    <path d="M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
  </svg>
);

export const IconPlus = ({ size }: IconProps) => (
  <svg {...base(size)}>
    <path d="M12 5v14" />
    <path d="M5 12h14" />
  </svg>
);

export const IconClose = ({ size }: IconProps) => (
  <svg {...base(size)}>
    <path d="M18 6 6 18" />
    <path d="m6 6 12 12" />
  </svg>
);

export const IconMusic = ({ size }: IconProps) => (
  <svg {...base(size)}>
    <path d="M9 18V5l12-2v13" />
    <circle cx="6" cy="18" r="3" />
    <circle cx="18" cy="16" r="3" />
  </svg>
);

export const IconLoad = ({ size }: IconProps) => (
  <svg {...base(size)}>
    <path d="M12 3v12" />
    <path d="m7 10 5 5 5-5" />
    <path d="M5 21h14" />
  </svg>
);
