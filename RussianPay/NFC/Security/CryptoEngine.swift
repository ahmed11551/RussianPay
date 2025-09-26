import Foundation
import CryptoKit
import Security

/// Криптографический движок для безопасных платежей
class CryptoEngine {
    
    // MARK: - Properties
    private let keyManager: KeyManager
    private let secureEnclave: SecureEnclaveManager
    
    // Ключи для различных операций
    private var sessionKey: SymmetricKey?
    private var ephemeralKeyPair: CryptoKit.Curve25519.KeyAgreement.PrivateKey?
    
    // MARK: - Initialization
    init() {
        self.keyManager = KeyManager()
        self.secureEnclave = SecureEnclaveManager()
        setupKeys()
    }
    
    // MARK: - Key Management
    
    private func setupKeys() {
        // Генерация сессионного ключа
        sessionKey = SymmetricKey(size: .bits256)
        
        // Генерация эфемеральной пары ключей
        ephemeralKeyPair = CryptoKit.Curve25519.KeyAgreement.PrivateKey()
    }
    
    // MARK: - Payment Token Generation
    
    /// Генерация платежного токена
    func generatePaymentToken(amount: Double, merchantId: String) -> PaymentToken? {
        guard let sessionKey = sessionKey else { return nil }
        
        // Создание данных токена
        let tokenData = createTokenData(amount: amount, merchantId: merchantId)
        
        // Подпись токена
        guard let signature = signData(tokenData, with: sessionKey) else { return nil }
        
        // Шифрование токена
        guard let encryptedToken = encryptData(tokenData, with: sessionKey) else { return nil }
        
        return PaymentToken(
            token: encryptedToken.base64EncodedString(),
            timestamp: Date(),
            signature: signature.base64EncodedString(),
            protocol: .iso14443A
        )
    }
    
    private func createTokenData(amount: Double, merchantId: String) -> Data {
        var data = Data()
        
        // Добавление суммы
        let amountBytes = withUnsafeBytes(of: amount) { Data($0) }
        data.append(amountBytes)
        
        // Добавление ID мерчанта
        data.append(merchantId.data(using: .utf8) ?? Data())
        
        // Добавление временной метки
        let timestamp = Date().timeIntervalSince1970
        let timestampBytes = withUnsafeBytes(of: timestamp) { Data($0) }
        data.append(timestampBytes)
        
        // Добавление случайного nonce
        data.append(generateRandomBytes(length: 16))
        
        return data
    }
    
    // MARK: - Authentication
    
    /// Генерация ответа на аутентификацию
    func generateAuthenticationResponse() -> Data {
        guard let sessionKey = sessionKey else { return Data() }
        
        // Создание challenge-response
        let challenge = generateRandomBytes(length: 8)
        let response = hmac(challenge, with: sessionKey)
        
        return challenge + response
    }
    
    /// Генерация Application Cryptogram
    func generateApplicationCryptogram() -> Data {
        guard let sessionKey = sessionKey else { return Data() }
        
        // Создание данных для AC
        var acData = Data()
        acData.append(generateRandomBytes(length: 4)) // ATC
        acData.append(generateRandomBytes(length: 8)) // Unpredictable Number
        acData.append(generateRandomBytes(length: 6)) // Transaction Date
        acData.append(generateRandomBytes(length: 3)) // Transaction Type
        
        // Генерация AC
        let ac = hmac(acData, with: sessionKey)
        return ac.prefix(8) // 8 байт для AC
    }
    
    // MARK: - Apple Pay Integration
    
    /// Генерация Apple Pay токена
    func generateApplePayToken(cardData: CardData, amount: Double, merchantId: String) -> ApplePayToken? {
        guard let ephemeralKey = ephemeralKeyPair else { return nil }
        
        // Создание заголовка Apple Pay
        let header = createApplePayHeader(ephemeralKey: ephemeralKey)
        
        // Создание данных платежа
        let paymentData = createApplePayPaymentData(cardData: cardData, amount: amount, merchantId: merchantId)
        
        // Шифрование данных
        guard let encryptedData = encryptApplePayData(paymentData, with: ephemeralKey) else { return nil }
        
        return ApplePayToken(
            token: generateApplePayTokenString(),
            paymentData: encryptedData,
            header: header
        )
    }
    
    private func createApplePayHeader(ephemeralKey: CryptoKit.Curve25519.KeyAgreement.PrivateKey) -> ApplePayHeader {
        let publicKey = ephemeralKey.publicKey
        let publicKeyData = publicKey.rawRepresentation
        
        // Генерация хеша публичного ключа
        let publicKeyHash = SHA256.hash(data: publicKeyData)
        
        // Генерация ID транзакции
        let transactionId = generateRandomBytes(length: 16)
        
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
        let maskedPAN = maskCardNumber(cardData.cardNumber)
        cardDataStruct.append(maskedPAN.data(using: .utf8) ?? Data())
        
        // Expiry Date
        cardDataStruct.append(cardData.expiryDate.data(using: .utf8) ?? Data())
        
        // Cardholder Name
        cardDataStruct.append(cardData.cardholderName.data(using: .utf8) ?? Data())
        
        // Шифрование данных карты
        guard let sessionKey = sessionKey else { return Data() }
        return encryptData(cardDataStruct, with: sessionKey) ?? Data()
    }
    
    private func maskCardNumber(_ cardNumber: String) -> String {
        guard cardNumber.count >= 4 else { return cardNumber }
        let lastFour = String(cardNumber.suffix(4))
        return "•••• •••• •••• \(lastFour)"
    }
    
    private func encryptApplePayData(_ data: Data, with key: CryptoKit.Curve25519.KeyAgreement.PrivateKey) -> Data? {
        // Эмуляция шифрования Apple Pay
        guard let sessionKey = sessionKey else { return nil }
        return encryptData(data, with: sessionKey)
    }
    
    private func generateApplePayTokenString() -> String {
        // Генерация строки токена Apple Pay
        let randomBytes = generateRandomBytes(length: 32)
        return randomBytes.base64EncodedString()
    }
    
    // MARK: - Cryptographic Operations
    
    /// Генерация случайных байтов
    func generateRandomBytes(length: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return Data(bytes)
    }
    
    /// Подпись данных
    private func signData(_ data: Data, with key: SymmetricKey) -> Data? {
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return Data(signature)
    }
    
    /// Создание HMAC
    private func hmac(_ data: Data, with key: SymmetricKey) -> Data {
        let hmac = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return Data(hmac)
    }
    
    /// Шифрование данных
    private func encryptData(_ data: Data, with key: SymmetricKey) -> Data? {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Ошибка шифрования: \(error)")
            return nil
        }
    }
    
    /// Расшифровка данных
    private func decryptData(_ data: Data, with key: SymmetricKey) -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("Ошибка расшифровки: \(error)")
            return nil
        }
    }
    
    // MARK: - Key Derivation
    
    /// Вывод ключа из мастер-ключа
    private func deriveKey(from masterKey: SymmetricKey, context: String) -> SymmetricKey {
        let contextData = context.data(using: .utf8) ?? Data()
        let derivedKey = HKDF<SHA256>.deriveKey(inputKeyMaterial: masterKey, salt: contextData, outputByteCount: 32)
        return derivedKey
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