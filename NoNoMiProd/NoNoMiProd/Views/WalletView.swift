import SwiftUI

struct WalletView: View {
    @ObservedObject var walletService: CryptoWalletService
    
    private var selectedChain: CryptoChain {
        walletService.selectedChain
    }
    
    private var selectedWallet: WalletInfo? {
        walletService.wallets[selectedChain]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            walletContentSection
        }
        .frame(width: 320, height: 240)
        .background(walletBackground)
    }
    
    private var headerSection: some View {
        HStack {
            Text(selectedChain.logoName)
                .font(.title2)
            Text("INJECTIVE TESTNET")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.gradient)
        )
    }
    
    private var walletContentSection: some View {
        VStack(spacing: 8) {
            balanceSection
            addressSection
        }
        .padding(12)
    }
    
    private var balanceSection: some View {
        HStack(spacing: 8) {
            Text(selectedChain.logoName)
                .font(.title2)
            
            balanceInfo
            
            Spacer()
        }
    }
    
    private var balanceInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(format: "%.4f", selectedWallet?.balance ?? 0.0))
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(selectedChain.rawValue.uppercased())
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var addressSection: some View {
        if let address = selectedWallet?.address {
            HStack {
                Text(truncateAddress(address))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospaced()
                
                Spacer()
                
                copyButton(for: address)
            }
        }
    }
    
    private func copyButton(for address: String) -> some View {
        Button(action: {
            UIPasteboard.general.string = address
        }) {
            Image(systemName: "doc.on.doc")
                .font(.caption2)
                .foregroundColor(.blue)
        }
    }
    
    private var walletBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay(walletBorder)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var walletBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(borderGradient, lineWidth: 1.5)
    }
    
    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.black.opacity(0.6),
                Color.gray.opacity(0.3),
                Color.black.opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func truncateAddress(_ address: String) -> String {
        guard address.count > 10 else { return address }
        let start = String(address.prefix(6))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
}



#Preview {
    WalletView(walletService: CryptoWalletService())
} 