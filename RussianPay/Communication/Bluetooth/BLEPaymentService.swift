import Foundation
import CoreBluetooth
import CryptoKit

/// Bluetooth Low Energy сервис для альтернативной связи
class BLEPaymentService: NSObject, ObservableObject {
    
    // MARK: - Properties
    @Published var isAdvertising = false
    @Published var isScanning = false
    @Published var connectedDevices: [CBPeripheral] = []
    @Published var discoveredDevices: [CBPeripheral] = []
    
    private var centralManager: CBCentralManager?
    private var peripheralManager: CBPeripheralManager?
    private var discoveredPeripheral: CBPeripheral?
    
    // Характеристики для платежей
    private var paymentCharacteristic: CBMutableCharacteristic?
    private var responseCharacteristic: CBMutableCharacteristic?
    
    // Сервис UUID
    private let paymentServiceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
    private let paymentCharacteristicUUID = CBUUID(string: "87654321-4321-4321-4321-CBA987654321")
    private let responseCharacteristicUUID = CBUUID(string: "11111111-2222-3333-4444-555555555555")
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupBluetooth()
    }
    
    // MARK: - Setup
    
    private func setupBluetooth() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Advertising (Peripheral Mode)
    
    /// Запуск рекламы как периферийное устройство
    func startAdvertising() {
        guard let peripheralManager = peripheralManager,
              peripheralManager.state == .poweredOn else {
            print("Peripheral Manager не готов")
            return
        }
        
        // Создание сервиса
        let service = CBMutableService(type: paymentServiceUUID, primary: true)
        
        // Создание характеристик
        paymentCharacteristic = CBMutableCharacteristic(
            type: paymentCharacteristicUUID,
            properties: [.write, .writeWithoutResponse],
            value: nil,
            permissions: [.writeable]
        )
        
        responseCharacteristic = CBMutableCharacteristic(
            type: responseCharacteristicUUID,
            properties: [.read, .notify],
            value: nil,
            permissions: [.readable]
        )
        
        // Добавление характеристик к сервису
        service.characteristics = [paymentCharacteristic!, responseCharacteristic!]
        
        // Добавление сервиса
        peripheralManager.add(service)
        
        // Настройка рекламы
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [paymentServiceUUID],
            CBAdvertisementDataLocalNameKey: "RussianPay",
            CBAdvertisementDataManufacturerDataKey: "RussianPay".data(using: .utf8) ?? Data()
        ]
        
        // Запуск рекламы
        peripheralManager.startAdvertising(advertisementData)
        isAdvertising = true
        
        print("🔵 BLE реклама запущена")
    }
    
    /// Остановка рекламы
    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()
        isAdvertising = false
        print("🔵 BLE реклама остановлена")
    }
    
    // MARK: - Scanning (Central Mode)
    
    /// Запуск сканирования устройств
    func startScanning() {
        guard let centralManager = centralManager,
              centralManager.state == .poweredOn else {
            print("Central Manager не готов")
            return
        }
        
        // Очистка списка устройств
        discoveredDevices.removeAll()
        
        // Запуск сканирования
        centralManager.scanForPeripherals(
            withServices: [paymentServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
        isScanning = true
        print("🔍 BLE сканирование запущено")
    }
    
    /// Остановка сканирования
    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
        print("🔍 BLE сканирование остановлено")
    }
    
    // MARK: - Connection Management
    
    /// Подключение к устройству
    func connect(to peripheral: CBPeripheral) {
        centralManager?.connect(peripheral, options: nil)
        discoveredPeripheral = peripheral
        print("🔗 Подключение к \(peripheral.name ?? "Unknown")")
    }
    
    /// Отключение от устройства
    func disconnect() {
        if let peripheral = discoveredPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
            discoveredPeripheral = nil
            print("🔗 Отключение от устройства")
        }
    }
    
    // MARK: - Payment Operations
    
    /// Отправка платежных данных
    func sendPaymentData(_ paymentData: PaymentData) {
        guard let peripheral = discoveredPeripheral,
              let characteristic = paymentCharacteristic else {
            print("❌ Нет подключения для отправки данных")
            return
        }
        
        // Кодирование данных платежа
        let encodedData = encodePaymentData(paymentData)
        
        // Отправка данных
        peripheral.writeValue(
            encodedData,
            for: characteristic,
            type: .withResponse
        )
        
        print("💳 Отправка платежных данных через BLE")
    }
    
    /// Получение ответа на платеж
    func receivePaymentResponse() -> PaymentResponse? {
        guard let characteristic = responseCharacteristic,
              let value = characteristic.value else {
            return nil
        }
        
        return decodePaymentResponse(value)
    }
    
    // MARK: - Data Encoding/Decoding
    
    private func encodePaymentData(_ paymentData: PaymentData) -> Data {
        var data = Data()
        
        // Добавление заголовка
        data.append("PAYMENT".data(using: .utf8) ?? Data())
        
        // Добавление суммы
        let amountBytes = withUnsafeBytes(of: paymentData.amount) { Data($0) }
        data.append(amountBytes)
        
        // Добавление ID мерчанта
        data.append(paymentData.merchantId.data(using: .utf8) ?? Data())
        
        // Добавление временной метки
        let timestamp = Date().timeIntervalSince1970
        let timestampBytes = withUnsafeBytes(of: timestamp) { Data($0) }
        data.append(timestampBytes)
        
        // Добавление подписи
        if let signature = createSignature(for: data) {
            data.append(signature)
        }
        
        return data
    }
    
    private func decodePaymentResponse(_ data: Data) -> PaymentResponse? {
        guard data.count >= 8 else { return nil }
        
        // Извлечение статуса
        let statusBytes = data.prefix(4)
        let status = String(data: statusBytes, encoding: .utf8) ?? "UNKNOWN"
        
        // Извлечение суммы
        let amountBytes = data.dropFirst(4).prefix(8)
        let amount = amountBytes.withUnsafeBytes { $0.load(as: Double.self) }
        
        // Извлечение ID транзакции
        let transactionIdBytes = data.dropFirst(12).prefix(16)
        let transactionId = transactionIdBytes.map { String(format: "%02X", $0) }.joined()
        
        return PaymentResponse(
            status: status,
            amount: amount,
            transactionId: transactionId,
            timestamp: Date()
        )
    }
    
    private func createSignature(for data: Data) -> Data? {
        // Создание подписи для данных
        let key = SymmetricKey(size: .bits256)
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return Data(signature)
    }
    
    // MARK: - Utility Methods
    
    /// Проверка доступности Bluetooth
    var isBluetoothAvailable: Bool {
        return centralManager?.state == .poweredOn
    }
    
    /// Получение состояния Bluetooth
    var bluetoothState: CBManagerState {
        return centralManager?.state ?? .unknown
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEPaymentService: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("🔵 Bluetooth включен")
        case .poweredOff:
            print("🔵 Bluetooth выключен")
        case .unauthorized:
            print("🔵 Bluetooth не авторизован")
        case .unsupported:
            print("🔵 Bluetooth не поддерживается")
        case .resetting:
            print("🔵 Bluetooth перезагружается")
        case .unknown:
            print("🔵 Bluetooth состояние неизвестно")
        @unknown default:
            print("🔵 Bluetooth неизвестное состояние")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Обнаружение устройства
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
            print("🔍 Обнаружено устройство: \(peripheral.name ?? "Unknown")")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Успешное подключение
        peripheral.delegate = self
        peripheral.discoverServices([paymentServiceUUID])
        
        if !connectedDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            connectedDevices.append(peripheral)
        }
        
        print("🔗 Подключено к \(peripheral.name ?? "Unknown")")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Ошибка подключения к \(peripheral.name ?? "Unknown"): \(error?.localizedDescription ?? "Unknown error")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        // Отключение устройства
        connectedDevices.removeAll { $0.identifier == peripheral.identifier }
        print("🔗 Отключено от \(peripheral.name ?? "Unknown")")
    }
}

