import SwiftUI
import CoreData

/// Форма для совершения платежа
struct PaymentSheetView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State Properties
    @State private var amount: String = ""
    @State private var merchantName: String = ""
    @State private var description: String = ""
    @State private var selectedCard: Card?
    @State private var paymentMethod: PaymentMethod = .nfc
    @State private var isProcessing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var paymentResult: PaymentResult?
    
    // MARK: - Available Cards
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CardEntity.isDefault, ascending: false)],
        animation: .default)
    private var cards: FetchedResults<CardEntity>
    
    // MARK: - Payment Methods
    enum PaymentMethod: String, CaseIterable {
        case nfc = "NFC"
        case applePay = "Apple Pay"
        case bluetooth = "Bluetooth"
        case wifi = "Wi-Fi Direct"
        case qr = "QR-код"
        
        var icon: String {
            switch self {
            case .nfc: return "wave.3.right"
            case .applePay: return "applelogo"
            case .bluetooth: return "bluetooth"
            case .wifi: return "wifi"
            case .qr: return "qrcode"
            }
        }
        
        var description: String {
            switch self {
            case .nfc: return "Бесконтактная оплата"
            case .applePay: return "Apple Pay"
            case .bluetooth: return "Bluetooth Low Energy"
            case .wifi: return "Wi-Fi Direct"
            case .qr: return "QR-код"
            }
        }
    }
    
    // MARK: - Payment Result
    enum PaymentResult {
        case success(Transaction)
        case failure(String)
        case cancelled
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Информация о платеже
                Section("Информация о платеже") {
                    // Сумма
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Сумма")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        HStack {
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("₽")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Название мерчанта
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Название мерчанта")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("Магазин", text: $merchantName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Описание
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Описание")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("Товары и услуги", text: $description)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Выбор карты
                Section("Карта для оплаты") {
                    if cards.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("Нет доступных карт")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Добавьте карту для совершения платежа")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ForEach(cards, id: \.id) { cardEntity in
                            let card = cardEntity.toCard()
                            Button(action: {
                                selectedCard = card
                            }) {
                                HStack {
                                    CardRowView(card: card)
                                    
                                    Spacer()
                                    
                                    if selectedCard?.id == card.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Способ оплаты
                Section("Способ оплаты") {
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        Button(action: {
                            paymentMethod = method
                        }) {
                            HStack {
                                Image(systemName: method.icon)
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(method.rawValue)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    Text(method.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if paymentMethod == method {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Предварительный просмотр платежа
                if !amount.isEmpty && !merchantName.isEmpty {
                    Section("Предварительный просмотр") {
                        PaymentPreviewView(
                            amount: amount,
                            merchantName: merchantName,
                            description: description,
                            card: selectedCard,
                            paymentMethod: paymentMethod
                        )
                    }
                }
            }
            .navigationTitle("Оплата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Оплатить") {
                        processPayment()
                    }
                    .disabled(!isFormValid || isProcessing)
                }
            }
            .alert("Результат платежа", isPresented: $showingAlert) {
                Button("OK") {
                    if case .success = paymentResult {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                if selectedCard == nil && !cards.isEmpty {
                    selectedCard = cards.first?.toCard()
                }
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        return !amount.isEmpty &&
               !merchantName.isEmpty &&
               selectedCard != nil &&
               !isProcessing
    }
    
    // MARK: - Payment Processing
    
    private func processPayment() {
        guard let card = selectedCard else { return }
        
        isProcessing = true
        
        // Валидация суммы
        guard let paymentAmount = Double(amount.replacingOccurrences(of: ",", with: ".")),
              paymentAmount > 0 else {
            showAlert("Неверная сумма платежа")
            return
        }
        
        // Создание транзакции
        let transaction = Transaction(
            amount: paymentAmount,
            currency: "RUB",
            merchantName: merchantName,
            cardId: card.id,
            status: .pending,
            timestamp: Date(),
            description: description.isEmpty ? nil : description
        )
        
        // Обработка платежа в зависимости от выбранного метода
        switch paymentMethod {
        case .nfc:
            processNFCPayment(transaction: transaction, card: card)
        case .applePay:
            processApplePayPayment(transaction: transaction, card: card)
        case .bluetooth:
            processBluetoothPayment(transaction: transaction, card: card)
        case .wifi:
            processWiFiPayment(transaction: transaction, card: card)
        case .qr:
            processQRPayment(transaction: transaction, card: card)
        }
    }
    
    private func processNFCPayment(transaction: Transaction, card: Card) {
        // Эмуляция NFC платежа
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let successTransaction = Transaction(
                amount: transaction.amount,
                currency: transaction.currency,
                merchantName: transaction.merchantName,
                cardId: transaction.cardId,
                status: .completed,
                timestamp: Date(),
                description: transaction.description
            )
            
            saveTransaction(successTransaction)
            paymentResult = .success(successTransaction)
            showAlert("Платеж успешно выполнен!")
        }
    }
    
    private func processApplePayPayment(transaction: Transaction, card: Card) {
        // Эмуляция Apple Pay платежа
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let successTransaction = Transaction(
                amount: transaction.amount,
                currency: transaction.currency,
                merchantName: transaction.merchantName,
                cardId: transaction.cardId,
                status: .completed,
                timestamp: Date(),
                description: transaction.description
            )
            
            saveTransaction(successTransaction)
            paymentResult = .success(successTransaction)
            showAlert("Платеж через Apple Pay успешно выполнен!")
        }
    }
    
    private func processBluetoothPayment(transaction: Transaction, card: Card) {
        // Эмуляция Bluetooth платежа
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let successTransaction = Transaction(
                amount: transaction.amount,
                currency: transaction.currency,
                merchantName: transaction.merchantName,
                cardId: transaction.cardId,
                status: .completed,
                timestamp: Date(),
                description: transaction.description
            )
            
            saveTransaction(successTransaction)
            paymentResult = .success(successTransaction)
            showAlert("Платеж через Bluetooth успешно выполнен!")
        }
    }
    
    private func processWiFiPayment(transaction: Transaction, card: Card) {
        // Эмуляция Wi-Fi Direct платежа
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            let successTransaction = Transaction(
                amount: transaction.amount,
                currency: transaction.currency,
                merchantName: transaction.merchantName,
                cardId: transaction.cardId,
                status: .completed,
                timestamp: Date(),
                description: transaction.description
            )
            
            saveTransaction(successTransaction)
            paymentResult = .success(successTransaction)
            showAlert("Платеж через Wi-Fi Direct успешно выполнен!")
        }
    }
    
    private func processQRPayment(transaction: Transaction, card: Card) {
        // Эмуляция QR-код платежа
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let successTransaction = Transaction(
                amount: transaction.amount,
                currency: transaction.currency,
                merchantName: transaction.merchantName,
                cardId: transaction.cardId,
                status: .completed,
                timestamp: Date(),
                description: transaction.description
            )
            
            saveTransaction(successTransaction)
            paymentResult = .success(successTransaction)
            showAlert("Платеж через QR-код успешно выполнен!")
        }
    }
    
    private func saveTransaction(_ transaction: Transaction) {
        let transactionEntity = TransactionEntity(context: viewContext)
        transactionEntity.updateFromTransaction(transaction)
        
        do {
            try viewContext.save()
        } catch {
            print("Ошибка сохранения транзакции: \(error)")
        }
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
        isProcessing = false
    }
}

// MARK: - Payment Preview View
struct PaymentPreviewView: View {
    let amount: String
    let merchantName: String
    let description: String
    let card: Card?
    let paymentMethod: PaymentSheetView.PaymentMethod
    
    var body: some View {
        VStack(spacing: 16) {
            // Сумма
            HStack {
                Text("Сумма:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(amount) ₽")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            // Мерчант
            HStack {
                Text("Мерчант:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(merchantName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            // Описание
            if !description.isEmpty {
                HStack {
                    Text("Описание:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            // Карта
            if let card = card {
                HStack {
                    Text("Карта:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: card.cardType.icon)
                            .foregroundColor(Color(card.cardType.color))
                        Text(card.maskedNumber)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            
            // Способ оплаты
            HStack {
                Text("Способ:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack {
                    Image(systemName: paymentMethod.icon)
                        .foregroundColor(.blue)
                    Text(paymentMethod.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Card Row View (используем существующий)
struct CardRowView: View {
    let card: Card
    
    var body: some View {
        HStack {
            Image(systemName: card.cardType.icon)
                .font(.title2)
                .foregroundColor(Color(card.cardType.color))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.maskedNumber)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(card.cardholderName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(card.expiryDate) • \(card.bankName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if card.isDefault {
                Text("По умолчанию")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct PaymentSheetView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSheetView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
