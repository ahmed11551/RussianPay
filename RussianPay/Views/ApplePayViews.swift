import SwiftUI
import PassKit

// MARK: - Apple Pay Status View
struct ApplePayStatusView: View {
    @ObservedObject var applePayEmulator: ApplePayEmulator
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: statusIcon)
                    .font(.title)
                    .foregroundColor(statusColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Pay")
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
                
                Text(applePayEmulator.isAvailable ? "Доступно" : "Недоступно")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Поддерживаемые сети
            if applePayEmulator.isAvailable {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Поддерживаемые сети:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(applePayEmulator.supportedNetworks, id: \.self) { network in
                            Text(network.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusIcon: String {
        return applePayEmulator.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    private var statusColor: Color {
        return applePayEmulator.isAvailable ? .green : .red
    }
    
    private var statusText: String {
        return applePayEmulator.isAvailable ? "Готов к использованию" : "Не поддерживается"
    }
}

// MARK: - Payment Form View
struct PaymentFormView: View {
    @Binding var amount: String
    @Binding var merchantId: String
    @Binding var description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Детали платежа")
                .font(.headline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Сумма
            VStack(alignment: .leading, spacing: 8) {
                Text("Сумма")
                    .font(.subheadline)
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
            
            // ID мерчанта
            VStack(alignment: .leading, spacing: 8) {
                Text("ID мерчанта")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("com.russianpay.merchant", text: $merchantId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Описание
            VStack(alignment: .leading, spacing: 8) {
                Text("Описание")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Товары и услуги", text: $description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Apple Pay Button View
struct ApplePayButtonView: View {
    @ObservedObject var applePayEmulator: ApplePayEmulator
    let amount: String
    let merchantId: String
    let description: String
    
    @State private var isProcessing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Оплата")
                .font(.headline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Apple Pay кнопка
            Button(action: {
                processApplePayPayment()
            }) {
                HStack {
                    Image(systemName: "applelogo")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Text("Оплатить через Apple Pay")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.black, .gray]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(12)
                .shadow(radius: 4)
            }
            .disabled(!isFormValid || isProcessing)
            .opacity(isFormValid ? 1.0 : 0.6)
            
            // Альтернативная кнопка
            if !applePayEmulator.isAvailable {
                Button(action: {
                    processAlternativePayment()
                }) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Оплатить картой")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .disabled(!isFormValid || isProcessing)
            }
            
            if isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Обработка платежа...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Результат платежа", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        return !amount.isEmpty &&
               !merchantId.isEmpty &&
               !description.isEmpty &&
               Double(amount.replacingOccurrences(of: ",", with: ".")) != nil
    }
    
    private func processApplePayPayment() {
        guard let paymentAmount = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            showAlert("Неверная сумма платежа")
            return
        }
        
        isProcessing = true
        
        // Создание запроса на оплату
        let request = applePayEmulator.createPaymentRequest(
            amount: paymentAmount,
            merchantId: merchantId,
            description: description
        )
        
        // Запуск процесса оплаты
        applePayEmulator.startPayment(request: request) { payment, error in
            DispatchQueue.main.async {
                isProcessing = false
                
                if let error = error {
                    showAlert("Ошибка платежа: \(error.localizedDescription)")
                } else if let payment = payment {
                    // Обработка успешного платежа
                    processSuccessfulPayment(payment: payment, amount: paymentAmount)
                }
            }
        }
    }
    
    private func processAlternativePayment() {
        isProcessing = true
        
        // Эмуляция альтернативного платежа
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isProcessing = false
            showAlert("Платеж успешно выполнен!")
        }
    }
    
    private func processSuccessfulPayment(payment: PKPayment, amount: Double) {
        // Генерация токена Apple Pay
        if let token = applePayEmulator.generatePaymentToken(
            for: payment,
            amount: amount,
            merchantId: merchantId
        ) {
            print("Apple Pay токен сгенерирован: \(token.token)")
        }
        
        showAlert("Платеж через Apple Pay успешно выполнен!")
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Wallet Integration View
struct WalletIntegrationView: View {
    @ObservedObject var applePayEmulator: ApplePayEmulator
    @State private var showingAddCard = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Интеграция с Wallet")
                .font(.headline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Статус Wallet
            HStack {
                Image(systemName: "wallet.pass.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Wallet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Управление картами")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Добавить карту") {
                    showingAddCard = true
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
            
            // Функции Wallet
            VStack(spacing: 12) {
                WalletFunctionRow(
                    icon: "creditcard.fill",
                    title: "Добавить карту",
                    description: "Добавить банковскую карту в Wallet",
                    action: { showingAddCard = true }
                )
                
                WalletFunctionRow(
                    icon: "trash.fill",
                    title: "Удалить карту",
                    description: "Удалить карту из Wallet",
                    action: { deleteCardFromWallet() }
                )
                
                WalletFunctionRow(
                    icon: "arrow.clockwise",
                    title: "Обновить карты",
                    description: "Синхронизировать с банком",
                    action: { updateCardsInWallet() }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingAddCard) {
            AddCardToWalletView(applePayEmulator: applePayEmulator)
        }
        .alert("Результат", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func deleteCardFromWallet() {
        // Эмуляция удаления карты из Wallet
        showAlert("Карта удалена из Wallet")
    }
    
    private func updateCardsInWallet() {
        // Эмуляция обновления карт в Wallet
        showAlert("Карты обновлены в Wallet")
    }
}

// MARK: - Wallet Function Row
struct WalletFunctionRow: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
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

// MARK: - Add Card to Wallet View
struct AddCardToWalletView: View {
    @ObservedObject var applePayEmulator: ApplePayEmulator
    @Environment(\.presentationMode) var presentationMode
    
    @State private var cardNumber: String = ""
    @State private var cardholderName: String = ""
    @State private var expiryDate: String = ""
    @State private var cvv: String = ""
    @State private var bankName: String = ""
    @State private var isProcessing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Данные карты") {
                    TextField("Номер карты", text: $cardNumber)
                        .keyboardType(.numberPad)
                    
                    TextField("Имя держателя", text: $cardholderName)
                        .autocapitalization(.allCharacters)
                    
                    TextField("Срок действия (MM/YY)", text: $expiryDate)
                        .keyboardType(.numberPad)
                    
                    SecureField("CVV", text: $cvv)
                        .keyboardType(.numberPad)
                    
                    TextField("Банк", text: $bankName)
                }
                
                Section("Предварительный просмотр") {
                    CardPreviewView(
                        cardNumber: cardNumber,
                        cardholderName: cardholderName,
                        expiryMonth: 12,
                        expiryYear: 2025,
                        cardType: .visa,
                        bankName: bankName
                    )
                }
            }
            .navigationTitle("Добавить в Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") {
                        addCardToWallet()
                    }
                    .disabled(!isFormValid || isProcessing)
                }
            }
            .alert("Результат", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("успешно") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        return !cardNumber.isEmpty &&
               !cardholderName.isEmpty &&
               !expiryDate.isEmpty &&
               !cvv.isEmpty &&
               !bankName.isEmpty
    }
    
    private func addCardToWallet() {
        isProcessing = true
        
        let cardData = CardData(
            cardNumber: cardNumber,
            expiryDate: expiryDate,
            cvv: cvv,
            cardholderName: cardholderName,
            bankName: bankName
        )
        
        // Добавление карты в Wallet
        if applePayEmulator.addCardToWallet(cardData: cardData) {
            showAlert("Карта успешно добавлена в Wallet!")
        } else {
            showAlert("Ошибка добавления карты в Wallet")
        }
        
        isProcessing = false
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Preview
struct ApplePayViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ApplePayStatusView(applePayEmulator: ApplePayEmulator(
                cryptoEngine: CryptoEngine(),
                keyManager: KeyManager()
            ))
            
            PaymentFormView(
                amount: .constant("100.00"),
                merchantId: .constant("com.russianpay.merchant"),
                description: .constant("Тестовый платеж")
            )
            
            ApplePayButtonView(
                applePayEmulator: ApplePayEmulator(
                    cryptoEngine: CryptoEngine(),
                    keyManager: KeyManager()
                ),
                amount: "100.00",
                merchantId: "com.russianpay.merchant",
                description: "Тестовый платеж"
            )
        }
        .padding()
    }
}
