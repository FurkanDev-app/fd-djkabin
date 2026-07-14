import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// base './' -> FiveM NUI dosyaları relative path ile yükler
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
  },
});
