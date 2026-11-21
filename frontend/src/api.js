const json = { 'Content-Type': 'application/json' }

async function call(path, options = {}) {
  const res = await fetch(path, options)
  const text = await res.text()
  const data = text ? JSON.parse(text) : null
  if (!res.ok) throw new Error((data && data.error) || (res.status === 400 ? 'Please fill in all fields (password needs 8+ characters)' : `Request failed (${res.status})`))
  return data
}

export const register = (email, password, name) =>
  call('/api/auth/register', { method: 'POST', headers: json, body: JSON.stringify({ email, password, name }) })

export const login = (email, password) =>
  call('/api/auth/login', { method: 'POST', headers: json, body: JSON.stringify({ email, password }) })

export const getMenu = () => call('/api/menu')

export const placeOrder = (token, items) =>
  call('/api/orders', {
    method: 'POST',
    headers: { ...json, Authorization: `Bearer ${token}` },
    body: JSON.stringify({ items }),
  })

export const getOrders = (token) =>
  call('/api/orders', { headers: { Authorization: `Bearer ${token}` } })
