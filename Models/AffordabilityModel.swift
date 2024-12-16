import SwiftUI

class AffordabilityModel: ObservableObject {
    @Published var monthlyIncome: Double = 0
    @Published var categories: [BudgetCategory] = []
    private let store = BudgetCategoryStore.shared
    
    func calculateAffordableAmount(for category: BudgetCategory) -> Double {
        let monthlyAmount = monthlyIncome * category.allocationPercentage
        
        switch category.displayType {
        case .monthly:
            return monthlyAmount
            
        case .total:
            switch category.id {
            case "house":
                if let downPaymentStr = category.assumptions.first(where: { $0.title == "Down Payment" })?.value,
                   let downPayment = Double(downPaymentStr),
                   let interestRateStr = category.assumptions.first(where: { $0.title == "Interest Rate" })?.value,
                   let interestRate = Double(interestRateStr),
                   let termStr = category.assumptions.first(where: { $0.title == "Loan Term (Years)" })?.value,
                   let term = Double(termStr) {
                    
                    let monthlyInterestRate = (interestRate / 100) / 12
                    let numberOfPayments = term * 12
                    let p = monthlyAmount
                    
                    let mortgageAmount = p * ((pow(1 + monthlyInterestRate, numberOfPayments) - 1) /
                                            (monthlyInterestRate * pow(1 + monthlyInterestRate, numberOfPayments)))
                    
                    let totalPrice = mortgageAmount / (1 - (downPayment / 100))
                    return totalPrice
                }
                return monthlyAmount * 12
                
            case "emergency_savings":
                let essentialExpenses = calculateEssentialMonthlyExpenses()
                return essentialExpenses * 6
                
            case "vacation":
                return monthlyAmount * 12
                
            default:
                return monthlyAmount * 12
            }
        }
    }
    
    func updateAssumptions(for categoryId: String, assumptions: [CategoryAssumption]) {
        if let index = store.categories.firstIndex(where: { $0.id == categoryId }) {
            store.categories[index].assumptions = assumptions
            objectWillChange.send()
        }
    }
    
    private func calculateEssentialMonthlyExpenses() -> Double {
        let essentialCategories = ["house", "rent", "car", "groceries", "home_utilities", "public_transportation"]
        
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
    
    func getRecommendedAllocationPercentage(for category: BudgetCategory) -> Double {
        switch category.id {
        case "house": return 0.20
        case "rent": return 0.20
        case "car": return 0.10
        case "groceries": return 0.10
        case "eating_out": return 0.05
        case "public_transportation": return 0.05
        case "emergency_savings": return 0.05
        case "pet": return 0.02
        case "restaurants": return 0.05
        case "clothes": return 0.03
        case "subscriptions": return 0.02
        case "gym": return 0.02
        case "investments": return 0.05
        case "home_supplies": return 0.02
        case "home_utilities": return 0.08
        case "college_savings": return 0.02
        case "vacation": return 0.03
        case "tickets": return 0.02
        default: return 0.01
        }
    }
}
