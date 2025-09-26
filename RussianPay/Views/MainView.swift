import SwiftUI
import CoreData

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var nfcEmulator = NFCEmulator()
    @StateObject private var applePayEmulator = ApplePayEmulator(
        cryptoEngine: CryptoEngine(),
        keyManager: KeyManager()
    )
    
    @State private var selectedTab = 0
    @State private var showingAddCard = false
    @State private var showingPaymentSheet = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Главная вкладка - Карты
            CardsTabView()
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Карты")
                }
                .tag(0)
            
            // Вкладка NFC
            NFCTabView(nfcEmulator: nfcEmulator)
                .tabItem {
                    Image(systemName: "wave.3.right")
                    Text("NFC")
                }
                .tag(1)
            
            // Вкладка Apple Pay
            ApplePayTabView(applePayEmulator: applePayEmulator)
                .tabItem {
                    Image(systemName: "applelogo")
                    Text("Apple Pay")
                }
                .tag(2)
            
            // Вкладка транзакций
            TransactionsTabView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Транзакции")
                }
                .tag(3)
            
            // Вкладка настроек
            SettingsTabView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Настройки")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .sheet(isPresented: $showingAddCard) {
            AddCardView()
        }
        .sheet(isPresented: $showingPaymentSheet) {
            PaymentSheetView()
        }
    }
}

// MARK: - Cards Tab
struct CardsTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CardEntity.createdAt, ascending: false)],
        animation: .default)
    private var cards: FetchedResults<CardEntity>
    
    @State private var showingAddCard = false
    
    var body: some View {
        NavigationView {
            List {
                if cards.isEmpty {
                    EmptyCardsView()
                } else {
                    ForEach(cards, id: \.id) { cardEntity in
                        CardRowView(card: cardEntity.toCard())
                    }
                    .onDelete(perform: deleteCards)
                }
            }
            .navigationTitle("Мои карты")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCard = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCard) {
                AddCardView()
            }
        }
    }
    
    private func deleteCards(offsets: IndexSet) {
        withAnimation {
            offsets.map { cards[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                print("Ошибка удаления карты: \(error)")
            }
        }
    }
}

// MARK: - NFC Tab
struct NFCTabView: View {
    @ObservedObject var nfcEmulator: NFCEmulator
    @State private var selectedProtocol: NFCEmulator.NFCProtocol = .iso14443A
    @State private var showingProtocolPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Статус NFC
                NFCStatusView(nfcEmulator: nfcEmulator)
                
                // Выбор протокола
                ProtocolSelectorView(
                    selectedProtocol: $selectedProtocol,
                    showingPicker: $showingProtocolPicker
                )
                
                // Кнопки управления
                NFCControlButtonsView(nfcEmulator: nfcEmulator)
                
                // Альтернативные методы
                AlternativeMethodsView(nfcEmulator: nfcEmulator)
                
                Spacer()
            }
            .padding()
            .navigationTitle("NFC Эмулятор")
            .sheet(isPresented: $showingProtocolPicker) {
                ProtocolPickerView(selectedProtocol: $selectedProtocol)
            }
        }
    }
}

// MARK: - Apple Pay Tab
struct ApplePayTabView: View {
    @ObservedObject var applePayEmulator: ApplePayEmulator
    @State private var amount: String = ""
    @State private var merchantId: String = "com.russianpay.merchant"
    @State private var description: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Статус Apple Pay
                ApplePayStatusView(applePayEmulator: applePayEmulator)
                
                // Форма платежа
                PaymentFormView(
                    amount: $amount,
                    merchantId: $merchantId,
                    description: $description
                )
                
                // Кнопка оплаты
                ApplePayButtonView(
                    applePayEmulator: applePayEmulator,
                    amount: amount,
                    merchantId: merchantId,
                    description: description
                )
                
                // Интеграция с Wallet
                WalletIntegrationView(applePayEmulator: applePayEmulator)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Apple Pay")
        }
    }
}

// MARK: - Transactions Tab
struct TransactionsTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TransactionEntity.timestamp, ascending: false)],
        animation: .default)
    private var transactions: FetchedResults<TransactionEntity>
    
    var body: some View {
        NavigationView {
            List {
                if transactions.isEmpty {
                    EmptyTransactionsView()
                } else {
                    ForEach(transactions, id: \.id) { transactionEntity in
                        TransactionRowView(transaction: transactionEntity.toTransaction())
                    }
                }
            }
            .navigationTitle("Транзакции")
        }
    }
}

// MARK: - Settings Tab
struct SettingsTabView: View {
    @AppStorage("username") private var username: String = ""
    @AppStorage("autoConnect") private var autoConnect: Bool = true
    @AppStorage("debugMode") private var debugMode: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Профиль") {
                    TextField("Имя пользователя", text: $username)
                }
                
                Section("NFC") {
                    Toggle("Автоподключение", isOn: $autoConnect)
                    Toggle("Режим отладки", isOn: $debugMode)
                }
                
                Section("Безопасность") {
                    Button("Сменить ключи") {
                        // Логика смены ключей
                    }
                    Button("Очистить данные") {
                        // Логика очистки
                    }
                }
                
                Section("О приложении") {
                    HStack {
                        Text("Версия")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Настройки")
        }
    }
}

// MARK: - Supporting Views
struct EmptyCardsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Нет добавленных карт")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Добавьте свою первую карту для начала работы")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct EmptyTransactionsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Нет транзакций")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Здесь будут отображаться все ваши платежи")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

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

struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchantName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(transaction.description ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(transaction.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.formattedAmount)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    Image(systemName: transaction.status.icon)
                        .foregroundColor(Color(transaction.status.color))
                    Text(transaction.status.displayName)
                        .font(.caption)
                        .foregroundColor(Color(transaction.status.color))
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

