import Foundation
import CoreNFC
import CryptoKit

/// Эмулятор NFC-ридера для имитации терминала
class NFCReaderEmulator: NSObject, ObservableObject {
    
    // MARK: - Properties
    @Published var isReading = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var detectedTags: [NFCTagInfo] = []
    @Published var currentTransaction: TransactionInfo?
    
    private let cryptoEngine: CryptoEngine
    private let keyManager: KeyManager
    private var session: NFCNDEFReaderSession?
    private var currentTag: NFCTagInfo?
    
    // MARK: - Enums
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    // MARK: - Initialization
    init(cryptoEngine: CryptoEngine, keyManager: KeyManager) {
        self.cryptoEngine = cryptoEngine
        self.keyManager = keyManager
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Запуск эмуляции NFC-ридера
    func startReading() {
        guard !isReading else { return }
        
        isReading = true
        connectionStatus = .connecting
        
        // Проверка доступности NFC
        if NFCNDEFReaderSession.readingAvailable {
            startStandardNFCReading()
        } else {
            // Эмуляция без реального NFC
            startEmulatedReading()
        }
    }
    
    /// Остановка эмуляции
    func stopReading() {
        isReading = false
        connectionStatus = .disconnected
        
        session?.invalidate()
        session = nil
        currentTag = nil
    }
    
    /// Обработка обнаруженной метки
    func processDetectedTag(_ tag: NFCTagInfo) {
        currentTag = tag
        connectionStatus = .connected
        
        // Добавление в список обнаруженных меток
        if !detectedTags.contains(where: { $0.uid == tag.uid }) {
            detectedTags.append(tag)
        }
        
        // Начало транзакции
        startTransaction(with: tag)
    }
    
    /// Завершение транзакции
    func completeTransaction(success: Bool) {
        guard let transaction = currentTransaction else { return }
        
        transaction.isCompleted = true
        transaction.isSuccessful = success
        transaction.endTime = Date()
        
        // Очистка текущей транзакции
        currentTransaction = nil
        currentTag = nil
        connectionStatus = .disconnected
    }
    
    // MARK: - Private Methods
    
    private func startStandardNFCReading() {
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Поднесите карту к устройству для оплаты"
        session?.begin()
    }
    
    private func startEmulatedReading() {
        // Эмуляция процесса чтения без реального NFC
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.connectionStatus = .connected
            
            // Создание эмулированной метки
            let emulatedTag = self.createEmulatedTag()
            self.processDetectedTag(emulatedTag)
        }
    }
    
    private func createEmulatedTag() -> NFCTagInfo {
        // Создание эмулированной метки с тестовыми данными
        let uid = generateRandomUID()
        let atr = generateATR()
        
        return NFCTagInfo(
            uid: uid,
            atr: atr,
            cardType: .contactless,
            protocol: .iso14443A,
            isEmulated: true
        )
    }
    
    private func generateRandomUID() -> Data {
        var bytes = [UInt8](repeating: 0, count: 7)
        _ = SecRandomCopyBytes(kSecRandomDefault, 7, &bytes)
        return Data(bytes)
    }
    
    private func generateATR() -> Data {
        // Генерация ATR для эмулированной карты
        return Data([0x3B, 0x8F, 0x80, 0x01, 0x80, 0x4F, 0x0C, 0xA0, 0x00, 0x00, 0x03, 0x06, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00])
    }
    
    private func startTransaction(with tag: NFCTagInfo) {
        let transaction = TransactionInfo(
            tag: tag,
            startTime: Date(),
            amount: 0.0,
            merchantId: "com.russianpay.merchant",
            status: .initialized
        )
        
        currentTransaction = transaction
        
        // Начало процесса аутентификации
        authenticateTag(tag)
    }
    
