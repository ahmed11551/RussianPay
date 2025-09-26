import Foundation
import CoreNFC
import CryptoKit

/// Эмулятор NFC-меток для имитации банковских карт
class NFCTagEmulator: NSObject {
    
    // MARK: - Properties
    private let cryptoEngine: CryptoEngine
    private let keyManager: KeyManager
    private var currentCardData: CardData?
    private var isEmulating = false
    
    // Эмуляция различных типов карт
    private var cardType: CardType = .contactless
    private var protocolStack: [NFCProtocol] = [.iso14443A]
    
    // MARK: - Enums
    enum CardType {
        case contactless
        case dualInterface
        case emv
        case mir
        
        var atr: Data {
            switch self {
            case .contactless:
                return Data([0x3B, 0x8F, 0x80, 0x01, 0x80, 0x4F, 0x0C, 0xA0, 0x00, 0x00, 0x03, 0x06, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00])
            case .dualInterface:
                return Data([0x3B, 0x8F, 0x80, 0x01, 0x80, 0x4F, 0x0C, 0xA0, 0x00, 0x00, 0x03, 0x06, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00])
            case .emv:
                return Data([0x3B, 0x8F, 0x80, 0x01, 0x80, 0x4F, 0x0C, 0xA0, 0x00, 0x00, 0x03, 0x06, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00])
            case .mir:
                return Data([0x3B, 0x8F, 0x80, 0x01, 0x80, 0x4F, 0x0C, 0xA0, 0x00, 0x00, 0x03, 0x06, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00])
            }
        }
    }
    
