import XCTest
@testable import RussianPay

class RussianPayTests: XCTestCase {
    
    var cryptoEngine: CryptoEngine!
    var keyManager: KeyManager!
    var nfcEmulator: NFCEmulator!
    var applePayEmulator: ApplePayEmulator!
    
    override func setUpWithError() throws {
        cryptoEngine = CryptoEngine()
        keyManager = KeyManager()
        nfcEmulator = NFCEmulator()
        applePayEmulator = ApplePayEmulator(cryptoEngine: cryptoEngine, keyManager: keyManager)
    }
    
    override func tearDownWithError() throws {
        cryptoEngine = nil
        keyManager = nil
        nfcEmulator = nil
        applePayEmulator = nil
    }
    
    // MARK: - CryptoEngine Tests
    
    func testCryptoEngineInitialization() throws {
        XCTAssertNotNil(cryptoEngine)
    }
    
    func testPaymentTokenGeneration() throws {
        let amount = 100.0
        let merchantId = "com.russianpay.merchant"
        
        let token = cryptoEngine.generatePaymentToken(amount: amount, merchantId: merchantId)
        
        XCTAssertNotNil(token)
        XCTAssertEqual(token?.protocol, .iso14443A)
        XCTAssertNotNil(token?.token)
        XCTAssertNotNil(token?.signature)
    }
    
    func testRandomBytesGeneration() throws {
        let length = 16
        let randomBytes = cryptoEngine.generateRandomBytes(length: length)
        
        XCTAssertEqual(randomBytes.count, length)
        XCTAssertNotEqual(randomBytes, Data(count: length))
    }
    
    func testAuthenticationResponse() throws {
        let response = cryptoEngine.generateAuthenticationResponse()
        
        XCTAssertFalse(response.isEmpty)
        XCTAssertGreaterThan(response.count, 8)
    }
    
    func testApplicationCryptogram() throws {
        let ac = cryptoEngine.generateApplicationCryptogram()
        
        XCTAssertFalse(ac.isEmpty)
        XCTAssertEqual(ac.count, 8)
    }
    
    // MARK: - KeyManager Tests
    
    func testKeyManagerInitialization() throws {
        XCTAssertNotNil(keyManager)
        XCTAssertNotNil(keyManager.currentMasterKey)
        XCTAssertNotNil(keyManager.currentDeviceKey)
    }
    
    func testKeyDerivation() throws {
        let operation = KeyManager.KeyOperation.payment
        let context = "test_context"
        
        let derivedKey = keyManager.deriveKey(for: operation, context: context)
        
        XCTAssertNotNil(derivedKey)
        XCTAssertEqual(derivedKey.withUnsafeBytes { $0.count }, 32)
    }
    
    func testSecureStorage() throws {
        let testData = "test_data".data(using: .utf8)!
        let key = "test_key"
        
        let storeResult = keyManager.secureStore(testData, forKey: key)
        XCTAssertTrue(storeResult)
        
        let retrievedData = keyManager.secureRetrieve(forKey: key)
        XCTAssertEqual(retrievedData, testData)
        
        let deleteResult = keyManager.secureDelete(forKey: key)
        XCTAssertTrue(deleteResult)
    }
    
    // MARK: - NFCEmulator Tests
    
    func testNFCEmulatorInitialization() throws {
        XCTAssertNotNil(nfcEmulator)
        XCTAssertFalse(nfcEmulator.isEmulating)
        XCTAssertEqual(nfcEmulator.connectionStatus, .disconnected)
    }
    
    func testNFCProtocols() throws {
        let protocols = NFCEmulator.NFCProtocol.allCases
        
        XCTAssertEqual(protocols.count, 4)
        XCTAssertTrue(protocols.contains(.iso14443A))
        XCTAssertTrue(protocols.contains(.iso14443B))
        XCTAssertTrue(protocols.contains(.feliCa))
        XCTAssertTrue(protocols.contains(.iso15693))
    }
    
    func testNFCEmulationStart() throws {
        nfcEmulator.startEmulation(protocol: .iso14443A)
        
        XCTAssertTrue(nfcEmulator.isEmulating)
        XCTAssertEqual(nfcEmulator.currentProtocol, .iso14443A)
    }
    
    func testNFCEmulationStop() throws {
        nfcEmulator.startEmulation(protocol: .iso14443A)
        nfcEmulator.stopEmulation()
        
        XCTAssertFalse(nfcEmulator.isEmulating)
        XCTAssertEqual(nfcEmulator.connectionStatus, .disconnected)
    }
    
    // MARK: - ApplePayEmulator Tests
    
    func testApplePayEmulatorInitialization() throws {
        XCTAssertNotNil(applePayEmulator)
    }
    
    func testApplePayAvailability() throws {
        let isAvailable = ApplePayEmulator.isAvailable
        XCTAssertNotNil(isAvailable)
    }
    
