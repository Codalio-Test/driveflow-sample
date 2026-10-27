import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import path from 'node:path';

// The browser only ever talks to one public origin (this Vite server) — every
// API call goes to the same-origin `/api/*` proxy below. The target is derived
// from API_PORT (never hardcoded to a fixed port) so the host runtime can point
// the client at whichever port the Rails API was started on.
const apiPort = process.env.API_PORT || process.env.VITE_API_PORT || '3001';
const apiTarget = process.env.API_ORIGIN || `http://127.0.0.1:${apiPort}`;
const previewPort = Number(process.env.CLIENT_PORT || process.env.PORT || 5173);

export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
  server: {
      allowedHosts: ['.prod-runtime.all-hands.dev'],
    host: '0.0.0.0',
    port: previewPort,
    proxy: {
      '/api': { target: apiTarget, changeOrigin: true },
    },
  },
  preview: {
    host: '0.0.0.0',
    port: previewPort,
    proxy: {
      '/api': { target: apiTarget, changeOrigin: true },
    },
  },
});
