import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  base: './',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    assetsDir: 'assets',
    // 既定 500kB のままだと警告が出るが、分割後は最大チャンクも 500kB 未満に収まる想定。
    // 念のため 600 まで上げて分割成功時のノイズを抑える。
    chunkSizeWarningLimit: 600,
    rollupOptions: {
      output: {
        entryFileNames: 'assets/[name].js',
        // ヘルプ記事チャンクなど manualChunks 由来は内容ハッシュを付けてキャッシュ衝突を避ける
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: 'assets/[name].[ext]',
        manualChunks(id) {
          // ヘルプ記事の Markdown は import.meta.glob で eager 取り込みされるため、
          // 専用チャンクに切り出して index.js から外す。
          if (id.includes('/src/help/ja/articles/')) {
            return 'help-articles-ja'
          }
          if (id.includes('/src/help/en/articles/')) {
            return 'help-articles-en'
          }
          if (id.includes('/src/help/') && id.endsWith('.json')) {
            // index.json / reverse_index.json / context_map.json
            return 'help-meta'
          }

          // 大きめのサードパーティを役割別に分割
          if (id.includes('/node_modules/')) {
            if (id.includes('/marked/') || id.includes('/dompurify/')) {
              return 'vendor-markdown'
            }
            if (id.includes('/fuse.js/')) {
              return 'vendor-search'
            }
            if (id.includes('/vue-i18n/') || id.includes('/@intlify/')) {
              return 'vendor-i18n'
            }
            if (id.includes('/vue-router/')) {
              return 'vendor-router'
            }
            if (id.includes('/pinia/')) {
              return 'vendor-pinia'
            }
            if (id.includes('/@headlessui/') || id.includes('/@heroicons/')) {
              return 'vendor-headlessui'
            }
            if (id.includes('/@vueuse/')) {
              return 'vendor-vueuse'
            }
            // Vue 本体・その他は `vendor` にまとめる
            return 'vendor'
          }
        },
      },
    },
  },
})
