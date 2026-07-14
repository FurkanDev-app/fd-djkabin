export interface Track {
  url: string;
  videoId?: string;
  kind: 'yt' | 'direct';
  title: string;
  artist: string;
  duration: number;
  thumb?: string;
}

export interface EffectState {
  enabled: boolean;
  speed?: number;
  colorIndex?: number;
}

export interface BoothSettings {
  volume: number;
  radius: number;
  algorithm: 'linear' | 'quadratic' | 'exponential';
  accent: string;
  effects: Record<string, EffectState>;
}

export interface BoothState {
  track: Track | null;
  playing: boolean;
  position: number;
  repeatMode: boolean;
  shuffle: boolean;
  queue: Track[];
  playId: number;
}

export interface Booth {
  id: string;
  label: string;
  coords: { x: number; y: number; z: number };
  heading: number;
  settings: BoothSettings;
  state: BoothState;
}

export interface Playlist {
  id: number;
  name: string;
  tracks: Track[];
}

export interface SoundboardItem {
  id: string;
  label: string;
  icon: string;
  url: string;
}

export interface EffectConfig {
  label: string;
  colors?: number[][];
  hasSpeed?: boolean;
  hasColor?: boolean;
}

export type Locale = Record<string, string>;
