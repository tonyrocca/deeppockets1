import SwiftUI
import Combine

// MARK: - AffordabilityModel
class AffordabilityModel: ObservableObject {
    @Published var monthlyIncome: Double = 0
    @Published var categories: [BudgetCategory] = []
    @Published var affordabilityAmounts: [String: Double] = [:]
    @Published var assumptions: [String: [CategoryAssumption]] = [:]

    private let store = BudgetCategoryStore.shared
    
    // Financial constants for calculations
    private let constants = FinancialConstants(
        mortgageRatios: (frontend: 0.28, backend: 0.36),
        emergencyMultipliers: ["low_risk": 3.0, "medium_risk": 6.0, "high_risk": 9.0],
        inflationRate: 0.04,
        propertyAppreciation: 0.035,
        vehicleDepreciation: 0.15,
        investmentReturns: ["conservative": 0.06, "moderate": 0.08, "aggressive": 0.10]
    )
    
    // MARK: - Public Methods
    
    /// Updates the assumptions for a given category and triggers a recalculation.
    func updateAssumptions(for categoryId: String, assumptions: [CategoryAssumption]) {
        if let index = store.categories.firstIndex(where: { $0.id == categoryId }) {
            store.categories[index].assumptions = assumptions
            self.assumptions[categoryId] = assumptions

            let newAmount = calculateAffordableAmount(for: store.categories[index])
            store.categories[index].recommendedAmount = newAmount
            affordabilityAmounts[categoryId] = newAmount

            DispatchQueue.main.async {
                self.objectWillChange.send() // Force real-time UI refresh
            }
        }
    }
    
    /// Calculates an affordability amount for a category and rounds the result to one decimal.
    func calculateAffordableAmount(for category: BudgetCategory) -> Double {
        let monthlyAmount = monthlyIncome * category.allocationPercentage
        let totalDebtPayments = calculateTotalDebtPayments()
        let debtToIncomeRatio = (monthlyIncome > 0) ? totalDebtPayments / monthlyIncome : 0.0
        
        let rawAmount: Double
        
        // If the category is "home_maintenance", use a distinct formula.
        if category.id == "home_maintenance" {
            rawAmount = calculateHomeMaintenanceAffordability(for: category, debtToIncomeRatio: debtToIncomeRatio)
        }
        else {
            switch category.displayType {
            case .monthly:
                rawAmount = adjustMonthlyAmount(monthlyAmount, for: category)
            case .total:
                rawAmount = calculateTotalAffordability(category: category,
                                                        monthlyAmount: monthlyAmount,
                                                        debtToIncomeRatio: debtToIncomeRatio)
            }
        }
        return roundToTenth(rawAmount)
    }
    
    // MARK: - Category-Specific Calculations
    
    /// Calculates total affordability for categories that use a “total” display type.
    private func calculateTotalAffordability(category: BudgetCategory, monthlyAmount: Double, debtToIncomeRatio: Double) -> Double {
        // Use assumptions from the model if available; otherwise, fall back on category defaults.
        let currentAssumptions = assumptions[category.id] ?? category.assumptions
        let downPayment = getAssumptionValue(currentAssumptions, title: "Down Payment") ?? 20.0
        let interestRate = getAssumptionValue(currentAssumptions, title: "Interest Rate") ?? 7.0
        let propertyTax = getAssumptionValue(currentAssumptions, title: "Property Tax Rate") ?? 1.1
        
        switch category.type {
        case .housing:
            return calculateHouseAffordability(monthlyAmount: monthlyAmount,
                                               debtToIncomeRatio: debtToIncomeRatio,
                                               downPayment: downPayment,
                                               interestRate: interestRate,
                                               propertyTax: propertyTax)
        case .transportation:
            return calculateCarAffordability(monthlyAmount: monthlyAmount,
                                             debtToIncomeRatio: debtToIncomeRatio,
                                             interestRate: interestRate)
        case .savings:
            return calculateSavingsGoal(for: category, monthlyAmount: monthlyAmount)
        case .debt:
            return calculateDebtRepaymentPlan(for: category, monthlyAmount: monthlyAmount)
        case .utilities, .food, .entertainment, .insurance, .education, .personal, .health, .family, .other:
            // For these categories, use simple monthly * 12 calculation
            return monthlyAmount * 12
        }
    }
    
