import Foundation

enum AssumptionInputType {
    case percentageSlider(step: Double)
    case yearSlider(min: Int, max: Int)
    case textField
    case percentageDistribution
}

struct CategoryAssumption: Identifiable {
    let title: String
    var value: String
    let inputType: AssumptionInputType
    let description: String?
    var id: String { title }
}

enum AmountDisplayType {
    case monthly
    case total
}

enum CategoryType {
    case housing
    case transportation
    case savings
    case debt
    case utilities
    case food
    case entertainment
    case insurance
    case education
    case personal
    case other
}

struct BudgetCategory: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let allocationPercentage: Double
    var recommendedAmount: Double = 0
    let displayType: AmountDisplayType
    var assumptions: [CategoryAssumption]
    let type: CategoryType  // Added `type` to categorize affordability logic

    // Optional Properties (Fixing missing `savingsGoal` issue)
    var savingsGoal: Double?
    var savingsTimeline: Int?
    var debtAmount: Double?
    var debtInterestRate: Double?

    var formattedAllocation: String {
        let percentage = allocationPercentage * 100
        return String(format: "%.1f%%", percentage)
    }
}

extension CategoryAssumption {
    var displayValue: String {
        switch inputType {
        case .percentageSlider:
            return value + "%"
        case .yearSlider:
            return value + " years"
        default:
            return value
        }
    }
}

extension BudgetCategory {
    mutating func calculateRecommendedAmount(monthlyIncome: Double) {
        switch type {
        case .housing:
            recommendedAmount = calculateHousingAffordability(monthlyIncome: monthlyIncome)

        case .transportation:
            recommendedAmount = calculateCarAffordability(monthlyIncome: monthlyIncome)

        case .savings:
            recommendedAmount = calculateSavingsGoal(monthlyIncome: monthlyIncome)

        case .debt:
            recommendedAmount = calculateDebtRepayment(monthlyIncome: monthlyIncome)

        case .utilities, .food, .entertainment, .insurance, .education, .personal, .other:
            recommendedAmount = monthlyIncome * allocationPercentage * 12
        }
    }

    private func calculateHousingAffordability(monthlyIncome: Double) -> Double {
        guard let interestRateStr = assumptions.first(where: { $0.title == "Interest Rate" })?.value,
              let downPaymentStr = assumptions.first(where: { $0.title == "Down Payment" })?.value,
              let interestRate = Double(interestRateStr),
              let downPayment = Double(downPaymentStr) else {
            return monthlyIncome * 4 // Default to 4x income if missing values
        }
        
        let monthlyPayment = monthlyIncome * allocationPercentage
        let monthlyRate = (interestRate / 100) / 12
        let numberOfPayments = 30.0 * 12

        let loanAmount = monthlyPayment * ((pow(1 + monthlyRate, numberOfPayments) - 1) /
                                           (monthlyRate * pow(1 + monthlyRate, numberOfPayments)))
        
        return loanAmount / (1 - (downPayment / 100))
    }

    private func calculateCarAffordability(monthlyIncome: Double) -> Double {
        let baseCarBudget = monthlyIncome * allocationPercentage * 12
        let depreciation = 0.15 // Annual depreciation
        return baseCarBudget * (1 - depreciation)
    }

    private func calculateSavingsGoal(monthlyIncome: Double) -> Double {
        guard let savingsGoal = savingsGoal, let monthsToSave = savingsTimeline else {
            return monthlyIncome * allocationPercentage * 12
        }
        return min(savingsGoal, monthlyIncome * allocationPercentage * Double(monthsToSave))
    }

    private func calculateDebtRepayment(monthlyIncome: Double) -> Double {
        guard let debtAmount = debtAmount, let interestRate = debtInterestRate else {
            return monthlyIncome * allocationPercentage
        }
        let monthlyPayment = (debtAmount * (interestRate / 100)) / 12
        return max(monthlyPayment, monthlyIncome * allocationPercentage)
    }
}
