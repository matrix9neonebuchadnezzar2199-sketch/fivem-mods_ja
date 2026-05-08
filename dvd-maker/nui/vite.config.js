import path from 'path';
import { fileURLToPath } from 'url';
import { defineConfig } from 'vite';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  root: __dirname,
  base: './',
  build: {
    outDir: path.resolve(__dirname, '../html'),
    emptyOutDir: false,
    minify: 'esbuild',
    sourcemap: false,
  },
});
