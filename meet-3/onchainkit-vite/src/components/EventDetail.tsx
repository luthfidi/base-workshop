import { useParams } from 'react-router-dom'
import { NFTMintCard } from '@coinbase/onchainkit/nft'
import {
  NFTCreator,
  NFTCollectionTitle,
  NFTAssetCost,
  NFTMintButton
} from '@coinbase/onchainkit/nft/mint'
import { NFTMedia } from '@coinbase/onchainkit/nft/view'

export default function EventDetail() {
  const { id } = useParams<{ id: string }>()

  // Mock event data - nanti akan fetch dari smart contract
  const event = {
    id: parseInt(id || '0'),
    name: "Base Workshop Meet 3",
    description: "Learn about NFT Ticketing with OnchainKit. This workshop will cover building decentralized applications on Base network using OnchainKit components.",
    price: "0.001",
    maxSupply: 100,
    sold: 25,
    active: true,
    imageURI: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800",
    eventDate: Date.now() + 86400000,
    venue: "Jakarta, Indonesia",
    contractAddress: "0x25b2C2eaf9b8EC899d9cd44Ac74001eF17180F14"
  }

  const handleMintSuccess = (transactionReceipt: any) => {
    console.log('Ticket minted successfully:', transactionReceipt)
    // Redirect to my-tickets or show success message
    alert('Ticket purchased successfully! Check your wallet.')
  }

  const handleMintError = (error: any) => {
    console.error('Mint error:', error)
    alert('Failed to purchase ticket. Please try again.')
  }

  return (
    <div>
      <div className="bg-white rounded-lg shadow-md overflow-hidden mb-4">
        <img
          src={event.imageURI}
          alt={event.name}
          className="w-full h-48 object-cover"
        />
        <div className="p-4">
          <h1 className="text-lg font-bold mb-2 text-gray-800">{event.name}</h1>
          <p className="text-gray-600 mb-4 text-sm leading-relaxed">{event.description}</p>

          <div className="grid grid-cols-2 gap-2 mb-4">
            <div className="bg-gray-50 p-2 rounded">
              <div className="text-xs text-gray-500 mb-1">📅 Date</div>
              <div className="text-sm font-medium text-gray-800">{new Date(event.eventDate).toLocaleDateString()}</div>
            </div>
            <div className="bg-gray-50 p-2 rounded">
              <div className="text-xs text-gray-500 mb-1">📍 Venue</div>
              <div className="text-sm font-medium text-gray-800">{event.venue}</div>
            </div>
            <div className="bg-gray-50 p-2 rounded">
              <div className="text-xs text-gray-500 mb-1">💰 Price</div>
              <div className="text-sm font-bold text-blue-600">{event.price} ETH</div>
            </div>
            <div className="bg-gray-50 p-2 rounded">
              <div className="text-xs text-gray-500 mb-1">🎫 Available</div>
              <div className="text-sm font-medium text-gray-800">{event.maxSupply - event.sold} / {event.maxSupply}</div>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-md p-4 text-center">
        <h2 className="text-lg font-bold mb-2 text-gray-800">Purchase Your Ticket</h2>
        <p className="text-gray-600 mb-4 text-sm">Your ticket will be minted as an NFT on the Base network.</p>

        {event.contractAddress !== "0x0000000000000000000000000000000000000000" ? (
          <NFTMintCard
            contractAddress={event.contractAddress}
            isSponsored={true}
            onSuccess={handleMintSuccess}
            onError={handleMintError}
          >
            <NFTMedia />
            <NFTCollectionTitle />
            <NFTAssetCost />
            <NFTMintButton />
          </NFTMintCard>
        ) : (
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
            <p className="text-yellow-800 mb-2 text-sm">🚧 Contract not deployed yet. Coming soon!</p>
            <button className="bg-gray-300 text-gray-500 py-2 px-4 rounded-lg cursor-not-allowed text-sm" disabled>
              Purchase Ticket
            </button>
          </div>
        )}
      </div>
    </div>
  )
}