    // MARK: - Initialization
    init(cryptoEngine: CryptoEngine, keyManager: KeyManager) {
        self.cryptoEngine = cryptoEngine
        self.keyManager = keyManager
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Эмуляция банковской карты
    func emulateCard(cardData: CardData) {
        currentCardData = cardData
        isEmulating = true
        
        // Генерация уникального UID карты
        let cardUID = generateCardUID(from: cardData)
        
        // Создание эмулятора метки
        let tagEmulator = createTagEmulator(uid: cardUID, cardData: cardData)
        
        // Запуск эмуляции
        startTagEmulation(tagEmulator)
    }
    
    /// Остановка эмуляции
    func stopEmulation() {
        isEmulating = false
        currentCardData = nil
    }
    
    /// Обработка APDU команд
    func processAPDU(_ apdu: Data) -> Data? {
        guard let cardData = currentCardData else { return nil }
        
        let command = parseAPDUCommand(apdu)
        
        switch command {
        case .select:
            return handleSelectCommand(apdu)
        case .readBinary:
            return handleReadBinaryCommand(apdu)
        case .getChallenge:
            return handleGetChallengeCommand(apdu)
        case .externalAuthenticate:
            return handleExternalAuthenticateCommand(apdu)
        case .internalAuthenticate:
            return handleInternalAuthenticateCommand(apdu)
        case .generateAC:
            return handleGenerateACCommand(apdu)
        case .getData:
            return handleGetDataCommand(apdu)
        case .putData:
            return handlePutDataCommand(apdu)
        case .updateBinary:
            return handleUpdateBinaryCommand(apdu)
        case .unknown:
            return createErrorResponse(.commandNotAllowed)
        }
    }
    
    // MARK: - Private Methods
    
    private func generateCardUID(from cardData: CardData) -> Data {
        // Генерация уникального UID на основе данных карты
        let input = cardData.cardNumber + cardData.expiryDate + cardData.cvv
        let hash = SHA256.hash(data: input.data(using: .utf8) ?? Data())
        return Data(hash.prefix(7)) // 7 байт для UID
    }
    
    private func createTagEmulator(uid: Data, cardData: CardData) -> NFCTagEmulator {
        let emulator = NFCTagEmulator()
        emulator.uid = uid
        emulator.cardData = cardData
        return emulator
    }
    
    private func startTagEmulation(_ emulator: NFCTagEmulator) {
        // Эмуляция обнаружения метки терминалом
        DispatchQueue.global(qos: .userInitiated).async {
            self.simulateTagDetection(emulator)
        }
    }
    
    private func simulateTagDetection(_ emulator: NFCTagEmulator) {
        // Симуляция процесса обнаружения и инициализации метки
        print("🔍 Эмуляция обнаружения NFC-метки...")
        
        // Отправка ATR (Answer To Reset)
        let atr = cardType.atr
        print("📤 Отправка ATR: \(atr.map { String(format: "%02X", $0) }.joined())")
        
        // Ожидание команд от терминала
        print("⏳ Ожидание APDU команд от терминала...")
    }
    
    // MARK: - APDU Command Handling
    
    private enum APDUCommand {
        case select
        case readBinary
        case getChallenge
        case externalAuthenticate
        case internalAuthenticate
        case generateAC
        case getData
        case putData
        case updateBinary
        case unknown
    }
    
    private func parseAPDUCommand(_ apdu: Data) -> APDUCommand {
        guard apdu.count >= 4 else { return .unknown }
        
        let cla = apdu[0]
        let ins = apdu[1]
        
        switch (cla, ins) {
        case (0x00, 0xA4): return .select
        case (0x00, 0xB0): return .readBinary
        case (0x00, 0x84): return .getChallenge
        case (0x00, 0x82): return .externalAuthenticate
        case (0x00, 0x88): return .internalAuthenticate
        case (0x80, 0xAE): return .generateAC
        case (0x80, 0xCA): return .getData
        case (0x80, 0xDA): return .putData
        case (0x00, 0xD6): return .updateBinary
        default: return .unknown
        }
    }
    
    private func handleSelectCommand(_ apdu: Data) -> Data {
        // Обработка команды SELECT
        print("📋 Обработка команды SELECT")
        
        // Возвращаем успешный ответ
        return Data([0x90, 0x00])
    }
    
    private func handleReadBinaryCommand(_ apdu: Data) -> Data {
        // Обработка команды READ BINARY
        print("📖 Обработка команды READ BINARY")
        
        guard let cardData = currentCardData else {
            return createErrorResponse(.fileNotFound)
        }
        
        // Эмуляция чтения данных карты
        let cardDataBytes = createCardDataBytes(cardData)
        return cardDataBytes + Data([0x90, 0x00])
    }
    
    private func handleGetChallengeCommand(_ apdu: Data) -> Data {
        // Обработка команды GET CHALLENGE
        print("🎲 Обработка команды GET CHALLENGE")
        
        // Генерация случайного challenge
        let challenge = cryptoEngine.generateRandomBytes(length: 8)
        return challenge + Data([0x90, 0x00])
    }
    
    private func handleExternalAuthenticateCommand(_ apdu: Data) -> Data {
        // Обработка команды EXTERNAL AUTHENTICATE
        print("🔐 Обработка команды EXTERNAL AUTHENTICATE")
        
        // Эмуляция аутентификации
        return Data([0x90, 0x00])
    }
    
    private func handleInternalAuthenticateCommand(_ apdu: Data) -> Data {
        // Обработка команды INTERNAL AUTHENTICATE
        print("🔐 Обработка команды INTERNAL AUTHENTICATE")
        
        // Эмуляция внутренней аутентификации
        let response = cryptoEngine.generateAuthenticationResponse()
        return response + Data([0x90, 0x00])
    }
    
    private func handleGenerateACCommand(_ apdu: Data) -> Data {
        // Обработка команды GENERATE AC
        print("💳 Обработка команды GENERATE AC")
        
        // Генерация Application Cryptogram
        let ac = cryptoEngine.generateApplicationCryptogram()
        return ac + Data([0x90, 0x00])
    }
    
    private func handleGetDataCommand(_ apdu: Data) -> Data {
        // Обработка команды GET DATA
        print("📊 Обработка команды GET DATA")
        
        // Возвращаем данные карты
        let cardData = createCardDataBytes(currentCardData!)
        return cardData + Data([0x90, 0x00])
    }
    
    private func handlePutDataCommand(_ apdu: Data) -> Data {
        // Обработка команды PUT DATA
        print("💾 Обработка команды PUT DATA")
        
        return Data([0x90, 0x00])
    }
    
    private func handleUpdateBinaryCommand(_ apdu: Data) -> Data {
        // Обработка команды UPDATE BINARY
        print("✏️ Обработка команды UPDATE BINARY")
        
        return Data([0x90, 0x00])
    }
    
    // MARK: - Helper Methods
    
    private func createCardDataBytes(_ cardData: CardData) -> Data {
        // Создание байтов данных карты в формате EMV
        var data = Data()
        
        // PAN (Primary Account Number)
        data.append(0x5A) // Tag for PAN
        data.append(UInt8(cardData.cardNumber.count))
        data.append(contentsOf: cardData.cardNumber.utf8)
        
        // Expiry Date
        data.append(0x5F, 0x24) // Tag for Expiry Date
        data.append(0x03)
        data.append(contentsOf: cardData.expiryDate.utf8)
        
        // Cardholder Name
        data.append(0x5F, 0x20) // Tag for Cardholder Name
        data.append(UInt8(cardData.cardholderName.count))
        data.append(contentsOf: cardData.cardholderName.utf8)
        
        return data
    }
    
    private func createErrorResponse(_ error: APDUError) -> Data {
        return Data([error.sw1, error.sw2])
    }
    
    private enum APDUError {
        case commandNotAllowed
        case fileNotFound
        case securityStatusNotSatisfied
        case incorrectParameters
        
        var sw1: UInt8 {
            switch self {
            case .commandNotAllowed: return 0x69
            case .fileNotFound: return 0x6A
            case .securityStatusNotSatisfied: return 0x69
            case .incorrectParameters: return 0x6A
            }
        }
        
        var sw2: UInt8 {
            switch self {
            case .commandNotAllowed: return 0x82
            case .fileNotFound: return 0x82
            case .securityStatusNotSatisfied: return 0x82
            case .incorrectParameters: return 0x86
            }
        }
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