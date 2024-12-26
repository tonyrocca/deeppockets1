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
                   let termStr = category.assumptions.first(where: { $0.title == "Loan Term" })?.value,
                   let term = Double(termStr) {
                    
                    // Using the 28% rule for mortgage payments
                    let maxMonthlyPayment = monthlyIncome * 0.28
                    let monthlyInterestRate = (interestRate / 100) / 12
                    let numberOfPayments = term * 12
                    
                    // Calculate maximum mortgage amount using the monthly payment formula
                    let mortgageAmount = maxMonthlyPayment *
                        ((pow(1 + monthlyInterestRate, numberOfPayments) - 1) /
                        (monthlyInterestRate * pow(1 + monthlyInterestRate, numberOfPayments)))
                    
                    // Calculate total house price including down payment
                    let totalPrice = mortgageAmount / (1 - (downPayment / 100))
                    return totalPrice
                }
                return monthlyIncome * 4 // Fallback calculation
                
            case "car":
                            // Car loan calculation
                            if let downPaymentStr = category.assumptions.first(where: { $0.title == "Down Payment" })?.value,
                               let downPayment = Double(downPaymentStr),
                               let interestRateStr = category.assumptions.first(where: { $0.title == "Interest Rate" })?.value,
                               let interestRate = Double(interestRateStr),
                               let termStr = category.assumptions.first(where: { $0.title == "Loan Term" })?.value,
                               let term = Double(termStr) {
                                
                                // Set aside some for insurance, gas, and maintenance
                                let operatingCosts = monthlyAmount * 0.3  // 30% of car budget for operating costs
                                let availableForPayment = monthlyAmount - operatingCosts
                                
                                let monthlyInterestRate = (interestRate / 100) / 12
                                let numberOfPayments = term * 12
                                
                                let loanAmount = availableForPayment *
                                    ((pow(1 + monthlyInterestRate, numberOfPayments) - 1) /
                                    (monthlyInterestRate * pow(1 + monthlyInterestRate, numberOfPayments)))
                                
                                let totalPrice = loanAmount / (1 - (downPayment / 100))
                                return totalPrice
                            }
                            return monthlyAmount * 12
                
            case "emergency_savings":
                // 6 months of essential expenses
                let essentialExpenses = calculateEssentialMonthlyExpenses()
                return essentialExpenses * 6
                
            case "vacation":
                // Annual vacation budget
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
    
    // Updated allocation percentages for take-home pay
    func getRecommendedAllocationPercentage(for category: BudgetCategory) -> Double {
        switch category.id {
        case "house": return 0.28  // Standard mortgage calculation rule
        case "rent": return 0.28   // Same as house
        case "car": return 0.15    // Including insurance, gas, maintenance
        case "groceries": return 0.12
        case "eating_out": return 0.06
        case "public_transportation": return 0.05
        case "emergency_savings": return 0.10
        case "pet": return 0.03
        case "restaurants": return 0.05
        case "clothes": return 0.04
        case "subscriptions": return 0.03
        case "gym": return 0.02
        case "investments": return 0.15
        case "home_supplies": return 0.03
        case "home_utilities": return 0.10
        case "college_savings": return 0.05
        case "vacation": return 0.05
        case "tickets": return 0.03
        case "medical": return 0.05
        case "credit_cards": return 0.10
        case "student_loans": return 0.10
        case "personal_loans": return 0.10
        case "car_loan": return 0.15
        case "charity": return 0.05
        default: return 0.02
        }
    }
}
