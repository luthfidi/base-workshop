import { Wallet, ConnectWallet, WalletDropdown } from '@coinbase/onchainkit/wallet'

export default function WalletConnect() {
  return (
    <Wallet>
      <ConnectWallet />
      <WalletDropdown />
    </Wallet>
  )
}