    private func authenticateTag(_ tag: NFCTagInfo) {
        // Эмуляция процесса аутентификации
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.currentTransaction?.status = .authenticated
            print("🔐 Метка аутентифицирована: \(tag.uid.map { String(format: "%02X", $0) }.joined())")
        }
    }
    
    // MARK: - APDU Commands
    
    /// Отправка APDU команды
    func sendAPDUCommand(_ apdu: Data) -> Data? {
        guard let tag = currentTag else { return nil }
        
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
        print("📋 Обработка команды SELECT")
        return Data([0x90, 0x00])
    }
    
    private func handleReadBinaryCommand(_ apdu: Data) -> Data {
        print("📖 Обработка команды READ BINARY")
        
        // Эмуляция чтения данных карты
        let cardData = createEmulatedCardData()
        return cardData + Data([0x90, 0x00])
    }
    
    private func handleGetChallengeCommand(_ apdu: Data) -> Data {
        print("🎲 Обработка команды GET CHALLENGE")
        
        // Генерация случайного challenge
        let challenge = cryptoEngine.generateRandomBytes(length: 8)
        return challenge + Data([0x90, 0x00])
    }
    
    private func handleExternalAuthenticateCommand(_ apdu: Data) -> Data {
        print("🔐 Обработка команды EXTERNAL AUTHENTICATE")
        
        // Эмуляция внешней аутентификации
        return Data([0x90, 0x00])
    }
    
    private func handleInternalAuthenticateCommand(_ apdu: Data) -> Data {
        print("🔐 Обработка команды INTERNAL AUTHENTICATE")
        
        // Эмуляция внутренней аутентификации
        let response = cryptoEngine.generateAuthenticationResponse()
        return response + Data([0x90, 0x00])
    }
    
    private func handleGenerateACCommand(_ apdu: Data) -> Data {
        print("💳 Обработка команды GENERATE AC")
        
        // Генерация Application Cryptogram
        let ac = cryptoEngine.generateApplicationCryptogram()
        return ac + Data([0x90, 0x00])
    }
    
    private func handleGetDataCommand(_ apdu: Data) -> Data {
        print("📊 Обработка команды GET DATA")
        
        // Возврат данных карты
        let cardData = createEmulatedCardData()
        return cardData + Data([0x90, 0x00])
    }
    
    private func handlePutDataCommand(_ apdu: Data) -> Data {
        print("💾 Обработка команды PUT DATA")
        return Data([0x90, 0x00])
    }
    
    private func handleUpdateBinaryCommand(_ apdu: Data) -> Data {
        print("✏️ Обработка команды UPDATE BINARY")
        return Data([0x90, 0x00])
    }
    
    private func createEmulatedCardData() -> Data {
        // Создание эмулированных данных карты
        var data = Data()
        
        // PAN (Primary Account Number)
        data.append(0x5A) // Tag for PAN
        data.append(0x10) // Length
        data.append(contentsOf: "1234567890123456".utf8)
        
        // Expiry Date
        data.append(0x5F, 0x24) // Tag for Expiry Date
        data.append(0x03) // Length
        data.append(contentsOf: "12/25".utf8)
        
        // Cardholder Name
        data.append(0x5F, 0x20) // Tag for Cardholder Name
        data.append(0x0C) // Length
        data.append(contentsOf: "IVAN IVANOV".utf8)
        
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

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCReaderEmulator: NFCNDEFReaderSessionDelegate {
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.connectionStatus = .error(error.localizedDescription)
            self.isReading = false
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Обработка обнаруженных NFC-меток
        for message in messages {
            processNDEFMessage(message)
        }
    }
    
    private func processNDEFMessage(_ message: NFCNDEFMessage) {
        for record in message.records {
            if let payload = String(data: record.payload, encoding: .utf8) {
                print("NFC Payload: \(payload)")
                
                // Создание информации о метке
                let tagInfo = NFCTagInfo(
                    uid: generateRandomUID(),
                    atr: generateATR(),
                    cardType: .contactless,
                    protocol: .iso14443A,
                    isEmulated: false
                )
                
                processDetectedTag(tagInfo)
            }
        }
    }
}

// MARK: - Supporting Types
struct NFCTagInfo: Identifiable, Equatable {
    let id = UUID()
    let uid: Data
    let atr: Data
    let cardType: CardType
    let protocol: NFCProtocol
    let isEmulated: Bool
    
    enum CardType {
        case contactless
        case dualInterface
        case emv
        case mir
    }
    
    enum NFCProtocol {
        case iso14443A
        case iso14443B
        case feliCa
        case iso15693
    }
    
    static func == (lhs: NFCTagInfo, rhs: NFCTagInfo) -> Bool {
        return lhs.uid == rhs.uid
    }
}

struct TransactionInfo {
    let tag: NFCTagInfo
    let startTime: Date
    var endTime: Date?
    var amount: Double
    let merchantId: String
    var status: TransactionStatus
    var isCompleted: Bool = false
    var isSuccessful: Bool = false
    
    enum TransactionStatus {
        case initialized
        case authenticated
        case processing
        case completed
        case failed
    }
}