    /// Calculates home affordability using a detailed mortgage formula.
    private func calculateHouseAffordability(monthlyAmount: Double, debtToIncomeRatio: Double, downPayment: Double, interestRate: Double, propertyTax: Double) -> Double {
        // Determine the maximum debt-to-income ratio available for a mortgage
        let maxDTI = constants.mortgageRatios.backend
        let availableDTI = maxDTI - debtToIncomeRatio
        // Use the smaller of the frontend ratio or what is available based on current debt load
        let effectiveRatio = min(constants.mortgageRatios.frontend, availableDTI)
        let adjustedMaxPayment = monthlyIncome * effectiveRatio
        
        // Estimate monthly taxes and insurance (assume an annual rate of 1.5%)
        let taxAndInsuranceMonthly = (adjustedMaxPayment * 0.015) / 12.0
        let effectivePayment = adjustedMaxPayment - taxAndInsuranceMonthly
        
        let monthlyRate = (interestRate / 100) / 12
        let numberOfPayments = 30.0 * 12
        let numerator = pow(1 + monthlyRate, numberOfPayments) - 1
        let denominator = monthlyRate * pow(1 + monthlyRate, numberOfPayments)
        let mortgageAmount = effectivePayment * (numerator / denominator)
        let totalPrice = mortgageAmount / (1 - (downPayment / 100))
        
        // Project property appreciation over 5 years
        let futureValue = totalPrice * pow(1 + constants.propertyAppreciation, 5)
        return futureValue
    }
    
    /// Calculates car affordability using a simplified loan formula.
    private func calculateCarAffordability(monthlyAmount: Double, debtToIncomeRatio: Double, interestRate: Double) -> Double {
        let loanTermMonths: Double = 60.0
        let interestRateDecimal = interestRate / 100.0
        let monthlyPayment = (monthlyAmount * interestRateDecimal) / loanTermMonths
        // Adjust for debt load (if any)
        return monthlyPayment / (1 - debtToIncomeRatio)
    }
    
    /// Calculates a savings goal amount based on the target and timeline.
    private func calculateSavingsGoal(for category: BudgetCategory, monthlyAmount: Double) -> Double {
        let savingsTarget = category.savingsGoal ?? 0
        let monthsToSave = category.savingsTimeline ?? 12
        return min(savingsTarget, monthlyAmount * Double(monthsToSave))
    }
    
    /// Calculates the debt repayment plan amount.
    private func calculateDebtRepaymentPlan(for category: BudgetCategory, monthlyAmount: Double) -> Double {
        let remainingDebt = category.debtAmount ?? 0
        let interestRate = category.debtInterestRate ?? 7.0
        let minimumPayment = (remainingDebt * (interestRate / 100.0)) / 12.0
        return max(minimumPayment, monthlyAmount)
    }
    
    /// Special calculation for home maintenance.
    private func calculateHomeMaintenanceAffordability(for category: BudgetCategory, debtToIncomeRatio: Double) -> Double {
        // Look for the main home category and use its numbers to estimate maintenance.
        if let homeCategory = store.categories.first(where: { $0.id == "home" }) {
            let homeMonthlyAmount = monthlyIncome * homeCategory.allocationPercentage
            let homeAssumptions = assumptions[homeCategory.id] ?? homeCategory.assumptions
            let downPayment = getAssumptionValue(homeAssumptions, title: "Down Payment") ?? 20.0
            let interestRate = getAssumptionValue(homeAssumptions, title: "Interest Rate") ?? 7.0
            let propertyTax = getAssumptionValue(homeAssumptions, title: "Property Tax Rate") ?? 1.1
            
            let homePrice = calculateHouseAffordability(monthlyAmount: homeMonthlyAmount,
                                                        debtToIncomeRatio: debtToIncomeRatio,
                                                        downPayment: downPayment,
                                                        interestRate: interestRate,
                                                        propertyTax: propertyTax)
            // For example, assume maintenance is 1% of home price per year (divided by 12 for monthly)
            return (homePrice * 0.01) / 12.0
        }
        // Fallback if home category is missing
        return monthlyIncome * category.allocationPercentage * 12
    }
    
    // MARK: - Helper Functions
    
    /// Adjusts the monthly amount by an income-level multiplier.
    private func adjustMonthlyAmount(_ amount: Double, for category: BudgetCategory) -> Double {
        let multiplier = determineIncomeLevel(monthlyIncome).multiplier
        return amount * multiplier
    }
    
    /// Sums the recommended amounts for debt-related categories.
    private func calculateTotalDebtPayments() -> Double {
        let debtCategories = ["credit_cards", "student_loans", "personal_loans", "car_loan"]
        return store.categories.filter { debtCategories.contains($0.id) }
                               .reduce(0) { $0 + $1.recommendedAmount }
    }
    
    /// Retrieves a numeric value from a set of assumptions based on its title.
    private func getAssumptionValue(_ assumptions: [CategoryAssumption], title: String) -> Double? {
        if let valueStr = assumptions.first(where: { $0.title == title })?.value,
           let value = Double(valueStr) {
            return value
        }
        return nil
    }
    
    /// Rounds a given value to one decimal place.
    private func roundToTenth(_ value: Double) -> Double {
        return (value * 10).rounded() / 10.0
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
    /// Determines the income level based on annual income.
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
