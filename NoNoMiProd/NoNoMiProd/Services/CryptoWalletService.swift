import Foundation
import Security

enum CryptoChain: String, CaseIterable {
    case injective = "inj"
    
    var name: String {
        switch self {
        case .injective: return "Injective"
        }
    }
    
    var logoName: String {
        switch self {
        case .injective: return "🔹"
        }
    }
    
    var explorerURL: String {
        switch self {
        case .injective: return "https://testnet.explorer.injective.network"
        }
    }
    
    var rpcURL: String {
        switch self {
        case .injective: return "https://testnet.sentry.tm.injective.network:443"
        }
    }
}

struct WalletInfo {
    let address: String
    let privateKey: String
    let balance: Double
}

class CryptoWalletService: ObservableObject {
    @Published var wallets: [CryptoChain: WalletInfo] = [:]
    @Published var isLoading = false
    @Published var selectedChain: CryptoChain = .injective
    
    private let keychain = Keychain()
    
    init() {
        loadOrCreateWallets()
        startBalancePolling()
    }
    
    private func loadOrCreateWallets() {
        for chain in CryptoChain.allCases {
            if let privateKey = keychain.get(chain.rawValue + "_private_key") {
                let address = generateAddress(from: privateKey, chain: chain)
                print("💰 Loaded existing \(chain.rawValue.uppercased()) wallet address: \(address)")
                wallets[chain] = WalletInfo(address: address, privateKey: privateKey, balance: 0.0)
            } else {
                createNewWallet(for: chain)
            }
        }
    }
    
    private func createNewWallet(for chain: CryptoChain) {
        let privateKey: String
        let address: String
        
        switch chain {
        case .injective:
            // 使用真实的Injective testnet私钥和地址
            privateKey = "b62500f54a1935148e905238643b4a8c98a594c85c162e0a0b326987dca9de48"
            address = "inj1gqe596gtdeevgs8pydq7waccq94fnpd6ktvnwh"
            print("🔥 使用真实的 INJECTIVE TESTNET 钱包地址: \(address)")
        }
        
        keychain.set(privateKey, forKey: chain.rawValue + "_private_key")
        wallets[chain] = WalletInfo(address: address, privateKey: privateKey, balance: 0.0)
    }
    

    
    private func generateAddress(from privateKey: String, chain: CryptoChain) -> String {
        // 使用真实的预设地址和私钥（Injective Testnet）
        switch chain {
        case .injective:
            // 使用真实的Injective testnet地址
            return "inj1gqe596gtdeevgs8pydq7waccq94fnpd6ktvnwh"
        }
    }
    
    private func startBalancePolling() {
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            self.updateBalances()
        }
        updateBalances()
    }
    
    private func updateBalances() {
        for chain in CryptoChain.allCases {
            fetchBalance(for: chain)
        }
    }
    
    private func fetchBalance(for chain: CryptoChain) {
        guard let wallet = wallets[chain] else { return }
        
        // 模拟余额查询（实际应用中需要调用真实的RPC）
        DispatchQueue.global().asyncAfter(deadline: .now() + Double.random(in: 1.0...3.0)) {
            let simulatedBalance = Double.random(in: 0.1...10.0)
            
            DispatchQueue.main.async {
                self.wallets[chain] = WalletInfo(
                    address: wallet.address,
                    privateKey: wallet.privateKey,
                    balance: simulatedBalance
                )
            }
        }
    }
    
    func transfer(amount: Double, to recipient: String, chain: CryptoChain, completion: @escaping (String?) -> Void) {
        guard let wallet = wallets[chain] else {
            completion(nil)
            return
        }
        
        isLoading = true
        
        // 模拟区块链交易（实际应用中需要使用真实的区块链库）
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            let txHash = self.generateTransactionHash()
            
            DispatchQueue.main.async {
                self.isLoading = false
                // 更新余额
                self.wallets[chain] = WalletInfo(
                    address: wallet.address,
                    privateKey: wallet.privateKey,
                    balance: wallet.balance - amount
                )
                completion(txHash)
            }
        }
    }
    
    private func generateTransactionHash() -> String {
        let chars = "0123456789abcdef"
        return String((0..<64).map { _ in chars.randomElement()! })
    }
    
    func getExplorerURL(txHash: String, chain: CryptoChain) -> String {
        return "\(chain.explorerURL)/tx/\(txHash)"
    }
}

// 简单的Keychain包装器
class Keychain {
    func set(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
} 