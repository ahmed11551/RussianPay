import Foundation
import CoreData

struct Card: Identifiable, Codable {
    let id = UUID()
    var cardNumber: String
    var cardholderName: String
    var expiryMonth: Int
    var expiryYear: Int
    var cvv: String
    var bankName: String
    var cardType: CardType
    var isDefault: Bool
    var createdAt: Date
    
    enum CardType: String, CaseIterable, Codable {
        case visa = "Visa"
        case mastercard = "Mastercard"
        case mir = "МИР"
        case unionpay = "UnionPay"
        
        var icon: String {
            switch self {
            case .visa: return "creditcard"
            case .mastercard: return "creditcard.fill"
            case .mir: return "creditcard.circle"
            case .unionpay: return "creditcard.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .visa: return "blue"
            case .mastercard: return "orange"
            case .mir: return "red"
            case .unionpay: return "green"
            }
        }
    }
    
    var maskedNumber: String {
        let lastFour = String(cardNumber.suffix(4))
        return "•••• •••• •••• \(lastFour)"
    }
    
    var expiryDate: String {
        return String(format: "%02d/%d", expiryMonth, expiryYear % 100)
    }
    
    var isValid: Bool {
        return cardNumber.count == 16 && 
               expiryMonth >= 1 && expiryMonth <= 12 &&
               expiryYear >= 2024 &&
               cvv.count == 3
    }
}

// Core Data Entity
@objc(CardEntity)
public class CardEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var cardNumber: String
    @NSManaged public var cardholderName: String
    @NSManaged public var expiryMonth: Int16
    @NSManaged public var expiryYear: Int16
    @NSManaged public var cvv: String
    @NSManaged public var bankName: String
    @NSManaged public var cardType: String
    @NSManaged public var isDefault: Bool
    @NSManaged public var createdAt: Date
}

extension CardEntity {
    func toCard() -> Card {
        return Card(
            cardNumber: cardNumber,
            cardholderName: cardholderName,
            expiryMonth: Int(expiryMonth),
            expiryYear: Int(expiryYear),
            cvv: cvv,
            bankName: bankName,
            cardType: CardType(rawValue: cardType) ?? .visa,
            isDefault: isDefault,
            createdAt: createdAt
        )
    }
    
    func updateFromCard(_ card: Card) {
        self.id = card.id
        self.cardNumber = card.cardNumber
        self.cardholderName = card.cardholderName
        self.expiryMonth = Int16(card.expiryMonth)
        self.expiryYear = Int16(card.expiryYear)
        self.cvv = card.cvv
        self.bankName = card.bankName
        self.cardType = card.cardType.rawValue
        self.isDefault = card.isDefault
        self.createdAt = card.createdAt
    }
} 