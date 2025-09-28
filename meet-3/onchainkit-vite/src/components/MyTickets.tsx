import { useState, useEffect } from 'react'
import { useAccount } from 'wagmi'
import QRCode from 'qrcode'

interface Ticket {
  tokenId: string
  eventId: string
  eventName: string
  eventDate: number
  venue: string
  imageURI: string
  used: boolean
}

export default function MyTickets() {
  const { address, isConnected } = useAccount()
  const [tickets, setTickets] = useState<Ticket[]>([])
  const [loading, setLoading] = useState(true)
  const [qrCodes, setQrCodes] = useState<{ [key: string]: string }>({})

  useEffect(() => {
    if (!isConnected) {
      setLoading(false)
      return
    }

    // Mock tickets data - nanti akan fetch dari blockchain
    const mockTickets: Ticket[] = [
      {
        tokenId: "12345",
        eventId: "0",
        eventName: "Base Workshop Meet 3",
        eventDate: Date.now() + 86400000,
        venue: "Jakarta, Indonesia",
        imageURI: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400",
        used: false
      },
      {
        tokenId: "12346",
        eventId: "1",
        eventName: "Base Developer Conference",
        eventDate: Date.now() + 172800000,
        venue: "San Francisco, CA",
        imageURI: "https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=400",
        used: true
      }
    ]

    setTimeout(() => {
      setTickets(mockTickets)
      generateQRCodes(mockTickets)
      setLoading(false)
    }, 1000)
  }, [isConnected])

  const generateQRCodes = async (tickets: Ticket[]) => {
    const codes: { [key: string]: string } = {}

    for (const ticket of tickets) {
      try {
        // QR format: tokenId-contractAddress-chainId
        const qrData = `${ticket.tokenId}-0x25b2C2eaf9b8EC899d9cd44Ac74001eF17180F14-84532`
        const qrCodeDataURL = await QRCode.toDataURL(qrData, {
          width: 200,
          margin: 2,
          color: {
            dark: '#000000',
            light: '#FFFFFF'
          }
        })
        codes[ticket.tokenId] = qrCodeDataURL
      } catch (error) {
        console.error('Error generating QR code:', error)
      }
    }

    setQrCodes(codes)
  }

  if (!isConnected) {
    return (
      <div>
        <h2 className="text-xl font-bold text-center mb-6 text-gray-800">My Tickets</h2>
        <div className="bg-white rounded-lg shadow-md p-6 text-center">
          <p className="text-gray-600 text-sm">Please connect your wallet to view your tickets.</p>
        </div>
      </div>
    )
  }

  if (loading) {
    return (
      <div>
        <h2 className="text-xl font-bold text-center mb-6 text-gray-800">My Tickets</h2>
        <div className="text-center py-8 text-gray-600">Loading your tickets...</div>
      </div>
    )
  }

  if (tickets.length === 0) {
    return (
      <div>
        <h2 className="text-xl font-bold text-center mb-6 text-gray-800">My Tickets</h2>
        <div className="bg-white rounded-lg shadow-md p-6 text-center">
          <p className="text-gray-600 mb-4 text-sm">You don't have any tickets yet.</p>
          <a href="/" className="bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors inline-block text-sm">Browse Events</a>
        </div>
      </div>
    )
  }

  return (
    <div>
      <h2 className="text-xl font-bold text-center mb-6 text-gray-800">My Tickets</h2>
      <div className="space-y-4">
        {tickets.map((ticket) => (
          <div key={ticket.tokenId} className={`bg-white rounded-lg shadow-md overflow-hidden ${ticket.used ? 'opacity-70' : ''}`}>
            <div className="relative h-32">
              <img src={ticket.imageURI} alt={ticket.eventName} className="w-full h-full object-cover" />
              {ticket.used && (
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="bg-red-500 text-white px-4 py-1 transform -rotate-12 font-bold text-sm rounded">USED</div>
                </div>
              )}
            </div>

            <div className="p-4">
              <h3 className="text-lg font-semibold mb-2">{ticket.eventName}</h3>
              <div className="space-y-1 text-xs text-gray-700 mb-3">
                <p><span className="font-medium">📅</span> {new Date(ticket.eventDate).toLocaleDateString()}</p>
                <p><span className="font-medium">📍</span> {ticket.venue}</p>
                <p><span className="font-medium">🎫</span> Token ID: #{ticket.tokenId}</p>
                <p className={`font-medium ${
                  ticket.used ? 'text-red-600' : 'text-green-600'
                }`}>
                  {ticket.used ? '❌ Used' : '✅ Valid'}
                </p>
              </div>

              <div className="text-center border-t border-gray-200 pt-3">
                <h4 className="font-medium mb-2 text-sm">Entry QR Code</h4>
                {qrCodes[ticket.tokenId] ? (
                  <img
                    src={qrCodes[ticket.tokenId]}
                    alt="QR Code"
                    className="mx-auto border border-gray-200 rounded w-24 h-24 mb-1"
                  />
                ) : (
                  <div className="text-gray-500 py-4 text-sm">Generating QR...</div>
                )}
                <p className="text-xs text-gray-500">
                  Show this QR code at the venue entrance
                </p>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}