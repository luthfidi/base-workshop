import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'

interface Event {
  id: number
  name: string
  description: string
  price: string
  maxSupply: number
  sold: number
  active: boolean
  imageURI: string
  eventDate: number
  venue: string
}

export default function EventsList() {
  const [events, setEvents] = useState<Event[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Mock data untuk sekarang - nanti akan fetch dari smart contract
    const mockEvents: Event[] = [
      {
        id: 0,
        name: "Base Workshop Meet 3",
        description: "Learn about NFT Ticketing with OnchainKit",
        price: "0.001",
        maxSupply: 100,
        sold: 25,
        active: true,
        imageURI: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400",
        eventDate: Date.now() + 86400000, // Tomorrow
        venue: "Jakarta, Indonesia"
      },
      {
        id: 1,
        name: "Base Developer Conference",
        description: "Annual developer conference for Base ecosystem",
        price: "0.005",
        maxSupply: 500,
        sold: 150,
        active: true,
        imageURI: "https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=400",
        eventDate: Date.now() + 172800000, // Day after tomorrow
        venue: "San Francisco, CA"
      }
    ]

    setTimeout(() => {
      setEvents(mockEvents)
      setLoading(false)
    }, 1000)
  }, [])

  if (loading) {
    return <div className="text-center py-8 text-gray-600">Loading events...</div>
  }

  return (
    <div>
      <h2 className="text-xl font-bold text-center mb-6 text-gray-800">Upcoming Events</h2>
      <div className="space-y-4">
        {events.map((event) => (
          <div key={event.id} className="bg-white rounded-lg shadow-md overflow-hidden">
            <img
              src={event.imageURI}
              alt={event.name}
              className="w-full h-40 object-cover"
            />
            <div className="p-4">
              <h3 className="text-lg font-bold mb-2 text-gray-800">{event.name}</h3>
              <p className="text-gray-600 mb-3 text-sm leading-relaxed">{event.description}</p>

              <div className="space-y-1 mb-4">
                <div className="flex justify-between items-center py-1">
                  <span className="text-xs font-medium text-gray-500">📍 {event.venue}</span>
                </div>
                <div className="flex justify-between items-center py-1">
                  <span className="text-xs text-gray-600">📅 {new Date(event.eventDate).toLocaleDateString()}</span>
                  <span className="text-sm font-bold text-blue-600">{event.price} ETH</span>
                </div>
                <div className="flex justify-between items-center py-1">
                  <span className="text-xs text-gray-500">🎫 {event.maxSupply - event.sold} / {event.maxSupply} available</span>
                </div>
              </div>

              {event.active && event.sold < event.maxSupply ? (
                <Link
                  to={`/event/${event.id}`}
                  className="block w-full bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors text-center text-sm font-medium"
                >
                  Buy Ticket
                </Link>
              ) : (
                <button className="block w-full bg-gray-300 text-gray-500 py-2 px-4 rounded-lg cursor-not-allowed text-sm font-medium" disabled>
                  {event.sold >= event.maxSupply ? 'Sold Out' : 'Event Inactive'}
                </button>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}