    func testPaymentRequestCreation() throws {
        let amount = 100.0
        let merchantId = "com.russianpay.merchant"
        let description = "Test Payment"
        
        let request = applePayEmulator.createPaymentRequest(
            amount: amount,
            merchantId: merchantId,
            description: description
        )
        
        XCTAssertEqual(request.merchantIdentifier, merchantId)
        XCTAssertEqual(request.countryCode, "RU")
        XCTAssertEqual(request.currencyCode, "RUB")
        XCTAssertEqual(request.paymentSummaryItems.count, 2)
    }
    
    // MARK: - Card Model Tests
    
    func testCardInitialization() throws {
        let card = Card(
            cardNumber: "1234567890123456",
            cardholderName: "IVAN IVANOV",
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            bankName: "Sberbank",
            cardType: .visa,
            isDefault: true,
            createdAt: Date()
        )
        
        XCTAssertEqual(card.cardNumber, "1234567890123456")
        XCTAssertEqual(card.cardholderName, "IVAN IVANOV")
        XCTAssertEqual(card.expiryMonth, 12)
        XCTAssertEqual(card.expiryYear, 2025)
        XCTAssertEqual(card.cvv, "123")
        XCTAssertEqual(card.bankName, "Sberbank")
        XCTAssertEqual(card.cardType, .visa)
        XCTAssertTrue(card.isDefault)
    }
    
    func testCardValidation() throws {
        let validCard = Card(
            cardNumber: "1234567890123456",
            cardholderName: "IVAN IVANOV",
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            bankName: "Sberbank",
            cardType: .visa,
            isDefault: true,
            createdAt: Date()
        )
        
        XCTAssertTrue(validCard.isValid)
    }
    
    func testCardMasking() throws {
        let card = Card(
            cardNumber: "1234567890123456",
            cardholderName: "IVAN IVANOV",
            expiryMonth: 12,
            expiryYear: 2025,
            cvv: "123",
            bankName: "Sberbank",
            cardType: .visa,
            isDefault: true,
            createdAt: Date()
        )
        
        XCTAssertEqual(card.maskedNumber, "•••• •••• •••• 3456")
    }
    
    // MARK: - Transaction Model Tests
    
    func testTransactionInitialization() throws {
        let transaction = Transaction(
            amount: 100.0,
            currency: "RUB",
            merchantName: "Test Merchant",
            cardId: UUID(),
            status: .completed,
            timestamp: Date(),
            description: "Test Transaction"
        )
        
        XCTAssertEqual(transaction.amount, 100.0)
        XCTAssertEqual(transaction.currency, "RUB")
        XCTAssertEqual(transaction.merchantName, "Test Merchant")
        XCTAssertEqual(transaction.status, .completed)
        XCTAssertNotNil(transaction.description)
    }
    
    func testTransactionStatus() throws {
        let statuses = Transaction.TransactionStatus.allCases
        
        XCTAssertEqual(statuses.count, 4)
        XCTAssertTrue(statuses.contains(.pending))
        XCTAssertTrue(statuses.contains(.completed))
        XCTAssertTrue(statuses.contains(.failed))
        XCTAssertTrue(statuses.contains(.cancelled))
    }
    
    // MARK: - QRCodeService Tests
    
    func testQRCodeServiceInitialization() throws {
        let qrService = QRCodeService()
        
        XCTAssertNotNil(qrService)
        XCTAssertFalse(qrService.isGenerating)
        XCTAssertFalse(qrService.isScanning)
    }
    
    func testPaymentQRGeneration() throws {
        let qrService = QRCodeService()
        let amount = 100.0
        let merchantId = "com.russianpay.merchant"
        let description = "Test Payment"
        
        let qrCode = qrService.generatePaymentQR(
            amount: amount,
            merchantId: merchantId,
            description: description
        )
        
        XCTAssertNotNil(qrCode)
    }
    
    // MARK: - BLEPaymentService Tests
    
    func testBLEPaymentServiceInitialization() throws {
        let bleService = BLEPaymentService()
        
        XCTAssertNotNil(bleService)
        XCTAssertFalse(bleService.isAdvertising)
        XCTAssertFalse(bleService.isScanning)
    }
    
    func testBLEBluetoothAvailability() throws {
        let bleService = BLEPaymentService()
        
        // Проверка доступности Bluetooth
        let isAvailable = bleService.isBluetoothAvailable
        XCTAssertNotNil(isAvailable)
    }
    
    // MARK: - WiFiDirectService Tests
    
    func testWiFiDirectServiceInitialization() throws {
        let wifiService = WiFiDirectService()
        
        XCTAssertNotNil(wifiService)
        XCTAssertFalse(wifiService.isHosting)
        XCTAssertFalse(wifiService.isConnected)
    }
    
    // MARK: - Performance Tests
    
    func testCryptoEnginePerformance() throws {
        measure {
            for _ in 0..<100 {
                _ = cryptoEngine.generateRandomBytes(length: 16)
            }
        }
    }
    
    func testKeyDerivationPerformance() throws {
        measure {
            for _ in 0..<100 {
                _ = keyManager.deriveKey(for: .payment, context: "test")
            }
        }
    }
    
    func testPaymentTokenGenerationPerformance() throws {
        measure {
            for _ in 0..<50 {
                _ = cryptoEngine.generatePaymentToken(amount: 100.0, merchantId: "test")
            }
        }
    }
}
