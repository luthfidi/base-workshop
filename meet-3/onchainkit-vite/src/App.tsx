import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom'
import { OnchainKitProvider } from '@coinbase/onchainkit'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { WagmiProvider } from 'wagmi'
import { base } from 'viem/chains'
import { http, createConfig } from 'wagmi'
import { coinbaseWallet, metaMask } from 'wagmi/connectors'
import EventsList from './components/EventsList'
import EventDetail from './components/EventDetail'
import MyTickets from './components/MyTickets'
import VerifyTicket from './components/VerifyTicket'
import WalletConnect from './components/WalletConnect'
import './App.css'

const config = createConfig({
  chains: [base],
  connectors: [
    coinbaseWallet(),
    metaMask(),
  ],
  transports: {
    [base.id]: http(),
  },
})

const queryClient = new QueryClient()

function App() {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <OnchainKitProvider
          apiKey={import.meta.env.VITE_PUBLIC_ONCHAINKIT_API_KEY}
          chain={base}
        >
      <Router>
        <div className="min-h-screen bg-gray-100 flex justify-center">
          {/* Mobile Container - Fixed width on desktop */}
          <div className="w-full max-w-sm mx-auto bg-white min-h-screen flex flex-col shadow-xl md:shadow-2xl">
            <header className="bg-gradient-to-r from-blue-600 to-blue-700 text-white">
              <div className="px-4 py-3">
                <div className="flex justify-between items-center mb-3">
                  <h1 className="text-lg font-bold">🎫 NFT Ticketing</h1>
                  <div className="scale-75">
                    <WalletConnect />
                  </div>
                </div>
                <nav className="flex justify-center space-x-4">
                  <Link to="/" className="hover:bg-white/10 px-3 py-2 rounded-md transition-colors text-sm font-medium">Events</Link>
                  <Link to="/my-tickets" className="hover:bg-white/10 px-3 py-2 rounded-md transition-colors text-sm font-medium">My Tickets</Link>
                  <Link to="/verify" className="hover:bg-white/10 px-3 py-2 rounded-md transition-colors text-sm font-medium">Verify</Link>
                </nav>
              </div>
            </header>

            <main className="flex-1 bg-gray-50 p-4 overflow-y-auto">
              <Routes>
                <Route path="/" element={<EventsList />} />
                <Route path="/event/:id" element={<EventDetail />} />
                <Route path="/my-tickets" element={<MyTickets />} />
                <Route path="/verify" element={<VerifyTicket />} />
              </Routes>
            </main>
          </div>
        </div>
      </Router>
    </OnchainKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  )
}

export default App
