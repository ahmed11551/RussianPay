import SwiftUI
import CoreData

/// Форма добавления новой банковской карты
struct AddCardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State Properties
    @State private var cardNumber: String = ""
    @State private var cardholderName: String = ""
    @State private var expiryMonth: Int = 1
    @State private var expiryYear: Int = 2024
    @State private var cvv: String = ""
    @State private var bankName: String = ""
    @State private var cardType: Card.CardType = .visa
    @State private var isDefault: Bool = false
    
    // MARK: - Validation
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isValidating = false
    
    // MARK: - Available Options
    private let months = Array(1...12)
    private let years = Array(2024...2030)
    private let banks = ["Сбербанк", "ВТБ", "Альфа-Банк", "Тинькофф", "Газпромбанк", "Райффайзенбанк", "Открытие", "Россельхозбанк"]
    
    var body: some View {
        NavigationView {
            Form {
                // Информация о карте
                Section("Информация о карте") {
                    // Номер карты
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Номер карты")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("1234 5678 9012 3456", text: $cardNumber)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: cardNumber) { newValue in
                                cardNumber = formatCardNumber(newValue)
                                cardType = detectCardType(cardNumber)
                            }
                        
                        // Индикатор типа карты
                        HStack {
                            Image(systemName: cardType.icon)
                                .foregroundColor(Color(cardType.color))
                            Text(cardType.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Имя держателя карты
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Имя держателя карты")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        TextField("IVAN IVANOV", text: $cardholderName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                    }
                }
                
                // Срок действия
                Section("Срок действия") {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Месяц")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Picker("Месяц", selection: $expiryMonth) {
                                ForEach(months, id: \.self) { month in
                                    Text(String(format: "%02d", month))
                                        .tag(month)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 100)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Год")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Picker("Год", selection: $expiryYear) {
                                ForEach(years, id: \.self) { year in
                                    Text(String(year))
                                        .tag(year)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(height: 100)
                        }
                    }
                }
                
                // Безопасность
                Section("Безопасность") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CVV")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        SecureField("123", text: $cvv)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: cvv) { newValue in
                                if newValue.count > 3 {
                                    cvv = String(newValue.prefix(3))
                                }
                            }
                    }
                }
                
                // Банк
                Section("Банк") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Банк")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Picker("Банк", selection: $bankName) {
                            ForEach(banks, id: \.self) { bank in
                                Text(bank)
                                    .tag(bank)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // Настройки
                Section("Настройки") {
                    Toggle("Карта по умолчанию", isOn: $isDefault)
                        .font(.headline)
                        .fontWeight(.medium)
                }
                
                // Предварительный просмотр карты
                Section("Предварительный просмотр") {
                    CardPreviewView(
                        cardNumber: cardNumber,
                        cardholderName: cardholderName,
                        expiryMonth: expiryMonth,
                        expiryYear: expiryYear,
                        cardType: cardType,
                        bankName: bankName
                    )
                }
            }
            .navigationTitle("Добавить карту")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        saveCard()
                    }
                    .disabled(!isFormValid || isValidating)
                }
            }
            .alert("Ошибка", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        return cardNumber.count >= 16 &&
               cardholderName.count >= 3 &&
               cvv.count == 3 &&
               !bankName.isEmpty &&
               !isValidating
    }
    
    // MARK: - Helper Methods
    
    private func formatCardNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        let chunks = cleaned.chunked(into: 4)
        return chunks.joined(separator: " ")
    }
    
    private func detectCardType(_ number: String) -> Card.CardType {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        
        if cleaned.hasPrefix("4") {
            return .visa
        } else if cleaned.hasPrefix("5") || cleaned.hasPrefix("2") {
            return .mastercard
        } else if cleaned.hasPrefix("2") {
            return .mir
        } else if cleaned.hasPrefix("6") {
            return .unionpay
        }
        
        return .visa
    }
    
    private func saveCard() {
        isValidating = true
        
        // Валидация номера карты
        guard validateCardNumber(cardNumber) else {
            showAlert("Неверный номер карты")
            return
        }
        
        // Валидация CVV
        guard validateCVV(cvv) else {
            showAlert("Неверный CVV код")
            return
        }
        
        // Валидация срока действия
        guard validateExpiryDate(month: expiryMonth, year: expiryYear) else {
            showAlert("Карта просрочена")
            return
        }
        
        // Создание новой карты
        let newCard = Card(
            cardNumber: cardNumber.replacingOccurrences(of: " ", with: ""),
            cardholderName: cardholderName.uppercased(),
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cvv: cvv,
            bankName: bankName,
            cardType: cardType,
            isDefault: isDefault,
            createdAt: Date()
        )
        
        // Сохранение в Core Data
        saveCardToCoreData(newCard)
    }
    
    private func validateCardNumber(_ number: String) -> Bool {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        
        // Проверка длины
        guard cleaned.count == 16 else { return false }
        
        // Проверка на цифры
        guard cleaned.allSatisfy({ $0.isNumber }) else { return false }
        
        // Алгоритм Луна
        return luhnCheck(cleaned)
    }
    
    private func validateCVV(_ cvv: String) -> Bool {
        return cvv.count == 3 && cvv.allSatisfy({ $0.isNumber })
    }
    
    private func validateExpiryDate(month: Int, year: Int) -> Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        if year < currentYear {
            return false
        } else if year == currentYear && month < currentMonth {
            return false
        }
        
        return true
    }
    
    private func luhnCheck(_ number: String) -> Bool {
        var sum = 0
        var alternate = false
        
        for character in number.reversed() {
            guard let digit = Int(String(character)) else { return false }
            
            var value = digit
            if alternate {
                value *= 2
                if value > 9 {
                    value = (value % 10) + 1
                }
            }
            
            sum += value
            alternate.toggle()
        }
        
        return sum % 10 == 0
    }
    
    private func saveCardToCoreData(_ card: Card) {
        let cardEntity = CardEntity(context: viewContext)
        cardEntity.updateFromCard(card)
        
        // Если это карта по умолчанию, снять флаг с других карт
        if isDefault {
            let request: NSFetchRequest<CardEntity> = CardEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isDefault == YES")
            
            do {
                let existingDefaultCards = try viewContext.fetch(request)
                for existingCard in existingDefaultCards {
                    existingCard.isDefault = false
                }
            } catch {
                print("Ошибка поиска карт по умолчанию: \(error)")
            }
        }
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            showAlert("Ошибка сохранения карты: \(error.localizedDescription)")
        }
        
        isValidating = false
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
        isValidating = false
    }
}

