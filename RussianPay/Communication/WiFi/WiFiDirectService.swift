import Foundation
import Network

/// Wi-Fi Direct сервис для передачи платежных данных между устройствами
class WiFiDirectService: NSObject, ObservableObject {
    
    // MARK: - Properties
    @Published var isHosting = false
    @Published var isConnected = false
    @Published var connectedHost: NWEndpoint?
    
    private var listener: NWListener?
    private var connection: NWConnection?
    private let serviceType = "russianpay-wifi"
    private let port: NWEndpoint.Port = 8888
    
    // MARK: - Hosting (Server)
    func startHosting() {
        do {
            listener = try NWListener(using: .tcp, on: port)
        } catch {
            print("Ошибка запуска Wi-Fi Direct сервера: \(error)")
            return
        }
        
        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                self.isHosting = true
                print("🟢 Wi-Fi Direct сервер запущен на порту \(self.port)")
            case .failed(let error):
                print("❌ Ошибка сервера: \(error)")
                self.isHosting = false
            default:
                break
            }
        }
        
        listener?.newConnectionHandler = { [weak self] newConnection in
            self?.connection = newConnection
            self?.setupConnectionHandlers(newConnection)
            newConnection.start(queue: .main)
            self?.isConnected = true
            print("🔗 Установлено новое Wi-Fi Direct соединение")
        }
        
        listener?.start(queue: .main)
    }
    
    func stopHosting() {
        listener?.cancel()
        listener = nil
        isHosting = false
        isConnected = false
        print("🛑 Wi-Fi Direct сервер остановлен")
    }
    
    // MARK: - Connecting (Client)
    func connectToHost(host: NWEndpoint.Host) {
        connection = NWConnection(host: host, port: port, using: .tcp)
        setupConnectionHandlers(connection)
        connection?.start(queue: .main)
        print("🔗 Подключение к Wi-Fi Direct хосту: \(host)")
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
        print("🔌 Wi-Fi Direct соединение разорвано")
    }
    
    // MARK: - Data Transfer
    func sendPaymentData(_ data: Data) {
        guard let connection = connection else { return }
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("❌ Ошибка отправки данных: \(error)")
            } else {
                print("💸 Платежные данные отправлены через Wi-Fi Direct")
            }
        })
    }
    
    private func setupConnectionHandlers(_ connection: NWConnection?) {
        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                self.isConnected = true
                print("🟢 Wi-Fi Direct соединение готово")
            case .failed(let error):
                print("❌ Ошибка соединения: \(error)")
                self.isConnected = false
            case .cancelled:
                self.isConnected = false
            default:
                break
            }
        }
        receiveNextMessage(connection)
    }
    
    private func receiveNextMessage(_ connection: NWConnection?) {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self.handleReceivedData(data)
            }
            if isComplete == false && error == nil {
                self.receiveNextMessage(connection)
            }
        }
    }
    
    private func handleReceivedData(_ data: Data) {
        // Обработка полученных платежных данных
        print("💳 Получены данные через Wi-Fi Direct: \(data.count) байт")
        // Здесь можно добавить декодирование и обработку платежа
    }
} 