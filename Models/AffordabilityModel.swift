import SwiftUI

class AffordabilityModel: ObservableObject {
    @Published var monthlyIncome: Double = 0
    @Published var categories: [BudgetCategory] = []
    private let store = BudgetCategoryStore.shared
    
    func calculateAffordableAmount(for category: BudgetCategory) -> Double {
        let monthlyAmount = monthlyIncome * category.allocationPercentage
        
        switch category.displayType {
        case .monthly:
            // Straightforward monthly allocation
            return monthlyAmount
            
        case .total:
            // Handle large "total" categories differently by their IDs
            switch category.id {
                
            case "house":
                // House/mortgage calculation
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
                        ((pow(1 + monthlyInterestRate, numberOfPayments) - 1)
                        / (monthlyInterestRate * pow(1 + monthlyInterestRate, numberOfPayments)))
                    
                    // Calculate total house price including down payment
                    let totalPrice = mortgageAmount / (1 - (downPayment / 100))
                    return totalPrice
                }
                // Fallback if assumptions aren’t set
                return monthlyIncome * 4
                
            case "car":
                // Car loan calculation
                if let downPaymentStr = category.assumptions.first(where: { $0.title == "Down Payment" })?.value,
                   let downPayment = Double(downPaymentStr),
                   let interestRateStr = category.assumptions.first(where: { $0.title == "Interest Rate" })?.value,
                   let interestRate = Double(interestRateStr),
                   let termStr = category.assumptions.first(where: { $0.title == "Loan Term" })?.value,
                   let term = Double(termStr) {
                    
                    // Reserve ~30% of the car category for operating costs (insurance, gas, maintenance)
                    let operatingCosts = monthlyAmount * 0.3
                    let availableForPayment = monthlyAmount - operatingCosts
                    
                    let monthlyInterestRate = (interestRate / 100) / 12
                    let numberOfPayments = term * 12
                    
                    // Standard monthly payment formula
                    let loanAmount = availableForPayment *
                        ((pow(1 + monthlyInterestRate, numberOfPayments) - 1)
                        / (monthlyInterestRate * pow(1 + monthlyInterestRate, numberOfPayments)))
                    
                    let totalPrice = loanAmount / (1 - (downPayment / 100))
                    return totalPrice
                }
                // Fallback if assumptions aren’t set
                return monthlyAmount * 12
                
            case "emergency_savings":
                // Emergency fund based on “Months Coverage”
                if let monthsCoverageStr = category.assumptions.first(where: { $0.title == "Months Coverage" })?.value,
                   let monthsCoverage = Double(monthsCoverageStr) {
                    
                    // Approximate essential expenses
                    let housing    = monthlyIncome * 0.28
                    let utilities  = monthlyIncome * 0.08
                    let food       = monthlyIncome * 0.12
                    let healthcare = monthlyIncome * 0.05
                    let transport  = monthlyIncome * 0.10
                    
                    let essentialMonthly = housing + utilities + food + healthcare + transport
                    return essentialMonthly * monthsCoverage
                }
                // Default fallback = 3 months
                return monthlyIncome * 3
                
            case "college_savings":
                // Simplistic “college cost” model
                if let yearsToStr = category.assumptions.first(where: { $0.title == "Years to College" })?.value,
                   let yearsTo = Double(yearsToStr) {
                    
                    let currentYearCost = 22_690.0  // Average annual cost at a public university
                    let inflationRate   = 0.05      // ~5% annual increase
                    let futureYearCost  = currentYearCost * pow(1 + inflationRate, yearsTo)
                    let totalCost       = futureYearCost * 4  // 4 years of college
                    
                    // Divide by # years and months to get monthly target
                    let monthlyContribution = (totalCost / yearsTo) / 12
                    return monthlyContribution
                }
                return monthlyAmount  // Fallback
                
            case "vacation":
                // Multiply the annual budget by a “destination type” factor
                if let destinationTypeStr = category.assumptions.first(where: { $0.title == "Destination Type" })?.value {
                    let multiplier: Double
                    switch destinationTypeStr {
                    case "Domestic":       multiplier = 1.0
                    case "International":  multiplier = 2.0
                    case "Luxury":         multiplier = 3.0
                    default:               multiplier = 1.0
                    }
                    return monthlyAmount * 12 * multiplier
                }
                // Fallback = 1x annual
                return monthlyAmount * 12
                
            default:
                // Default total: 12x monthly category allocation
                return monthlyAmount * 12
            }
        }
    }
    
    // Called when user changes assumption sliders/textfields in a category
    func updateAssumptions(for categoryId: String, assumptions: [CategoryAssumption]) {
        if let index = store.categories.firstIndex(where: { $0.id == categoryId }) {
            store.categories[index].assumptions = assumptions
            objectWillChange.send()
        }
    }
    
    private func calculateEssentialMonthlyExpenses() -> Double {
        // Example essential category list
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
    
    // Example method for recommended allocation
    func getRecommendedAllocationPercentage(for category: BudgetCategory) -> Double {
        switch category.id {
        case "house":          return 0.28
        case "rent":           return 0.28
        case "car":            return 0.15
        case "groceries":      return 0.12
        case "eating_out":     return 0.06
        case "public_transportation": return 0.05
        case "emergency_savings":     return 0.10
        case "pet":            return 0.03
        case "restaurants":    return 0.05
        case "clothes":        return 0.04
        case "subscriptions":  return 0.03
        case "gym":            return 0.02
        case "investments":    return 0.15
        case "home_supplies":  return 0.03
        case "home_utilities": return 0.10
        case "college_savings":return 0.05
        case "vacation":       return 0.05
        case "tickets":        return 0.03
        case "medical":        return 0.05
        case "credit_cards":   return 0.10
        case "student_loans":  return 0.10
        case "personal_loans": return 0.10
        case "car_loan":       return 0.15
        case "charity":        return 0.05
        default:               return 0.02
        }
    }
}
