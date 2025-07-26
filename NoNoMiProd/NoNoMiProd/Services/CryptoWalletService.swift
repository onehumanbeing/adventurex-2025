import Foundation
import Security

enum CryptoChain: String, CaseIterable {
    case injective = "inj"
    case bnb = "bnb"
    
    var name: String {
        switch self {
        case .injective: return "Injective"
        case .bnb: return "BNB Chain"
        }
    }
    
    var logoName: String {
        switch self {
        case .injective: return "🔹"
        case .bnb: return "🟡"
        }
    }
    
    var explorerURL: String {
        switch self {
        case .injective: return "https://testnet.explorer.injective.network"
        case .bnb: return "https://testnet.bscscan.com"
        }
    }
    
    var rpcURL: String {
        switch self {
        case .injective: return "https://testnet.sentry.tm.injective.network:443"
        case .bnb: return "https://data-seed-prebsc-1-s1.binance.org:8545"
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
                wallets[chain] = WalletInfo(address: address, privateKey: privateKey, balance: 0.0)
            } else {
                createNewWallet(for: chain)
            }
        }
    }
    
    private func createNewWallet(for chain: CryptoChain) {
        let privateKey = generatePrivateKey()
        let address = generateAddress(from: privateKey, chain: chain)
        
        keychain.set(privateKey, forKey: chain.rawValue + "_private_key")
        wallets[chain] = WalletInfo(address: address, privateKey: privateKey, balance: 0.0)
    }
    
    private func generatePrivateKey() -> String {
        let bytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
    
    private func generateAddress(from privateKey: String, chain: CryptoChain) -> String {
        // 模拟地址生成（实际应用中需要使用正确的加密库）
        let hash = privateKey.hash
        switch chain {
        case .injective:
            return "inj1" + String(format: "%x", abs(hash)).prefix(39)
        case .bnb:
            return "0x" + String(format: "%x", abs(hash)).prefix(40)
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