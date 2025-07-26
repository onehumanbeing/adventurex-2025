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
        .frame(width: 360, height: 180)
        .background(walletBackground)
    }
    
    private var headerSection: some View {
        HStack(spacing: 12) {
            // Logo区域
            ZStack {
                Circle()
                    .fill(goldGradient)
                    .frame(width: 32, height: 32)
                Text(selectedChain.logoName)
                    .font(.title3)
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("INJECTIVE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                    .tracking(1.5)
                
                Text("TESTNET")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .tracking(0.5)
            }
            
            Spacer()
            
            // 状态指示器
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("LIVE")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var walletContentSection: some View {
        VStack(spacing: 12) {
            balanceSection
            addressSection
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var balanceSection: some View {
        HStack(spacing: 16) {
            balanceInfo
            Spacer()
            balanceActions
        }
    }
    
    private var balanceInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(String(format: "%.4f", selectedWallet?.balance ?? 0.0))
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                
                Text("INJ")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            
            Text("≈ $\(String(format: "%.2f", (selectedWallet?.balance ?? 0.0) * 12.34))")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var balanceActions: some View {
        HStack(spacing: 8) {
            ActionButton(icon: "arrow.up", label: "Send") {
                // Send action
            }
            ActionButton(icon: "arrow.down", label: "Receive") {
                // Receive action  
            }
        }
    }
    
    @ViewBuilder
    private var addressSection: some View {
        if let address = selectedWallet?.address {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WALLET ADDRESS")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .tracking(0.5)
                    
                    Text(truncateAddress(address))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .monospaced()
                }
                
                Spacer()
                
                copyButton(for: address)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(goldBorder, lineWidth: 0.5)
                    )
            )
        }
    }
    
    private func copyButton(for address: String) -> some View {
        Button(action: {
            UIPasteboard.general.string = address
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(goldGradient)
                    .frame(width: 28, height: 28)
                
                Image(systemName: "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(.black)
                    .fontWeight(.semibold)
            }
        }
    }
    
    private var walletBackground: some View {
        ZStack {
            blackGoldBackground
            walletBorder
        }
        .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2), radius: 12, x: 0, y: 6)
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }
    
    private var walletBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(goldBorder, lineWidth: 1.5)
    }
    
    private var blackGoldBackground: some View {
        ZStack {
            // 基础黑色背景
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
            
            // 金色光泽覆盖
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.1),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
            
            // 磨砂效果
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .opacity(0.3)
        }
    }
    
    private var goldGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.84, blue: 0.0),
                Color(red: 0.85, green: 0.68, blue: 0.0),
                Color(red: 1.0, green: 0.84, blue: 0.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var goldBorder: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8),
                Color(red: 0.85, green: 0.68, blue: 0.0).opacity(0.4),
                Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.8)
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

struct ActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                        .fontWeight(.semibold)
                }
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .fontWeight(.medium)
            }
        }
    }
}

#Preview {
    WalletView(walletService: CryptoWalletService())
} 