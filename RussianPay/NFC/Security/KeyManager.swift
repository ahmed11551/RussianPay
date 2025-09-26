import Foundation
import Security
import CryptoKit

/// Менеджер ключей для безопасного хранения криптографических ключей
class KeyManager {
    
    // MARK: - Properties
    private let keychain = KeychainWrapper.standard
    private let secureEnclave = SecureEnclaveManager()
    
    // Ключи для различных операций
    private var masterKey: SymmetricKey?
    private var deviceKey: CryptoKit.Curve25519.Signing.PrivateKey?
    private var ephemeralKeys: [String: CryptoKit.Curve25519.KeyAgreement.PrivateKey] = [:]
    
    // MARK: - Initialization
    init() {
        setupKeys()
    }
    
    // MARK: - Key Setup
    
    private func setupKeys() {
        // Инициализация мастер-ключа
        masterKey = loadOrGenerateMasterKey()
        
        // Инициализация ключа устройства
        deviceKey = loadOrGenerateDeviceKey()
        
        // Очистка старых эфемеральных ключей
        cleanupExpiredKeys()
    }
    
    // MARK: - Master Key Management
    
    private func loadOrGenerateMasterKey() -> SymmetricKey {
        let masterKeyId = "com.russianpay.masterkey"
        
        // Попытка загрузить существующий ключ
        if let existingKeyData = keychain.data(forKey: masterKeyId),
           let key = try? SymmetricKey(dataRepresentation: existingKeyData) {
            return key
        }
        
        // Генерация нового ключа
        let newKey = SymmetricKey(size: .bits256)
        
        // Сохранение в Keychain
        do {
            let keyData = newKey.withUnsafeBytes { Data($0) }
            keychain.set(keyData, forKey: masterKeyId)
        } catch {
            print("Ошибка сохранения мастер-ключа: \(error)")
        }
        
        return newKey
    }
    
    // MARK: - Device Key Management
    
    private func loadOrGenerateDeviceKey() -> CryptoKit.Curve25519.Signing.PrivateKey {
        let deviceKeyId = "com.russianpay.devicekey"
        
        // Попытка загрузить существующий ключ
        if let existingKeyData = keychain.data(forKey: deviceKeyId),
           let key = try? CryptoKit.Curve25519.Signing.PrivateKey(dataRepresentation: existingKeyData) {
            return key
        }
        
        // Генерация нового ключа
        let newKey = CryptoKit.Curve25519.Signing.PrivateKey()
        
        // Сохранение в Keychain
        do {
            let keyData = newKey.rawRepresentation
            keychain.set(keyData, forKey: deviceKeyId)
        } catch {
            print("Ошибка сохранения ключа устройства: \(error)")
        }
        
        return newKey
    }
    
    // MARK: - Ephemeral Key Management
    
    /// Генерация эфемерального ключа для сессии
    func generateEphemeralKey(for sessionId: String) -> CryptoKit.Curve25519.KeyAgreement.PrivateKey {
        let key = CryptoKit.Curve25519.KeyAgreement.PrivateKey()
        ephemeralKeys[sessionId] = key
        
        // Установка времени жизни ключа (5 минут)
        DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
            self.ephemeralKeys.removeValue(forKey: sessionId)
        }
        
