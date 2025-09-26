import Foundation
import CoreData

struct Transaction: Identifiable, Codable {
    let id = UUID()
    var amount: Double
    var currency: String
    var merchantName: String
    var cardId: UUID
    var status: TransactionStatus
    var timestamp: Date
    var description: String?
    var location: String?
    
    enum TransactionStatus: String, CaseIterable, Codable {
        case pending = "pending"
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
        
        var displayName: String {
            switch self {
            case .pending: return "В обработке"
            case .completed: return "Выполнено"
            case .failed: return "Ошибка"
            case .cancelled: return "Отменено"
            }
        }
        
        var color: String {
            switch self {
            case .pending: return "orange"
            case .completed: return "green"
            case .failed: return "red"
            case .cancelled: return "gray"
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "clock"
            case .completed: return "checkmark.circle"
            case .failed: return "xmark.circle"
            case .cancelled: return "slash.circle"
            }
        }
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currency)"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: timestamp)
    }
}

// Core Data Entity
@objc(TransactionEntity)
public class TransactionEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var amount: Double
    @NSManaged public var currency: String
    @NSManaged public var merchantName: String
    @NSManaged public var cardId: UUID
    @NSManaged public var status: String
    @NSManaged public var timestamp: Date
    @NSManaged public var transactionDescription: String?
    @NSManaged public var location: String?
}

extension TransactionEntity {
    func toTransaction() -> Transaction {
        return Transaction(
            amount: amount,
            currency: currency,
            merchantName: merchantName,
            cardId: cardId,
            status: TransactionStatus(rawValue: status) ?? .pending,
            timestamp: timestamp,
            description: transactionDescription,
            location: location
        )
    }
    
    func updateFromTransaction(_ transaction: Transaction) {
        self.id = transaction.id
        self.amount = transaction.amount
        self.currency = transaction.currency
        self.merchantName = transaction.merchantName
        self.cardId = transaction.cardId
        self.status = transaction.status.rawValue
        self.timestamp = transaction.timestamp
        self.transactionDescription = transaction.description
        self.location = transaction.location
    }
} 