import { useState, useRef, useEffect } from 'react'
import QrScanner from 'qr-scanner'

interface VerificationResult {
  exists: boolean
  owner: string
  eventId: string
  eventName: string
  used: boolean
  tokenId: string
}

export default function VerifyTicket() {
  const [isScanning, setIsScanning] = useState(false)
  const [verificationResult, setVerificationResult] = useState<VerificationResult | null>(null)
  const [error, setError] = useState<string>('')
  const [manualInput, setManualInput] = useState('')
  const videoRef = useRef<HTMLVideoElement>(null)
  const qrScannerRef = useRef<QrScanner | null>(null)

  useEffect(() => {
    return () => {
      if (qrScannerRef.current) {
        qrScannerRef.current.destroy()
      }
    }
  }, [])

  const startScanning = async () => {
    try {
      setError('')
      setVerificationResult(null)

      if (!videoRef.current) return

      const qrScanner = new QrScanner(
        videoRef.current,
        (result) => {
          handleScanResult(result.data)
        },
        {
          highlightScanRegion: true,
          highlightCodeOutline: true,
        }
      )

      qrScannerRef.current = qrScanner
      await qrScanner.start()
      setIsScanning(true)
    } catch (err) {
      setError('Failed to start camera. Please check permissions or try manual input.')
      console.error('Scanner error:', err)
    }
  }

  const stopScanning = () => {
    if (qrScannerRef.current) {
      qrScannerRef.current.destroy()
      qrScannerRef.current = null
    }
    setIsScanning(false)
  }

  const handleScanResult = (data: string) => {
    console.log('Scanned data:', data)
    verifyTicketData(data)
    stopScanning()
  }

  const verifyTicketData = async (qrData: string) => {
    try {
      // Parse QR data: tokenId-contractAddress-chainId
      const parts = qrData.split('-')
      if (parts.length !== 3) {
        setError('Invalid QR code format')
        return
      }

      const [tokenId, contractAddress, chainId] = parts

      // Mock verification - nanti akan query smart contract
      const mockResult: VerificationResult = {
        exists: true,
        owner: '0x1234...5678',
        eventId: '0',
        eventName: 'Base Workshop Meet 3',
        used: false,
        tokenId: tokenId
      }

      // Simulate random verification results for demo
      const isValid = Math.random() > 0.3 // 70% chance valid
      if (isValid) {
        setVerificationResult(mockResult)
      } else {
        setVerificationResult({
          exists: false,
          owner: '',
          eventId: '',
          eventName: '',
          used: false,
          tokenId: tokenId
        })
      }

    } catch (err) {
      setError('Failed to verify ticket')
      console.error('Verification error:', err)
    }
  }

  const handleManualVerify = () => {
    if (!manualInput.trim()) {
      setError('Please enter a token ID')
      return
    }

    // Mock manual verification
    const mockQrData = `${manualInput}-0x25b2C2eaf9b8EC899d9cd44Ac74001eF17180F14-84532`
    verifyTicketData(mockQrData)
  }

  const handleCheckIn = async () => {
    if (!verificationResult) return

    try {
      // Mock check-in - nanti akan call smart contract
      setVerificationResult({
        ...verificationResult,
        used: true
      })
      alert('Ticket checked in successfully!')
    } catch (err) {
      setError('Failed to check in ticket')
      console.error('Check-in error:', err)
    }
  }

  return (
    <div>
      <h2 className="text-xl font-bold text-center mb-6 text-gray-800">🔍 Verify Ticket</h2>

      <div className="space-y-4 mb-6">
        {/* QR Scanner Section */}
        <div className="bg-white rounded-lg shadow-md p-4">
          <h3 className="text-lg font-semibold mb-3">Scan QR Code</h3>

          {!isScanning ? (
            <div className="text-center">
              <button onClick={startScanning} className="bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 transition-colors text-sm">
                📷 Start Camera
              </button>
            </div>
          ) : (
            <div className="text-center">
              <video ref={videoRef} className="w-full max-w-64 mx-auto rounded-lg mb-3"></video>
              <button onClick={stopScanning} className="bg-gray-600 text-white py-2 px-3 rounded-lg hover:bg-gray-700 transition-colors text-sm">
                Stop Scanning
              </button>
            </div>
          )}
        </div>

        {/* Manual Input Section */}
        <div className="bg-white rounded-lg shadow-md p-4">
          <h3 className="text-lg font-semibold mb-3">Manual Verification</h3>
          <div className="space-y-2">
            <input
              type="text"
              placeholder="Enter Token ID"
              value={manualInput}
              onChange={(e) => setManualInput(e.target.value)}
              className="w-full p-2 border-2 border-gray-300 rounded-lg focus:border-blue-500 focus:outline-none text-sm"
            />
            <button onClick={handleManualVerify} className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 transition-colors text-sm">
              Verify
            </button>
          </div>
        </div>
      </div>

      {/* Error Display */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-3 mb-4">
          <p className="text-red-600 text-sm">❌ {error}</p>
        </div>
      )}

      {/* Verification Result */}
      {verificationResult && (
        <div className={`bg-white rounded-lg shadow-md p-4 mb-4 border-l-4 ${
          verificationResult.exists ? 'border-green-500' : 'border-red-500'
        }`}>
          {verificationResult.exists ? (
            <div>
              <h3 className="text-lg font-semibold text-green-600 mb-3">✅ Valid Ticket</h3>
              <div className="space-y-2 text-sm text-gray-700">
                <p><span className="font-medium">Event:</span> {verificationResult.eventName}</p>
                <p><span className="font-medium">Token ID:</span> #{verificationResult.tokenId}</p>
                <p><span className="font-medium">Owner:</span> {verificationResult.owner}</p>
                <p><span className="font-medium">Status:</span>
                  <span className={`ml-2 font-medium ${
                    verificationResult.used ? 'text-red-600' : 'text-green-600'
                  }`}>
                    {verificationResult.used ? 'Already Used' : 'Not Used'}
                  </span>
                </p>
              </div>

              {!verificationResult.used && (
                <button onClick={handleCheckIn} className="mt-3 bg-green-600 text-white py-2 px-4 rounded-lg hover:bg-green-700 transition-colors text-sm w-full">
                  ✅ Check In
                </button>
              )}
            </div>
          ) : (
            <div>
              <h3 className="text-lg font-semibold text-red-600 mb-2">❌ Invalid Ticket</h3>
              <p className="text-gray-600 text-sm">This ticket does not exist or has been revoked.</p>
            </div>
          )}
        </div>
      )}

      <div className="bg-gray-50 rounded-lg p-4">
        <h4 className="text-base font-semibold mb-2 text-gray-800">How it works:</h4>
        <ul className="space-y-1 text-sm text-gray-600">
          <li className="flex items-start">
            <span className="w-1.5 h-1.5 bg-blue-500 rounded-full mt-1.5 mr-2 flex-shrink-0"></span>
            Scan the QR code from the ticket holder's phone
          </li>
          <li className="flex items-start">
            <span className="w-1.5 h-1.5 bg-blue-500 rounded-full mt-1.5 mr-2 flex-shrink-0"></span>
            Or manually enter the Token ID
          </li>
          <li className="flex items-start">
            <span className="w-1.5 h-1.5 bg-blue-500 rounded-full mt-1.5 mr-2 flex-shrink-0"></span>
            System verifies ownership on the blockchain
          </li>
          <li className="flex items-start">
            <span className="w-1.5 h-1.5 bg-blue-500 rounded-full mt-1.5 mr-2 flex-shrink-0"></span>
            Check in valid tickets to prevent reuse
          </li>
        </ul>
      </div>
    </div>
  )
}