        return key
    }
    
    /// Получение эфемерального ключа
    func getEphemeralKey(for sessionId: String) -> CryptoKit.Curve25519.KeyAgreement.PrivateKey? {
        return ephemeralKeys[sessionId]
    }
    
    /// Удаление эфемерального ключа
    func removeEphemeralKey(for sessionId: String) {
        ephemeralKeys.removeValue(forKey: sessionId)
    }
    
    // MARK: - Key Derivation
    
    /// Вывод ключа для конкретной операции
    func deriveKey(for operation: KeyOperation, context: String) -> SymmetricKey {
        guard let masterKey = masterKey else {
            fatalError("Мастер-ключ не инициализирован")
        }
        
        let contextData = context.data(using: .utf8) ?? Data()
        let operationData = operation.rawValue.data(using: .utf8) ?? Data()
        
        let salt = contextData + operationData
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: masterKey,
            salt: salt,
            outputByteCount: 32
        )
        
        return derivedKey
    }
    
    // MARK: - Key Operations
    
    enum KeyOperation: String, CaseIterable {
        case payment = "payment"
        case authentication = "authentication"
        case encryption = "encryption"
        case signing = "signing"
        case applePay = "applepay"
        
        var description: String {
            switch self {
            case .payment: return "Платежные операции"
            case .authentication: return "Аутентификация"
            case .encryption: return "Шифрование"
            case .signing: return "Подпись"
            case .applePay: return "Apple Pay"
            }
        }
    }
    
    // MARK: - Secure Storage
    
    /// Безопасное сохранение данных
    func secureStore(_ data: Data, forKey key: String) -> Bool {
        return keychain.set(data, forKey: key)
    }
    
    /// Безопасное получение данных
    func secureRetrieve(forKey key: String) -> Data? {
        return keychain.data(forKey: key)
    }
    
    /// Безопасное удаление данных
    func secureDelete(forKey key: String) -> Bool {
        return keychain.removeObject(forKey: key)
    }
    
    // MARK: - Key Rotation
    
    /// Ротация ключей
    func rotateKeys() {
        // Создание новых ключей
        let newMasterKey = SymmetricKey(size: .bits256)
        let newDeviceKey = CryptoKit.Curve25519.Signing.PrivateKey()
        
        // Перешифрование существующих данных
        reencryptData(with: newMasterKey)
        
        // Обновление ключей
        masterKey = newMasterKey
        deviceKey = newDeviceKey
        
        // Сохранение новых ключей
        saveKeys()
        
        // Очистка эфемеральных ключей
        ephemeralKeys.removeAll()
    }
    
    private func reencryptData(with newKey: SymmetricKey) {
        // Перешифрование всех сохраненных данных с новым ключом
        let keysToReencrypt = [
            "com.russianpay.cards",
            "com.russianpay.transactions",
            "com.russianpay.settings"
        ]
        
        for key in keysToReencrypt {
            if let encryptedData = keychain.data(forKey: key),
               let decryptedData = decryptData(encryptedData, with: masterKey!),
               let reencryptedData = encryptData(decryptedData, with: newKey) {
                keychain.set(reencryptedData, forKey: key)
            }
        }
    }
    
    private func saveKeys() {
        // Сохранение мастер-ключа
        if let masterKey = masterKey {
            let keyData = masterKey.withUnsafeBytes { Data($0) }
            keychain.set(keyData, forKey: "com.russianpay.masterkey")
        }
        
        // Сохранение ключа устройства
        if let deviceKey = deviceKey {
            let keyData = deviceKey.rawRepresentation
            keychain.set(keyData, forKey: "com.russianpay.devicekey")
        }
    }
    
    // MARK: - Cleanup
    
    private func cleanupExpiredKeys() {
        // Удаление ключей старше 24 часов
        let expiredKeys = ephemeralKeys.keys.filter { sessionId in
            // Логика проверки времени жизни ключа
            return false // Упрощенная логика
        }
        
        for key in expiredKeys {
            ephemeralKeys.removeValue(forKey: key)
        }
    }
    
    // MARK: - Cryptographic Operations
    
    private func encryptData(_ data: Data, with key: SymmetricKey) -> Data? {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Ошибка шифрования: \(error)")
            return nil
        }
    }
    
    private func decryptData(_ data: Data, with key: SymmetricKey) -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("Ошибка расшифровки: \(error)")
            return nil
        }
    }
    
    // MARK: - Public Interface
    
    /// Получение мастер-ключа
    var currentMasterKey: SymmetricKey? {
        return masterKey
    }
    
    /// Получение ключа устройства
    var currentDeviceKey: CryptoKit.Curve25519.Signing.PrivateKey? {
        return deviceKey
    }
    
    /// Проверка доступности Secure Enclave
    var isSecureEnclaveAvailable: Bool {
        return secureEnclave.isAvailable
    }
}

// MARK: - KeychainWrapper (упрощенная реализация)
class KeychainWrapper {
    static let standard = KeychainWrapper()
    
    private init() {}
    
    func set(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func data(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        }
        return nil
    }
    
    func removeObject(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}

// MARK: - Secure Enclave Manager
class SecureEnclaveManager {
    var isAvailable: Bool {
        return SecureEnclave.isAvailable
    }
} 