// MARK: - CBPeripheralDelegate
extension BLEPaymentService: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("❌ Ошибка обнаружения сервисов: \(error!.localizedDescription)")
            return
        }
        
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(
                [paymentCharacteristicUUID, responseCharacteristicUUID],
                for: service
            )
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("❌ Ошибка обнаружения характеристик: \(error!.localizedDescription)")
            return
        }
        
        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid == responseCharacteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("❌ Ошибка обновления значения: \(error!.localizedDescription)")
            return
        }
        
        if characteristic.uuid == responseCharacteristicUUID {
            // Обработка ответа на платеж
            if let response = decodePaymentResponse(characteristic.value ?? Data()) {
                print("💳 Получен ответ на платеж: \(response.status)")
            }
        }
    }
}

// MARK: - CBPeripheralManagerDelegate
extension BLEPaymentService: CBPeripheralManagerDelegate {
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("🔵 Peripheral Manager готов")
        case .poweredOff:
            print("🔵 Peripheral Manager выключен")
        case .unauthorized:
            print("🔵 Peripheral Manager не авторизован")
        case .unsupported:
            print("🔵 Peripheral Manager не поддерживается")
        case .resetting:
            print("🔵 Peripheral Manager перезагружается")
        case .unknown:
            print("🔵 Peripheral Manager состояние неизвестно")
        @unknown default:
            print("🔵 Peripheral Manager неизвестное состояние")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == paymentCharacteristicUUID {
                // Обработка входящих платежных данных
                if let paymentData = decodePaymentData(request.value) {
                    print("💳 Получены платежные данные: \(paymentData.amount)")
                    
                    // Отправка ответа
                    let response = createPaymentResponse(for: paymentData)
                    request.value = encodePaymentResponse(response)
                    peripheral.respond(to: request, withResult: .success)
                }
            }
        }
    }
    
    private func decodePaymentData(_ data: Data) -> PaymentData? {
        // Декодирование платежных данных
        guard data.count >= 16 else { return nil }
        
        let amountBytes = data.dropFirst(7).prefix(8)
        let amount = amountBytes.withUnsafeBytes { $0.load(as: Double.self) }
        
        let merchantIdData = data.dropFirst(15)
        let merchantId = String(data: merchantIdData, encoding: .utf8) ?? ""
        
        return PaymentData(amount: amount, merchantId: merchantId)
    }
    
    private func createPaymentResponse(for paymentData: PaymentData) -> PaymentResponse {
        return PaymentResponse(
            status: "SUCCESS",
            amount: paymentData.amount,
            transactionId: generateTransactionId(),
            timestamp: Date()
        )
    }
    
    private func encodePaymentResponse(_ response: PaymentResponse) -> Data {
        var data = Data()
        
        // Статус
        data.append(response.status.data(using: .utf8) ?? Data())
        
        // Сумма
        let amountBytes = withUnsafeBytes(of: response.amount) { Data($0) }
        data.append(amountBytes)
        
        // ID транзакции
        data.append(response.transactionId.data(using: .utf8) ?? Data())
        
        return data
    }
    
    private func generateTransactionId() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return String(uuid.prefix(16))
    }
}

// MARK: - Supporting Types
struct PaymentData {
    let amount: Double
    let merchantId: String
}

struct PaymentResponse {
    let status: String
    let amount: Double
    let transactionId: String
    let timestamp: Date
} 