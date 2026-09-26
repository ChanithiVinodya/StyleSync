import axios from 'axios'

// SHARED FILE - do not hardcode module-specific logic here.
// Add module-specific API calls in your own module's folder
// (e.g. src/modules/designers/api.ts) using this client.
export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:5000/api',
  headers: {
    'Content-Type': 'application/json',
  },
})

apiClient.interceptors.request.use((config) => {
  // Use the same key as authStorage
  const token = localStorage.getItem('stylesync_jwt_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})
