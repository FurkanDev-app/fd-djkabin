// Booth başına gizli player yönetimi: YouTube IFrame API + HTML5 Audio.
// Lua'dan gelen periyodik 'audioSync' mesajlarıyla sürülür; drift düzeltme,
// metadata raporu ve şarkı bitti bildirimi buradan yapılır.

import { fetchNui } from './nui';
import type { Track } from './types';

interface YTPlayer {
  loadVideoById(id: string, start: number): void;
  playVideo(): void;
  pauseVideo(): void;
  seekTo(sec: number, allowSeekAhead: boolean): void;
  setVolume(vol: number): void;
  getCurrentTime(): number;
  getDuration(): number;
  getPlayerState(): number;
  destroy(): void;
}

interface BoothPlayer {
  kind: 'yt' | 'direct';
  playId: number;
  yt?: YTPlayer;
  audio?: HTMLAudioElement;
  ready: boolean;
  metaReported: boolean;
  endedReported: boolean;
  el?: HTMLElement;
}

interface SyncMsg {
  boothId: string;
  playId: number;
  track: Track;
  playing: boolean;
  position: number;
  volume: number; // 0.0 - 1.0
  drift: number;
}

const players = new Map<string, BoothPlayer>();

let ytApiPromise: Promise<void> | null = null;

declare global {
  interface Window {
    onYouTubeIframeAPIReady?: () => void;
    YT?: {
      Player: new (el: HTMLElement, opts: unknown) => YTPlayer;
      PlayerState: { ENDED: number; PLAYING: number; PAUSED: number };
    };
  }
}

function loadYouTubeApi(): Promise<void> {
  if (ytApiPromise) return ytApiPromise;
  ytApiPromise = new Promise((resolve) => {
    if (window.YT?.Player) return resolve();
    window.onYouTubeIframeAPIReady = () => resolve();
    const tag = document.createElement('script');
    tag.src = 'https://www.youtube.com/iframe_api';
    document.head.appendChild(tag);
  });
  return ytApiPromise;
}

function playersRoot(): HTMLElement {
  return document.getElementById('players') ?? document.body;
}

async function reportMeta(boothId: string, playId: number, meta: { title?: string; artist?: string; duration?: number }) {
  await fetchNui('reportMeta', { boothId, playId, ...meta });
}

async function fetchYtTitle(videoId: string): Promise<{ title?: string; artist?: string }> {
  try {
    const resp = await fetch(`https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoId}&format=json`);
    if (!resp.ok) return {};
    const data = (await resp.json()) as { title?: string; author_name?: string };
    return { title: data.title, artist: data.author_name };
  } catch {
    return {};
  }
}

function destroyPlayer(boothId: string) {
  const p = players.get(boothId);
  if (!p) return;
  players.delete(boothId);
  try {
    p.yt?.destroy();
  } catch {
    /* yoksay */
  }
  if (p.audio) {
    p.audio.pause();
    p.audio.src = '';
  }
  p.el?.remove();
}

async function createPlayer(msg: SyncMsg): Promise<void> {
  destroyPlayer(msg.boothId);

  const player: BoothPlayer = {
    kind: msg.track.kind,
    playId: msg.playId,
    ready: false,
    metaReported: false,
    endedReported: false,
  };
  players.set(msg.boothId, player);

  if (msg.track.kind === 'yt' && msg.track.videoId) {
    await loadYouTubeApi();
    // Async yükleme sırasında booth başka şarkıya geçmiş olabilir
    if (players.get(msg.boothId) !== player) return;
    const el = document.createElement('div');
    playersRoot().appendChild(el);
    player.el = el;
    const videoId = msg.track.videoId;
    player.yt = new window.YT!.Player(el, {
      width: 64,
      height: 36,
      videoId,
      playerVars: { autoplay: 1, controls: 0, disablekb: 1, start: Math.floor(msg.position) },
      events: {
        onReady: () => {
          if (players.get(msg.boothId) !== player) return;
          player.ready = true;
          player.yt!.setVolume(Math.round(msg.volume * 100));
          if (!msg.playing) player.yt!.pauseVideo();
          const duration = player.yt!.getDuration();
          void fetchYtTitle(videoId).then((meta) => {
            if (!player.metaReported) {
              player.metaReported = true;
              void reportMeta(msg.boothId, player.playId, { ...meta, duration });
            }
          });
        },
        onStateChange: (e: { data: number }) => {
          if (players.get(msg.boothId) !== player) return;
          if (e.data === window.YT!.PlayerState.ENDED && !player.endedReported) {
            player.endedReported = true;
            void fetchNui('trackEnded', { boothId: msg.boothId, playId: player.playId });
          }
        },
      },
    });
  } else {
    const audio = new Audio(msg.track.url);
    audio.crossOrigin = 'anonymous';
    audio.volume = Math.min(1, msg.volume);
    audio.currentTime = msg.position;
    player.audio = audio;
    audio.addEventListener('loadedmetadata', () => {
      if (players.get(msg.boothId) !== player) return;
      player.ready = true;
      if (!player.metaReported && isFinite(audio.duration) && audio.duration > 0) {
        player.metaReported = true;
        void reportMeta(msg.boothId, player.playId, { duration: audio.duration });
      }
    });
    audio.addEventListener('ended', () => {
      if (players.get(msg.boothId) !== player) return;
      if (!player.endedReported) {
        player.endedReported = true;
        void fetchNui('trackEnded', { boothId: msg.boothId, playId: player.playId });
      }
    });
    if (msg.playing) void audio.play().catch(() => undefined);
  }
}

export function handleAudioSync(msg: SyncMsg): void {
  const existing = players.get(msg.boothId);

  if (!existing || existing.playId !== msg.playId) {
    void createPlayer(msg);
    return;
  }
  if (!existing.ready) return;

  if (existing.kind === 'yt' && existing.yt) {
    const yt = existing.yt;
    yt.setVolume(Math.round(msg.volume * 100));
    const state = yt.getPlayerState();
    const PLAYING = window.YT!.PlayerState.PLAYING;
    if (msg.playing) {
      if (state !== PLAYING && state !== window.YT!.PlayerState.ENDED) yt.playVideo();
      if (Math.abs(yt.getCurrentTime() - msg.position) > msg.drift) {
        yt.seekTo(msg.position, true);
      }
    } else if (state === PLAYING) {
      yt.pauseVideo();
      yt.seekTo(msg.position, true);
    }
  } else if (existing.audio) {
    const audio = existing.audio;
    audio.volume = Math.min(1, Math.max(0, msg.volume));
    if (msg.playing) {
      if (audio.paused && !audio.ended) void audio.play().catch(() => undefined);
      if (Math.abs(audio.currentTime - msg.position) > msg.drift) {
        audio.currentTime = msg.position;
      }
    } else if (!audio.paused) {
      audio.pause();
      audio.currentTime = msg.position;
    }
  }
}

export function handleDestroyPlayer(boothId: string): void {
  destroyPlayer(boothId);
}

export function playSfx(url: string, volume: number): void {
  const audio = new Audio(url);
  audio.volume = Math.min(1, Math.max(0, volume));
  void audio.play().catch(() => undefined);
}
