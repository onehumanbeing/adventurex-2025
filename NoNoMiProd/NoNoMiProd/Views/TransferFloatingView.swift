import SwiftUI

struct TransferFloatingView: View {
    let chain: CryptoChain
    @ObservedObject var walletService: CryptoWalletService
    @State private var showTransferDialog = false
    @State private var transferAmount = "1.0"
    @State private var recipientAddress = ""
    @State private var showExplorer = false
    @State private var explorerURL = ""
    
    var body: some View {
        VStack {
            // 悬浮转账按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showTransferDialog = true
                }
                setupDefaultRecipient()
            }) {
                HStack(spacing: 12) {
                    Text(chain.logoName)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Transfer")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(chain.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6), Color.blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                )
            }
            .scaleEffect(showTransferDialog ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: showTransferDialog)
            
            // 转账对话框
            if showTransferDialog {
                VStack(spacing: 16) {
                    // 标题
                    HStack {
                        Text("Transfer \(chain.rawValue.uppercased())")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showTransferDialog = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 当前余额
                    if let wallet = walletService.wallets[chain] {
                        HStack {
                            Text("Balance:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "%.4f %@", wallet.balance, chain.rawValue.uppercased()))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // 金额输入
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Amount")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("1.0", text: $transferAmount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    
                    // 收款地址输入
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recipient Address")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter address", text: $recipientAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.caption)
                    }
                    
                    // 转账按钮
                    Button(action: {
                        performTransfer()
                    }) {
                        HStack {
                            if walletService.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            
                            Text(walletService.isLoading ? "Transferring..." : "Confirm Transfer")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    .disabled(walletService.isLoading || transferAmount.isEmpty || recipientAddress.isEmpty)
                }
                .padding(20)
                .frame(width: 300)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.black.opacity(0.6), Color.gray.opacity(0.3), Color.black.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            // Explorer WebView
            if showExplorer && !explorerURL.isEmpty {
                ExplorerWebView(url: explorerURL, isVisible: $showExplorer)
                    .frame(width: 400, height: 300)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func setupDefaultRecipient() {
        // 设置默认的testnet收款地址
        switch chain {
        case .injective:
            recipientAddress = "inj178e674pxwx34j8mrrhnj2cgtly8j6wwvlws0z3"
        }
    }
    
    private func performTransfer() {
        guard let amount = Double(transferAmount), amount > 0 else { return }
        
        walletService.transfer(amount: amount, to: recipientAddress, chain: chain) { txHash in
            if let txHash = txHash {
                // 转账成功，显示explorer
                explorerURL = walletService.getExplorerURL(txHash: txHash, chain: chain)
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    showTransferDialog = false
                    showExplorer = true
                }
            }
        }
    }
}

struct ExplorerWebView: View {
    let url: String
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("Transaction Successful")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isVisible = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // WebView内容
            WebView(html: generateSuccessHTML())
                .clipShape(RoundedRectangle(cornerRadius: 0))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color.green.opacity(0.6), Color.blue.opacity(0.3), Color.green.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .green.opacity(0.3), radius: 12, x: 0, y: 8)
        )
    }
    
    private func generateSuccessHTML() -> String {
        return """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    text-align: center;
                    padding: 20px;
                    margin: 0;
                    min-height: 200px;
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                }
                .success-icon {
                    font-size: 48px;
                    margin-bottom: 16px;
                }
                .title {
                    font-size: 24px;
                    font-weight: bold;
                    margin-bottom: 8px;
                }
                .subtitle {
                    font-size: 16px;
                    opacity: 0.9;
                    margin-bottom: 20px;
                }
                .link {
                    color: #FFD700;
                    text-decoration: none;
                    font-weight: 500;
                }
            </style>
        </head>
        <body>
            <div class="success-icon">✅</div>
            <div class="title">Transfer Completed!</div>
            <div class="subtitle">Your transaction has been submitted to the blockchain</div>
            <a href="\(url)" class="link" target="_blank">View on Explorer</a>
        </body>
        </html>
        """
    }
}

#Preview {
    TransferFloatingView(chain: .injective, walletService: CryptoWalletService())
} 