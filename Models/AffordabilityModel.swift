import SwiftUI

class AffordabilityModel: ObservableObject {
    @Published var monthlyIncome: Double = 0
    @Published var categories: [BudgetCategory] = []
    @Published var affordabilityAmounts: [String: Double] = [:]

    private let store = BudgetCategoryStore.shared
    @Published var assumptions: [String: [CategoryAssumption]] = [:]

    // Financial Constants for calculations
    private let constants = FinancialConstants(
        mortgageRatios: (frontend: 0.28, backend: 0.36),
        emergencyMultipliers: ["low_risk": 3.0, "medium_risk": 6.0, "high_risk": 9.0],
        inflationRate: 0.04,
        propertyAppreciation: 0.035,
        vehicleDepreciation: 0.15,
        investmentReturns: ["conservative": 0.06, "moderate": 0.08, "aggressive": 0.10]
    )

    // MARK: - Update Assumptions & Trigger Real-time UI Updates
    func updateAssumptions(for categoryId: String, assumptions: [CategoryAssumption]) {
        if let index = store.categories.firstIndex(where: { $0.id == categoryId }) {
            store.categories[index].assumptions = assumptions
            self.assumptions[categoryId] = assumptions

            // **Force recalculation of affordability**
            let newAmount = calculateAffordableAmount(for: store.categories[index])
            store.categories[index].recommendedAmount = newAmount
            affordabilityAmounts[categoryId] = newAmount  // Ensure UI refresh

            DispatchQueue.main.async {
                self.objectWillChange.send()  // **Force real-time UI refresh**
            }
        }
    }

    // MARK: - Universal Affordability Calculation
    func calculateAffordableAmount(for category: BudgetCategory) -> Double {
        let monthlyAmount = monthlyIncome * category.allocationPercentage
        let totalDebtPayments = calculateTotalDebtPayments()
        let debtToIncomeRatio = totalDebtPayments / monthlyIncome

        switch category.displayType {
        case .monthly:
            return adjustMonthlyAmount(monthlyAmount, for: category)

        case .total:
            return calculateTotalAffordability(category: category,
                                               monthlyAmount: monthlyAmount,
                                               debtToIncomeRatio: debtToIncomeRatio)
        }
    }

    // MARK: - Dynamic Total Affordability Calculation for Any Category
    private func calculateTotalAffordability(category: BudgetCategory, monthlyAmount: Double, debtToIncomeRatio: Double) -> Double {
        let assumptions = assumptions[category.id] ?? category.assumptions
        let downPayment = getAssumptionValue(assumptions, title: "Down Payment") ?? 20.0
        let interestRate = getAssumptionValue(assumptions, title: "Interest Rate") ?? 7.0
        let propertyTax = getAssumptionValue(assumptions, title: "Property Tax Rate") ?? 1.1

        switch category.type {
        case .housing:
            return calculateHouseAffordability(monthlyAmount: monthlyAmount, debtToIncomeRatio: debtToIncomeRatio,
                                               downPayment: downPayment, interestRate: interestRate, propertyTax: propertyTax)

        case .transportation:
            return calculateCarAffordability(monthlyAmount: monthlyAmount, debtToIncomeRatio: debtToIncomeRatio,
                                             interestRate: interestRate)

        case .savings:
            return calculateSavingsGoal(for: category, monthlyAmount: monthlyAmount)

        case .debt:
            return calculateDebtRepaymentPlan(for: category, monthlyAmount: monthlyAmount)

        case .utilities, .food, .entertainment, .insurance, .education, .personal, .other:
            return monthlyAmount * 12  // Default calculation for other categories
        }
    }

    // MARK: - Category-Specific Affordability Calculations
    private func calculateHouseAffordability(monthlyAmount: Double, debtToIncomeRatio: Double, downPayment: Double, interestRate: Double, propertyTax: Double) -> Double {
        let maxDTI = constants.mortgageRatios.backend
        let availableDTI = maxDTI - debtToIncomeRatio
        let adjustedMaxPayment = monthlyIncome * min(constants.mortgageRatios.frontend, availableDTI)

        let taxAndInsurance = 0.015
        let effectivePayment = adjustedMaxPayment - (adjustedMaxPayment * taxAndInsurance / 12)
        let monthlyRate = (interestRate / 100) / 12
        let numberOfPayments = 30.0 * 12

        let numerator = pow(1 + monthlyRate, numberOfPayments) - 1
        let denominator = monthlyRate * pow(1 + monthlyRate, numberOfPayments)
        let mortgageAmount = effectivePayment * (numerator / denominator)

        let totalPrice = mortgageAmount / (1 - (downPayment / 100))
        return totalPrice * pow(1 + constants.propertyAppreciation, 5)
    }

    private func calculateCarAffordability(monthlyAmount: Double, debtToIncomeRatio: Double, interestRate: Double) -> Double {
        let loanTermMonths: Double = 60.0
        let interestRateDecimal = interestRate / 100.0
        let monthlyPayment = (monthlyAmount * interestRateDecimal) / loanTermMonths
        return monthlyPayment / (1 - debtToIncomeRatio)
    }

    private func calculateSavingsGoal(for category: BudgetCategory, monthlyAmount: Double) -> Double {
        let savingsTarget = category.savingsGoal ?? 0
        let monthsToSave = category.savingsTimeline ?? 12
        return min(savingsTarget, monthlyAmount * Double(monthsToSave))
    }

    private func calculateDebtRepaymentPlan(for category: BudgetCategory, monthlyAmount: Double) -> Double {
        let remainingDebt = category.debtAmount ?? 0
        let interestRate = category.debtInterestRate ?? 7.0
        let minimumPayment = (remainingDebt * (interestRate / 100.0)) / 12.0
        return max(minimumPayment, monthlyAmount)
    }

    // MARK: - Helper Functions
    private func adjustMonthlyAmount(_ amount: Double, for category: BudgetCategory) -> Double {
        let incomeLevel = determineIncomeLevel(monthlyIncome)
        return amount * incomeLevel.multiplier
    }

    private func calculateTotalDebtPayments() -> Double {
        let debtCategories = ["credit_cards", "student_loans", "personal_loans", "car_loan"]
        return store.categories.filter { debtCategories.contains($0.id) }
                               .reduce(0) { $0 + $1.recommendedAmount }
    }

    private func getAssumptionValue(_ assumptions: [CategoryAssumption], title: String) -> Double? {
        if let value = assumptions.first(where: { $0.title == title })?.value {
            return Double(value)
        }
        return nil
    }
}

// MARK: - Financial Constants Struct
private struct FinancialConstants {
    let mortgageRatios: (frontend: Double, backend: Double)
    let emergencyMultipliers: [String: Double]
    let inflationRate: Double
    let propertyAppreciation: Double
    let vehicleDepreciation: Double
    let investmentReturns: [String: Double]
}

// MARK: - Income Level Enum
private enum IncomeLevel {
    case low, moderate, high, veryHigh

    var multiplier: Double {
        switch self {
        case .low: return 0.9
        case .moderate: return 1.0
        case .high: return 1.1
        case .veryHigh: return 1.2
        }
    }
}

// MARK: - Extensions for Income and Location Adjustments
private extension AffordabilityModel {
    func determineIncomeLevel(_ monthlyIncome: Double) -> IncomeLevel {
        let annualIncome = monthlyIncome * 12
        switch annualIncome {
        case ..<50000: return .low
        case 50000..<100000: return .moderate
        case 100000..<200000: return .high
        default: return .veryHigh
        }
    }
}
