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
            if category.id == "utilities" {
                return calculateUtilitiesAmount(for: category)
            }

            let monthlyAmount = monthlyIncome * category.allocationPercentage
            let totalDebtPayments = calculateTotalDebtPayments()
            let debtToIncomeRatio = (monthlyIncome > 0) ? totalDebtPayments / monthlyIncome : 0.0
            
            let rawAmount: Double
            if category.id == "home_maintenance" {
                rawAmount = calculateHomeMaintenanceAffordability(for: category, debtToIncomeRatio: debtToIncomeRatio)
            } else {
                switch category.displayType {
                case .monthly:
                    rawAmount = adjustMonthlyAmount(monthlyAmount, for: category)
                case .total:
                    rawAmount = calculateTotalAffordability(category: category, monthlyAmount: monthlyAmount, debtToIncomeRatio: debtToIncomeRatio)
                }
            }
            return roundToTenth(rawAmount)
    }
    
    // MARK: - Category-Specific Calculations
    
    /// Calculates total affordability for categories that use a “total” display type.
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
        case .utilities, .food, .entertainment, .insurance, .education, .personal, .health, .family, .other:
            return monthlyAmount * 12
        }
    }
    
    // MARK: - SPECIAL CALCULATIONS
    
    /// Calculate utilities cost based on assumptions and income
    private func calculateUtilitiesAmount(for category: BudgetCategory) -> Double {
        // Get the current assumptions for utilities
        let currentAssumptions = assumptions[category.id] ?? category.assumptions
        
        // Calculate total from explicit assumptions
        let totalFromAssumptions = currentAssumptions.reduce(0) { total, assumption in
            if let value = Double(assumption.value) {
                return total + value
            }
            return total
        }
        
        // Income-based baseline
        let incomeBasedAmount = monthlyIncome * category.allocationPercentage
        
        // Sanity checks
        let minUtilitiesCost = 50.0   // Minimum reasonable utilities cost
        let maxUtilitiesCost = monthlyIncome * 0.15  // Cap at 15% of monthly income
        
        // Adjust the total based on reasonable bounds
        let adjustedTotal = max(minUtilitiesCost, min(totalFromAssumptions, maxUtilitiesCost))
        
        // Final amount: use assumption-based total, but ensure it's not too far from income-based allocation
        let finalAmount = adjustedTotal
        
        // Optional logging or debugging
        print("Utilities Breakdown:")
        print("- From Assumptions: $\(totalFromAssumptions)")
        print("- Income-Based Amount: $\(incomeBasedAmount)")
        print("- Final Amount: $\(finalAmount)")
        
        return finalAmount
    }
    
    /// Calculate a home price you can afford, based on monthlyIncome * allocation, plus a mortgage formula.
    private func calculateHomeAffordability(_ category: BudgetCategory, monthlyIncome: Double) -> Double {
        let assumptions = category.assumptions
        let downPayment = getAssumptionValue(assumptions, title: "Down Payment") ?? 20.0
        let interestRate = getAssumptionValue(assumptions, title: "Interest Rate") ?? 7.0
        let propertyTax = getAssumptionValue(assumptions, title: "Property Tax Rate") ?? 1.1
        let loanTermYears = Int(getAssumptionValue(assumptions, title: "Loan Term") ?? 30)
        
        // 1) Determine your target monthly budget for housing:
        let monthlyBudget = monthlyIncome * category.allocationPercentage
        
        // 2) Convert annual interest to monthly
        let monthlyInterest = (interestRate / 100.0) / 12.0
        
        // 3) Number of monthly payments
        let n = Double(loanTermYears * 12)
        
        // 4) Mortgage factor: r(1+r)^n / ((1+r)^n - 1)
        let numerator = monthlyInterest * pow(1 + monthlyInterest, n)
        let denominator = pow(1 + monthlyInterest, n) - 1
        let factor = numerator / denominator
        
        // 5) Solve for homePrice such that:
        //    ( (homePrice * (1 - dp/100)) * factor ) + (homePrice * (propertyTax/100) / 12 ) = monthlyBudget
        let dpFraction = (1 - downPayment / 100.0)
        let monthlyTaxFraction = (propertyTax / 100.0) / 12.0
        
        let divisor = dpFraction * factor + monthlyTaxFraction
        guard divisor > 0 else { return 0 }
        
        let homePrice = monthlyBudget / divisor
        
        // -----------------------------------------------------
        // EXTRA SNIPPET: Demonstrates monthly payment breakdown
        // using the solved 'homePrice' above. This doesn't alter
        // the returned 'homePrice' but shows how you'd compute
        // monthlyMortgage, monthlyTax, monthlyInsurance, etc.
        // -----------------------------------------------------
        
        // Loan amount after down payment:
        let loanAmount = homePrice * dpFraction
        
        // Monthly mortgage payment using amortization formula:
        let monthlyMortgage = loanAmount
            * (monthlyInterest * pow(1 + monthlyInterest, n))
            / (pow(1 + monthlyInterest, n) - 1)
        
        // Monthly property tax:
        let monthlyTax = (homePrice * propertyTax / 100.0) / 12.0
        
        // Estimated homeowner's insurance at ~0.5% annually:
        let monthlyInsurance = (homePrice * 0.005) / 12.0
        
        // If needed, you can track or store total monthly cost:
        let totalMonthly = monthlyMortgage + monthlyTax + monthlyInsurance
        // (Not returned here, but you can store or publish it
        // in your model if you need to display it.)
        // -----------------------------------------------------
        
        return homePrice
    }
    
    /// Calculate a car price you can afford, based on monthlyIncome * allocation, plus a car-loan formula.
    private func calculateCarAffordability(_ category: BudgetCategory, monthlyIncome: Double) -> Double {
        let assumptions = category.assumptions
        let downPayment = getAssumptionValue(assumptions, title: "Down Payment") ?? 10.0
        let interestRate = getAssumptionValue(assumptions, title: "Interest Rate") ?? 5.0
        let loanTermYears = Int(getAssumptionValue(assumptions, title: "Loan Term") ?? 5)
        
        // 1) Determine your target monthly budget for car:
        let monthlyBudget = monthlyIncome * category.allocationPercentage
        
        // 2) Convert annual interest to monthly
        let monthlyInterest = (interestRate / 100.0) / 12.0
        let n = Double(loanTermYears * 12)
        
        // 3) Loan factor: r(1+r)^n / ((1+r)^n - 1)
        let numerator = monthlyInterest * pow(1 + monthlyInterest, n)
        let denominator = pow(1 + monthlyInterest, n) - 1
        let factor = numerator / denominator
        
        // 4) Solve for carPrice:
        let dpFraction = 1.0 - (downPayment / 100.0)
        guard dpFraction > 0 else { return 0 }
        
        let carPrice = monthlyBudget / (factor * dpFraction)
        return carPrice
    }
    
    /// Calculate how much to save for emergencies = (MonthsOfSalary) * monthlyIncome.
    private func calculateEmergencySavings(_ category: BudgetCategory, monthlyIncome: Double) -> Double {
        let assumptions = category.assumptions
        let monthsOfSalary = getAssumptionValue(assumptions, title: "Months of Salary") ?? 6.0
        return monthlyIncome * monthsOfSalary
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
    /// Special calculation for home maintenance.
    private func calculateHomeMaintenanceAffordability(for category: BudgetCategory, debtToIncomeRatio: Double) -> Double {
        // First, try to find the home category to base calculations on
        if let homeCategory = store.categories.first(where: { $0.id == "home" }) {
            // Retrieve home-related assumptions
            let homeAssumptions = assumptions[homeCategory.id] ?? homeCategory.assumptions
            let downPayment = getAssumptionValue(homeAssumptions, title: "Down Payment") ?? 20.0
            let interestRate = getAssumptionValue(homeAssumptions, title: "Interest Rate") ?? 7.0
            let propertyTax = getAssumptionValue(homeAssumptions, title: "Property Tax Rate") ?? 1.1
            let loanTermYears = Int(getAssumptionValue(homeAssumptions, title: "Loan Term") ?? 30)
            
            // Calculate total home price we can afford
            let homePrice = calculateHomeAffordability(homeCategory, monthlyIncome: monthlyIncome)
            
            // Home maintenance calculation strategies:
            // 1. Industry standard: 1-4% of home value annually
            // 2. Adjust based on home age and condition
            // 3. Consider debt-to-income ratio for financial prudence
            
            // Base maintenance cost: 1% of home value annually
            let baseMaintenanceCost = (homePrice * 0.01)
            
            // Monthly maintenance cost
            let monthlyMaintenance = baseMaintenanceCost / 12.0
            
            // Adjust based on debt-to-income ratio
            // Higher debt ratio means more conservative maintenance budget
            let adjustmentFactor = debtToIncomeRatio > 0.36 ? 0.75 : 1.0
            
            // Additional factors:
            // - Older homes might need more maintenance
            // - Newer homes typically need less immediate maintenance
            let maintenanceBuffer = homePrice > 0 ? min(monthlyMaintenance * adjustmentFactor, monthlyIncome * 0.05) : 0
            
            return maintenanceBuffer
        }
        
        // Fallback: If no home category, use income-based allocation
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
        return store.categories
            .filter { debtCategories.contains($0.id) }
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
        case .low:       return 0.9
        case .moderate:  return 1.0
        case .high:      return 1.1
        case .veryHigh:  return 1.2
        }
    }
}

// MARK: - Extensions for Income and Location Adjustments
private extension AffordabilityModel {
    /// Determines the income level based on annual income.
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

