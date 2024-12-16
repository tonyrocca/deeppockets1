import SwiftUI

class AffordabilityModel: ObservableObject {
    @Published var monthlyIncome: Double = 0
    private let store = BudgetCategoryStore.shared
    
    func calculateAffordableAmount(for category: BudgetCategory) -> Double {
        let monthlyAmount = monthlyIncome * category.allocationPercentage
        
        switch category.displayType {
        case .monthly:
            // Monthly categories return their direct monthly allocation
            return monthlyAmount
            
        case .total:
            // Total categories need a special calculation
            switch category.id {
            case "emergency_savings":
                // Emergency fund should cover 6 months of essential expenses
                let essentialExpenses = calculateEssentialMonthlyExpenses()
                return essentialExpenses * 6
                
            case "vacation":
                // Annual vacation budget (12 months accumulation)
                return monthlyAmount * 12
                
            default:
                // Default total: accumulate over a year
                return monthlyAmount * 12
            }
        }
    }
    
    private func calculateEssentialMonthlyExpenses() -> Double {
        // Define which categories are considered "essential"
        // This can vary, but commonly: housing (mortgage or rent), groceries, home utilities, car, and public transportation.
        let essentialCategories = ["mortgage", "rent", "car", "groceries", "home_utilities", "public_transportation"]
        
        return essentialCategories.reduce(0.0) { total, categoryId in
            if let category = store.category(for: categoryId) {
                return total + (monthlyIncome * category.allocationPercentage)
            }
            return total
        }
    }
    
    func calculateAnnualIncome() -> Double {
        return monthlyIncome * 12
    }
    
    // Helper method to get recommended allocation percentages for the new categories
    func getRecommendedAllocationPercentage(for category: BudgetCategory) -> Double {
        switch category.id {
        case "mortgage": return 0.20           // Mortgage ~20% of income
        case "rent": return 0.20               // Rent ~20% (used instead of mortgage)
        case "car": return 0.10                // Car expenses ~10%
        case "groceries": return 0.10           // Groceries ~10%
        case "eating_out": return 0.05          // Quick meals out ~5%
        case "public_transportation": return 0.05 // Public transit ~5%, if used instead of car
        case "emergency_savings": return 0.05   // Emergency savings ~5% until funded
        case "pet": return 0.02                // Pet expenses ~2%
        case "restaurants": return 0.05         // Dining at restaurants (more formal) ~5%
        case "clothes": return 0.03             // Clothes ~3%
        case "subscriptions": return 0.02       // Subscriptions ~2%
        case "gym": return 0.02                 // Gym & fitness ~2%
        case "investments": return 0.05         // Investments (non-retirement) ~5%
        case "home_supplies": return 0.02       // Home supplies ~2%
        case "home_utilities": return 0.08      // Home utilities ~8%
        case "college_savings": return 0.02     // College savings ~2%
        case "vacation": return 0.03            // Vacation fund ~3%
        case "tickets": return 0.02             // Tickets (events) ~2%
        default: return 0.01                   // Default fallback
        }
    }
}
