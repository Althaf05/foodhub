import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

const target = (port) => ({
  target: `http://127.0.0.1:${port}`,
  changeOrigin: true,
})

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api/auth': target(8081),
      '/api/menu': target(8082),
      '/api/orders': target(8083),
    },
  },
})
