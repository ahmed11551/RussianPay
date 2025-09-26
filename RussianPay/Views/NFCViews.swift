import SwiftUI

// MARK: - NFC Status View
struct NFCStatusView: View {
    @ObservedObject var nfcEmulator: NFCEmulator
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: statusIcon)
                    .font(.title)
                    .foregroundColor(statusColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Статус NFC")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Индикатор состояния
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text(nfcEmulator.isEmulating ? "Эмуляция активна" : "Эмуляция неактивна")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusIcon: String {
        switch nfcEmulator.connectionStatus {
        case .connected:
            return "checkmark.circle.fill"
        case .connecting:
            return "clock.fill"
        case .error:
            return "xmark.circle.fill"
        case .disconnected:
            return "circle"
        }
    }
    
    private var statusColor: Color {
        switch nfcEmulator.connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .error:
            return .red
        case .disconnected:
            return .gray
        }
    }
    
    private var statusText: String {
        switch nfcEmulator.connectionStatus {
        case .connected:
            return "Подключено"
        case .connecting:
            return "Подключение..."
        case .error(let message):
            return "Ошибка: \(message)"
        case .disconnected:
            return "Отключено"
        }
    }
}

// MARK: - Protocol Selector View
struct ProtocolSelectorView: View {
    @Binding var selectedProtocol: NFCEmulator.NFCProtocol
    @Binding var showingPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Протокол NFC")
                .font(.headline)
                .fontWeight(.medium)
            
            Button(action: { showingPicker = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedProtocol.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(selectedProtocol.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Protocol Picker View
struct ProtocolPickerView: View {
    @Binding var selectedProtocol: NFCEmulator.NFCProtocol
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(NFCEmulator.NFCProtocol.allCases, id: \.self) { protocol in
                Button(action: {
                    selectedProtocol = protocol
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(protocol.rawValue)
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Text(protocol.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedProtocol == protocol {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Выбор протокола")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - NFC Control Buttons View
struct NFCControlButtonsView: View {
    @ObservedObject var nfcEmulator: NFCEmulator
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Управление")
                .font(.headline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                // Кнопка запуска эмуляции
                Button(action: {
                    nfcEmulator.startEmulation(protocol: nfcEmulator.currentProtocol)
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        
                        Text("Запустить")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .disabled(nfcEmulator.isEmulating)
                .buttonStyle(PlainButtonStyle())
                
                // Кнопка остановки эмуляции
                Button(action: {
                    nfcEmulator.stopEmulation()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        Text("Остановить")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .disabled(!nfcEmulator.isEmulating)
                .buttonStyle(PlainButtonStyle())
            }
            
            // Дополнительные кнопки
            HStack(spacing: 16) {
                Button(action: {
                    nfcEmulator.emulateTag(cardData: CardData(
                        cardNumber: "1234567890123456",
                        expiryDate: "12/25",
                        cvv: "123",
                        cardholderName: "IVAN IVANOV",
                        bankName: "Sberbank"
                    ))
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "creditcard.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Эмуляция карты")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    nfcEmulator.emulateReader()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("Эмуляция ридера")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Alternative Methods View
struct AlternativeMethodsView: View {
    @ObservedObject var nfcEmulator: NFCEmulator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Альтернативные методы")
                .font(.headline)
                .fontWeight(.medium)
            
            VStack(spacing: 12) {
                // Bluetooth
                HStack {
                    Image(systemName: "bluetooth")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bluetooth Low Energy")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Альтернативная связь через BLE")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Включить") {
                        // Логика включения BLE
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Wi-Fi Direct
                HStack {
                    Image(systemName: "wifi")
                        .font(.title2)
                        .foregroundColor(.green)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Wi-Fi Direct")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Прямое соединение Wi-Fi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Включить") {
                        // Логика включения Wi-Fi Direct
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
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
