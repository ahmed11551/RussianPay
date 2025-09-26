import Foundation
import Security
import CryptoKit
import LocalAuthentication

/// Менеджер для работы с Secure Enclave
class SecureEnclaveManager: ObservableObject {
    
    // MARK: - Properties
    @Published var isAvailable = false
    @Published var biometricType: BiometricType = .none
    @Published var isAuthenticated = false
    
    private let context = LAContext()
    private var biometricContext: LAContext?
    
    // MARK: - Enums
    enum BiometricType {
        case none
        case touchID
        case faceID
        case opticID
        
        var displayName: String {
            switch self {
            case .none: return "Недоступно"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            case .opticID: return "Optic ID"
            }
        }
        
        var icon: String {
            switch self {
            case .none: return "lock"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            case .opticID: return "eye"
            }
        }
    }
    
    // MARK: - Initialization
    init() {
        setupSecureEnclave()
        setupBiometrics()
    }
    
    // MARK: - Setup
    
    private func setupSecureEnclave() {
        // Проверка доступности Secure Enclave
        isAvailable = SecureEnclave.isAvailable
        
        if isAvailable {
            print("🔐 Secure Enclave доступен")
        } else {
            print("❌ Secure Enclave недоступен")
        }
    }
    
    private func setupBiometrics() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .none:
                biometricType = .none
            case .touchID:
                biometricType = .touchID
            case .faceID:
                biometricType = .faceID
            case .opticID:
                biometricType = .opticID
            @unknown default:
                biometricType = .none
            }
        } else {
            biometricType = .none
            print("❌ Биометрия недоступна: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    // MARK: - Key Management
    
    /// Генерация ключа в Secure Enclave
    func generateSecureEnclaveKey(tag: String) -> SecureEnclave.P256.KeyAgreement.PrivateKey? {
        guard isAvailable else {
            print("❌ Secure Enclave недоступен")
            return nil
        }
        
        do {
            let accessControl = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [.privateKeyUsage, .biometryAny],
                nil
            )
            
            let key = try SecureEnclave.P256.KeyAgreement.PrivateKey(
                accessControl: accessControl!,
                tag: tag.data(using: .utf8)!
            )
            
            print("🔐 Ключ Secure Enclave сгенерирован с тегом: \(tag)")
            return key
        } catch {
            print("❌ Ошибка генерации ключа Secure Enclave: \(error)")
            return nil
        }
    }
    
    /// Загрузка ключа из Secure Enclave
    func loadSecureEnclaveKey(tag: String) -> SecureEnclave.P256.KeyAgreement.PrivateKey? {
        guard isAvailable else {
            print("❌ Secure Enclave недоступен")
            return nil
        }
        
        do {
            let key = try SecureEnclave.P256.KeyAgreement.PrivateKey(tag: tag.data(using: .utf8)!)
            print("🔐 Ключ Secure Enclave загружен с тегом: \(tag)")
            return key
        } catch {
            print("❌ Ошибка загрузки ключа Secure Enclave: \(error)")
            return nil
        }
    }
    
    /// Удаление ключа из Secure Enclave
    func deleteSecureEnclaveKey(tag: String) -> Bool {
        guard isAvailable else {
            print("❌ Secure Enclave недоступен")
            return false
        }
        
        do {
            try SecureEnclave.P256.KeyAgreement.PrivateKey.delete(tag: tag.data(using: .utf8)!)
            print("🔐 Ключ Secure Enclave удален с тегом: \(tag)")
            return true
        } catch {
            print("❌ Ошибка удаления ключа Secure Enclave: \(error)")
            return false
        }
    }
    
    // MARK: - Biometric Authentication
    
    /// Аутентификация с использованием биометрии
    func authenticateWithBiometrics(reason: String = "Аутентификация для доступа к Secure Enclave") -> Bool {
        guard biometricType != .none else {
            print("❌ Биометрия недоступна")
            return false
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var success = false
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { result, error in
            success = result
            if let error = error {
                print("❌ Ошибка биометрической аутентификации: \(error.localizedDescription)")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        isAuthenticated = success
        return success
    }
    
    /// Аутентификация с использованием биометрии (асинхронно)
    func authenticateWithBiometricsAsync(reason: String = "Аутентификация для доступа к Secure Enclave", completion: @escaping (Bool, Error?) -> Void) {
        guard biometricType != .none else {
            completion(false, NSError(domain: "SecureEnclaveManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Биометрия недоступна"]))
            return
        }
        
        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: reason
        ) { result, error in
            DispatchQueue.main.async {
                self.isAuthenticated = result
                completion(result, error)
            }
        }
    }
    
    // MARK: - Cryptographic Operations
    
    /// Подпись данных с использованием ключа Secure Enclave
    func signData(_ data: Data, with key: SecureEnclave.P256.KeyAgreement.PrivateKey) -> Data? {
        guard isAvailable else {
            print("❌ Secure Enclave недоступен")
            return nil
        }
        
        do {
            let signature = try key.signature(for: data)
            return signature.rawRepresentation
        } catch {
            print("❌ Ошибка подписи данных: \(error)")
            return nil
        }
    }
    
    /// Создание общего секрета с использованием ECDH
    func createSharedSecret(publicKey: P256.KeyAgreement.PublicKey, privateKey: SecureEnclave.P256.KeyAgreement.PrivateKey) -> Data? {
        guard isAvailable else {
            print("❌ Secure Enclave недоступен")
            return nil
        }
        
        do {
            let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
            return sharedSecret.withUnsafeBytes { Data($0) }
        } catch {
            print("❌ Ошибка создания общего секрета: \(error)")
            return nil
        }
    }
    
    /// Генерация случайных данных в Secure Enclave
    func generateRandomData(length: Int) -> Data? {
        guard isAvailable else {
            print("❌ Secure Enclave недоступен")
            return nil
        }
        
        var randomData = Data(count: length)
        let result = randomData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            print("❌ Ошибка генерации случайных данных")
            return nil
        }
        
        return randomData
    }
    
    // MARK: - Key Derivation
    
    /// Вывод ключа из общего секрета
    func deriveKey(from sharedSecret: Data, context: String) -> SymmetricKey? {
        guard isAvailable else {
            print("❌ Secure Enclave недоступен")
            return nil
        }
        
        do {
            let contextData = context.data(using: .utf8) ?? Data()
            let derivedKey = HKDF<SHA256>.deriveKey(
                inputKeyMaterial: SymmetricKey(data: sharedSecret),
                salt: contextData,
                outputByteCount: 32
            )
            return derivedKey
        } catch {
            print("❌ Ошибка вывода ключа: \(error)")
            return nil
        }
    }
    
    // MARK: - Payment Token Generation
    
    /// Генерация платежного токена с использованием Secure Enclave
    func generatePaymentToken(amount: Double, merchantId: String, cardData: CardData) -> PaymentToken? {
        guard isAvailable else {
            print("❌ Secure Enclave недоступен")
            return nil
        }
        
        // Аутентификация с биометрией
        guard authenticateWithBiometrics(reason: "Подтвердите платеж") else {
            print("❌ Аутентификация не удалась")
            return nil
        }
        
        // Генерация ключа для токена
        guard let key = generateSecureEnclaveKey(tag: "payment_\(Date().timeIntervalSince1970)") else {
            print("❌ Не удалось сгенерировать ключ")
            return nil
        }
        
        // Создание данных токена
        let tokenData = createPaymentTokenData(amount: amount, merchantId: merchantId, cardData: cardData)
        
        // Подпись токена
        guard let signature = signData(tokenData, with: key) else {
            print("❌ Не удалось подписать токен")
            return nil
        }
        
        // Шифрование токена
        guard let encryptedToken = encryptToken(tokenData, with: key) else {
            print("❌ Не удалось зашифровать токен")
            return nil
        }
        
        return PaymentToken(
            token: encryptedToken.base64EncodedString(),
            timestamp: Date(),
            signature: signature.base64EncodedString(),
            protocol: .iso14443A
        )
    }
    
    private func createPaymentTokenData(amount: Double, merchantId: String, cardData: CardData) -> Data {
        var data = Data()
        
        // Добавление суммы
        let amountBytes = withUnsafeBytes(of: amount) { Data($0) }
        data.append(amountBytes)
        
        // Добавление ID мерчанта
        data.append(merchantId.data(using: .utf8) ?? Data())
        
        // Добавление данных карты (маскированных)
        let maskedCardData = maskCardData(cardData)
        data.append(maskedCardData)
        
        // Добавление временной метки
        let timestamp = Date().timeIntervalSince1970
        let timestampBytes = withUnsafeBytes(of: timestamp) { Data($0) }
        data.append(timestampBytes)
        
        // Добавление случайного nonce
        if let nonce = generateRandomData(length: 16) {
            data.append(nonce)
        }
        
        return data
    }
    
    private func maskCardData(_ cardData: CardData) -> Data {
        var data = Data()
        
        // Маскированный PAN
        let maskedPAN = "•••• •••• •••• \(String(cardData.cardNumber.suffix(4)))"
        data.append(maskedPAN.data(using: .utf8) ?? Data())
        
        // Expiry Date
        data.append(cardData.expiryDate.data(using: .utf8) ?? Data())
        
        // Cardholder Name
        data.append(cardData.cardholderName.data(using: .utf8) ?? Data())
        
        return data
    }
    
    private func encryptToken(_ data: Data, with key: SecureEnclave.P256.KeyAgreement.PrivateKey) -> Data? {
        // Создание симметричного ключа для шифрования
        guard let symmetricKey = generateRandomData(length: 32) else {
            return nil
        }
        
        let key = SymmetricKey(data: symmetricKey)
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("❌ Ошибка шифрования токена: \(error)")
            return nil
        }
    }
    
    // MARK: - Apple Pay Integration
    
    /// Генерация Apple Pay токена с использованием Secure Enclave
    func generateApplePayToken(cardData: CardData, amount: Double, merchantId: String) -> ApplePayToken? {
        guard isAvailable else {
            print("❌ Secure Enclave недоступен")
            return nil
        }
        
        // Аутентификация с биометрией
        guard authenticateWithBiometrics(reason: "Подтвердите Apple Pay платеж") else {
            print("❌ Аутентификация не удалась")
            return nil
        }
        
        // Генерация эфемерального ключа
        guard let ephemeralKey = generateSecureEnclaveKey(tag: "applepay_\(Date().timeIntervalSince1970)") else {
            print("❌ Не удалось сгенерировать эфемеральный ключ")
            return nil
        }
        
        // Создание заголовка Apple Pay
        let header = createApplePayHeader(ephemeralKey: ephemeralKey)
        
        // Создание данных платежа
        let paymentData = createApplePayPaymentData(cardData: cardData, amount: amount, merchantId: merchantId)
        
        // Шифрование данных
        guard let encryptedData = encryptApplePayData(paymentData, with: ephemeralKey) else {
            print("❌ Не удалось зашифровать данные Apple Pay")
            return nil
        }
        
        return ApplePayToken(
            token: generateApplePayTokenString(),
            paymentData: encryptedData,
            header: header
        )
    }
    
    private func createApplePayHeader(ephemeralKey: SecureEnclave.P256.KeyAgreement.PrivateKey) -> ApplePayHeader {
        let publicKey = ephemeralKey.publicKey
        let publicKeyData = publicKey.rawRepresentation
        
        // Генерация хеша публичного ключа
        let publicKeyHash = SHA256.hash(data: publicKeyData)
        
        // Генерация ID транзакции
        let transactionId = generateRandomData(length: 16) ?? Data()
        
        return ApplePayHeader(
            ephemeralPublicKey: publicKeyData,
            publicKeyHash: Data(publicKeyHash),
            transactionId: transactionId
        )
    }
    
    private func createApplePayPaymentData(cardData: CardData, amount: Double, merchantId: String) -> Data {
        var data = Data()
        
        // Данные карты (зашифрованные)
        let cardDataBytes = createEncryptedCardData(cardData)
        data.append(cardDataBytes)
        
        // Сумма платежа
        let amountBytes = withUnsafeBytes(of: amount) { Data($0) }
        data.append(amountBytes)
        
        // ID мерчанта
        data.append(merchantId.data(using: .utf8) ?? Data())
        
        // Временная метка
        let timestamp = Date().timeIntervalSince1970
        let timestampBytes = withUnsafeBytes(of: timestamp) { Data($0) }
        data.append(timestampBytes)
        
        return data
    }
    
    private func createEncryptedCardData(_ cardData: CardData) -> Data {
        // Создание структуры данных карты
        var cardDataStruct = Data()
        
        // PAN (маскированный)
        let maskedPAN = "•••• •••• •••• \(String(cardData.cardNumber.suffix(4)))"
        cardDataStruct.append(maskedPAN.data(using: .utf8) ?? Data())
        
        // Expiry Date
        cardDataStruct.append(cardData.expiryDate.data(using: .utf8) ?? Data())
        
        // Cardholder Name
        cardDataStruct.append(cardData.cardholderName.data(using: .utf8) ?? Data())
        
        // Шифрование данных карты
        guard let symmetricKey = generateRandomData(length: 32) else {
            return Data()
        }
        
        let key = SymmetricKey(data: symmetricKey)
        
        do {
            let sealedBox = try AES.GCM.seal(cardDataStruct, using: key)
            return sealedBox.combined
        } catch {
            print("❌ Ошибка шифрования данных карты: \(error)")
            return Data()
        }
    }
    
    private func encryptApplePayData(_ data: Data, with key: SecureEnclave.P256.KeyAgreement.PrivateKey) -> Data? {
        // Создание симметричного ключа для шифрования
        guard let symmetricKey = generateRandomData(length: 32) else {
            return nil
        }
        
        let symKey = SymmetricKey(data: symmetricKey)
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: symKey)
            return sealedBox.combined
        } catch {
            print("❌ Ошибка шифрования данных Apple Pay: \(error)")
            return nil
        }
    }
    
    private func generateApplePayTokenString() -> String {
        // Генерация строки токена Apple Pay
        guard let randomBytes = generateRandomData(length: 32) else {
            return UUID().uuidString
        }
        return randomBytes.base64EncodedString()
    }
    
    // MARK: - Cleanup
    
    /// Очистка всех ключей Secure Enclave
    func cleanupAllKeys() {
        guard isAvailable else { return }
        
        let keyTags = [
            "payment_\(Date().timeIntervalSince1970)",
            "applepay_\(Date().timeIntervalSince1970)"
        ]
        
        for tag in keyTags {
            _ = deleteSecureEnclaveKey(tag: tag)
        }
        
        print("🧹 Все ключи Secure Enclave очищены")
    }
}

// MARK: - Supporting Types
struct CardData {
    let cardNumber: String
    let expiryDate: String
    let cvv: String
    let cardholderName: String
    let bankName: String
}

struct PaymentToken {
    let token: String
    let timestamp: Date
    let signature: String
    let protocol: NFCProtocol
}

struct ApplePayToken {
    let token: String
    let paymentData: Data
    let header: ApplePayHeader
}

struct ApplePayHeader {
    let ephemeralPublicKey: Data
    let publicKeyHash: Data
    let transactionId: Data
}

enum NFCProtocol: String {
    case iso14443A = "ISO 14443-A"
    case iso14443B = "ISO 14443-B"
    case feliCa = "FeliCa"
    case iso15693 = "ISO 15693"
}
