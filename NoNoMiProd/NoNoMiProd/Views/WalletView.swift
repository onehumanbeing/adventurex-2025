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
            tabSection
            walletContentSection
        }
        .frame(width: 160, height: 120)
        .background(walletBackground)
    }
    
    private var tabSection: some View {
        HStack(spacing: 0) {
            ForEach(CryptoChain.allCases, id: \.self) { chain in
                tabButton(for: chain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func tabButton(for chain: CryptoChain) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                walletService.selectedChain = chain
            }
        }) {
            Text(chain.rawValue.uppercased())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(selectedChain == chain ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(tabButtonBackground(for: chain))
        }
    }
    
    private func tabButtonBackground(for chain: CryptoChain) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(selectedChain == chain ? Color.blue : Color.clear)
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