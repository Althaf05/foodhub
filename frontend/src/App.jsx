import { useEffect, useState } from 'react'
import { getMenu, getOrders, login, placeOrder, register } from './api'
import './App.css'

export default function App() {
  const [token, setToken] = useState(null)
  const [menu, setMenu] = useState([])
  const [cart, setCart] = useState({})
  const [orders, setOrders] = useState([])
  const [form, setForm] = useState({ name: '', email: '', password: '' })
  const [message, setMessage] = useState('')

  useEffect(() => {
    getMenu().then(setMenu).catch((e) => setMessage(e.message))
  }, [])

  const run = async (fn, okMessage) => {
    try {
      await fn()
      setMessage(okMessage || '')
    } catch (e) {
      setMessage(e.message)
    }
  }

  const refreshOrders = async (t) => setOrders(await getOrders(t))

  const onRegister = () =>
    run(() => register(form.email, form.password, form.name), 'Registered. Now log in.')

  const onLogin = () =>
    run(async () => {
      const res = await login(form.email, form.password)
      setToken(res.token)
      await refreshOrders(res.token)
    }, 'Logged in.')

  const onOrder = () =>
    run(async () => {
      const items = menu
        .filter((m) => cart[m.id] > 0)
        .map((m) => ({ menuItemId: m.id, name: m.name, price: m.price, quantity: cart[m.id] }))
      if (items.length === 0) throw new Error('Cart is empty')
      await placeOrder(token, items)
      setCart({})
      await refreshOrders(token)
    }, 'Order placed.')

  const add = (id) => setCart({ ...cart, [id]: (cart[id] || 0) + 1 })
  const field = (key) => ({
    value: form[key],
    onChange: (e) => setForm({ ...form, [key]: e.target.value }),
  })

  return (
    <div className="app">
      <h1>FoodHub</h1>
      {message && <p className="message">{message}</p>}

      {!token ? (
        <section>
          <h2>Register / Login</h2>
          <input placeholder="Name (register only)" {...field('name')} />
          <input placeholder="Email" {...field('email')} />
          <input placeholder="Password (min 8)" type="password" {...field('password')} />
          <div>
            <button onClick={onRegister}>Register</button>
            <button onClick={onLogin}>Login</button>
          </div>
        </section>
      ) : (
        <p>
          You are logged in. <button onClick={() => { setToken(null); setOrders([]) }}>Logout</button>
        </p>
      )}

      <section>
        <h2>Menu</h2>
        {menu.length === 0 && <p>No menu items yet.</p>}
        {menu.map((m) => (
          <div key={m.id} className="row">
            <span>{m.name} ({m.category}) - Rs {m.price}</span>
            <span>
              {cart[m.id] ? `x${cart[m.id]} ` : ''}
              <button onClick={() => add(m.id)}>Add</button>
            </span>
          </div>
        ))}
        {token && <button onClick={onOrder}>Place order</button>}
      </section>

      {token && (
        <section>
          <h2>My orders</h2>
          {orders.length === 0 && <p>No orders yet.</p>}
          {orders.map((o) => (
            <div key={o.id} className="row">
              <span>{o.items.map((i) => `${i.name} x${i.quantity}`).join(', ')}</span>
              <span>Rs {o.total} - {o.status}</span>
            </div>
          ))}
        </section>
      )}
    </div>
  )
}