// MARK: - Card Preview View
struct CardPreviewView: View {
    let cardNumber: String
    let cardholderName: String
    let expiryMonth: Int
    let expiryYear: Int
    let cardType: Card.CardType
    let bankName: String
    
    var body: some View {
        VStack(spacing: 16) {
            // Карта
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(cardType.color).opacity(0.8),
                                Color(cardType.color).opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 200)
                    .shadow(radius: 8)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Логотип банка
                    HStack {
                        Text(bankName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: cardType.icon)
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Номер карты
                    Text(formatCardNumber(cardNumber))
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    // Имя держателя и срок действия
                    HStack {
                        Text(cardholderName.uppercased())
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(String(format: "%02d/%d", expiryMonth, expiryYear % 100))
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                .padding(20)
            }
            
            // Информация о карте
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Тип карты:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(cardType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Банк:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(bankName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func formatCardNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        let chunks = cleaned.chunked(into: 4)
        return chunks.joined(separator: " ")
    }
}

// MARK: - String Extension
extension String {
    func chunked(into size: Int) -> [String] {
        return stride(from: 0, to: count, by: size).map {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: min(size, count - $0))
            return String(self[start..<end])
        }
    }
}

// MARK: - Preview
struct AddCardView_Previews: PreviewProvider {
    static var previews: some View {
        AddCardView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
