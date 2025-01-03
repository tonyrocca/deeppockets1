import Foundation

public enum PayPeriod: String, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case semimonthly = "Semi-monthly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    public var multiplier: Double {
        switch self {
        case .weekly: return 52/12
        case .biweekly: return 26/12
        case .semimonthly: return 2
        case .monthly: return 1
        case .yearly: return 1/12
        }
    }
    
    public var payPeriodsPerYear: Int {
        switch self {
        case .weekly: return 52
        case .biweekly: return 26
        case .semimonthly: return 24
        case .monthly: return 12
        case .yearly: return 1
        }
    }
}
