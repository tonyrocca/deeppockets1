import SwiftUI
import Combine

// MARK: - AffordabilityModel
class AffordabilityModel: ObservableObject {
    @Published var monthlyIncome: Double = 0
    @Published var categories: [BudgetCategory] = []
    @Published var affordabilityAmounts: [String: Double] = [:]
    @Published var assumptions: [String: [CategoryAssumption]] = [:]
    
    private let store = BudgetCategoryStore.shared
    
    // Improved financial constants with updated values and new adjustment factor for inflation.
    private let constants = FinancialConstants(
        mortgageRatios: (frontend: 0.28, backend: 0.36),
        emergencyMultipliers: ["low_risk": 3.0, "medium_risk": 6.0, "high_risk": 9.0],
        inflationRate: 0.03, // 3% inflation
        propertyAppreciation: 0.04, // 4% appreciation
        vehicleDepreciation: 0.20,  // 20% annual depreciation
        investmentReturns: ["conservative": 0.05, "moderate": 0.07, "aggressive": 0.09]
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
    
    /// Calculates an affordability amount for a given category using enhanced, differentiated logic.
    func calculateAffordableAmount(for category: BudgetCategory) -> Double {
        if category.id == "utilities" {
            return calculateUtilitiesAmount(for: category)
        }
        
        // Base allocation from income and category percentage
        let baseAllocation = monthlyIncome * category.allocationPercentage
        
        // Total debt payments affect discretionary capacity
        let totalDebtPayments = calculateTotalDebtPayments()
        let debtToIncomeRatio = monthlyIncome > 0 ? totalDebtPayments / monthlyIncome : 0.0
        
        let rawAmount: Double
        if category.id == "home_maintenance" {
            rawAmount = calculateHomeMaintenanceAffordability(for: category, debtToIncomeRatio: debtToIncomeRatio)
        } else {
            switch category.displayType {
            case .monthly:
                rawAmount = adjustMonthlyAmount(baseAllocation, for: category)
            case .total:
                rawAmount = calculateTotalAffordability(category: category, monthlyAmount: baseAllocation, debtToIncomeRatio: debtToIncomeRatio)
            }
        }
        
        // Apply an inflation adjustment for long-term goals (e.g. savings)
        let inflationAdjusted = category.type == .savings ? rawAmount * (1 + constants.inflationRate) : rawAmount
        
        return roundToTenth(inflationAdjusted)
    }
    
    // MARK: - Category-Specific Calculations
    
    private func calculateTotalAffordability(category: BudgetCategory, monthlyAmount: Double, debtToIncomeRatio: Double) -> Double {
        let currentAssumptions = assumptions[category.id] ?? category.assumptions
        let downPayment = getAssumptionValue(currentAssumptions, title: "Down Payment") ?? 20.0
        let interestRate = getAssumptionValue(currentAssumptions, title: "Interest Rate") ?? 7.0
        let propertyTax = getAssumptionValue(currentAssumptions, title: "Property Tax Rate") ?? 1.1
        
        switch category.type {
        case .housing:
            return calculateHomeAffordability(category, monthlyIncome: monthlyIncome)
        case .transportation:
            return calculateCarAffordability(category, monthlyIncome: monthlyIncome)
        case .savings:
            return calculateSavingsGoal(for: category, monthlyAmount: monthlyAmount)
        case .debt:
            return calculateDebtRepaymentPlan(for: category, monthlyAmount: monthlyAmount)
        default:
            return monthlyAmount * 12
        }
    }
    
    // Utilities: blend fixed assumption costs with a percentage of income.
    private func calculateUtilitiesAmount(for category: BudgetCategory) -> Double {
        let currentAssumptions = assumptions[category.id] ?? category.assumptions
        let fixedCost = currentAssumptions.compactMap { Double($0.value) }.reduce(0, +)
        let incomeBasedCost = monthlyIncome * category.allocationPercentage
        let minCost = 50.0
        let maxCost = monthlyIncome * 0.15
        let blendedCost = (fixedCost + incomeBasedCost) / 2
        let finalCost = max(minCost, min(blendedCost, maxCost))
        print("Utilities Calculation: fixed=\(fixedCost), incomeBased=\(incomeBasedCost), final=\(finalCost)")
        return finalCost
    }
    
    // Home affordability uses a mortgage formula with more detailed breakdown.
    private func calculateHomeAffordability(_ category: BudgetCategory, monthlyIncome: Double) -> Double {
        let assumptions = category.assumptions
        let downPayment = getAssumptionValue(assumptions, title: "Down Payment") ?? 20.0
        let interestRate = getAssumptionValue(assumptions, title: "Interest Rate") ?? 7.0
        let propertyTax = getAssumptionValue(assumptions, title: "Property Tax Rate") ?? 1.1
        let loanTermYears = Int(getAssumptionValue(assumptions, title: "Loan Term") ?? 30)
        
        let monthlyBudget = monthlyIncome * category.allocationPercentage
        let monthlyInterest = (interestRate / 100.0) / 12.0
        let n = Double(loanTermYears * 12)
        let factor = (monthlyInterest * pow(1 + monthlyInterest, n)) / (pow(1 + monthlyInterest, n) - 1)
        let dpFraction = 1 - downPayment / 100.0
        let monthlyTaxFraction = (propertyTax / 100.0) / 12.0
        
        let divisor = dpFraction * factor + monthlyTaxFraction
        guard divisor > 0 else { return 0 }
        let homePrice = monthlyBudget / divisor
        
        return homePrice
    }
    
    // Car affordability uses a similar loan formula but with distinct assumptions.
    private func calculateCarAffordability(_ category: BudgetCategory, monthlyIncome: Double) -> Double {
        let assumptions = category.assumptions
        let downPayment = getAssumptionValue(assumptions, title: "Down Payment") ?? 10.0
        let interestRate = getAssumptionValue(assumptions, title: "Interest Rate") ?? 5.0
        let loanTermYears = Int(getAssumptionValue(assumptions, title: "Loan Term") ?? 5)
        
        let monthlyBudget = monthlyIncome * category.allocationPercentage
        let monthlyInterest = (interestRate / 100.0) / 12.0
        let n = Double(loanTermYears * 12)
        let factor = (monthlyInterest * pow(1 + monthlyInterest, n)) / (pow(1 + monthlyInterest, n) - 1)
        let dpFraction = 1 - downPayment / 100.0
        guard dpFraction > 0 else { return 0 }
        let carPrice = monthlyBudget / (factor * dpFraction)
        return carPrice
    }
    
    // Emergency savings are calculated based on a multiplier (months of salary).
    private func calculateEmergencySavings(_ category: BudgetCategory, monthlyIncome: Double) -> Double {
        let assumptions = category.assumptions
        let months = getAssumptionValue(assumptions, title: "Months of Salary") ?? 6.0
        return monthlyIncome * months
    }
    
    // Savings goal calculation uses target amount and timeline, with a non-linear adjustment for high targets.
    private func calculateSavingsGoal(for category: BudgetCategory, monthlyAmount: Double) -> Double {
        let target = category.savingsGoal ?? 0
        let timeline = category.savingsTimeline ?? 12
        // For very high targets, scale the monthly requirement up slightly (non-linear adjustment)
        let adjustment = target > monthlyAmount * Double(timeline) ? 1.1 : 1.0
        return min(target, monthlyAmount * Double(timeline) * adjustment)
    }
    
    // Debt repayment plan: at minimum, pay the calculated interest or a base percentage.
    private func calculateDebtRepaymentPlan(for category: BudgetCategory, monthlyAmount: Double) -> Double {
        let remainingDebt = category.debtAmount ?? 0
        let interestRate = category.debtInterestRate ?? 7.0
        let basePayment = (remainingDebt * (interestRate / 100.0)) / 12.0
        // Ensure at least the monthly allocation is used
        return max(basePayment, monthlyAmount)
    }
    
    // Home maintenance: adjusts a percentage of home value based on debt load and home age proxy.
    private func calculateHomeMaintenanceAffordability(for category: BudgetCategory, debtToIncomeRatio: Double) -> Double {
        if let homeCategory = store.categories.first(where: { $0.id == "home" }) {
            let homeAssumptions = assumptions[homeCategory.id] ?? homeCategory.assumptions
            let downPayment = getAssumptionValue(homeAssumptions, title: "Down Payment") ?? 20.0
            let interestRate = getAssumptionValue(homeAssumptions, title: "Interest Rate") ?? 7.0
            let propertyTax = getAssumptionValue(homeAssumptions, title: "Property Tax Rate") ?? 1.1
            let loanTermYears = Int(getAssumptionValue(homeAssumptions, title: "Loan Term") ?? 30)
            
            let homePrice = calculateHomeAffordability(homeCategory, monthlyIncome: monthlyIncome)
            let baseMaintenance = homePrice * 0.01
            let monthlyMaintenance = baseMaintenance / 12.0
            // Apply a scaling factor based on debt-to-income ratio (more debt means lower maintenance spending)
            let scaleFactor = debtToIncomeRatio > 0.36 ? 0.75 : 1.0
            let adjustedMaintenance = homePrice > 0 ? min(monthlyMaintenance * scaleFactor, monthlyIncome * 0.05) : 0
            return adjustedMaintenance
        }
        return monthlyIncome * category.allocationPercentage * 12
    }
    
    // MARK: - Helper Functions
    
    // Adjust monthly allocation by an income-level multiplier (non-linear scaling).
    private func adjustMonthlyAmount(_ amount: Double, for category: BudgetCategory) -> Double {
        let multiplier = determineIncomeLevel(monthlyIncome).multiplier
        // For high-priority categories, boost the allocation slightly
        let priorityBoost = category.priority == 1 ? 1.05 : 1.0
        return amount * multiplier * priorityBoost
    }
    
    // Sum of recommended debt payments from key debt categories.
    private func calculateTotalDebtPayments() -> Double {
        let debtIds = ["credit_cards", "student_loans", "personal_loans", "car_loan"]
        return store.categories
            .filter { debtIds.contains($0.id) }
            .reduce(0) { $0 + $1.recommendedAmount }
    }
    
    // Retrieves a numeric value from a set of assumptions based on a title.
    private func getAssumptionValue(_ assumptions: [CategoryAssumption], title: String) -> Double? {
        if let valueStr = assumptions.first(where: { $0.title == title })?.value,
           let value = Double(valueStr) {
            return value
        }
        return nil
    }
    
    // Rounds a value to one decimal place.
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
        case .low:       return 0.9
        case .moderate:  return 1.0
        case .high:      return 1.1
        case .veryHigh:  return 1.2
        }
    }
}

// MARK: - Extensions for Income Adjustments
private extension AffordabilityModel {
    /// Determines income level based on annual income with non-linear thresholds.
    func determineIncomeLevel(_ monthlyIncome: Double) -> IncomeLevel {
        let annualIncome = monthlyIncome * 12
        switch annualIncome {
        case ..<50000:
            return .low
        case 50000..<100000:
            return .moderate
        case 100000..<200000:
            return .high
        default:
            return .veryHigh
        }
    }
}
