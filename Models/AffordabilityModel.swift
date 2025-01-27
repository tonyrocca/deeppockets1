import SwiftUI

class AffordabilityModel: ObservableObject {
    @Published var monthlyIncome: Double = 0
    @Published var categories: [BudgetCategory] = []
    private let store = BudgetCategoryStore.shared
    
    // Make updateAssumptions public and properly marked for SwiftUI
        @Published var assumptions: [String: [CategoryAssumption]] = [:]
        
        func updateAssumptions(for categoryId: String, assumptions: [CategoryAssumption]) {
            // Update the store
            if let index = store.categories.firstIndex(where: { $0.id == categoryId }) {
                store.categories[index].assumptions = assumptions
                // Update local state
                self.assumptions[categoryId] = assumptions
                // Notify observers
                objectWillChange.send()
            }
        }
    
    // Financial Constants
    private let constants = FinancialConstants(
        mortgageRatios: (frontend: 0.28, backend: 0.36), // Frontend & backend DTI ratios
        emergencyMultipliers: [
            "low_risk": 3.0,    // Stable job, good insurance
            "medium_risk": 6.0,  // Average stability
            "high_risk": 9.0     // Variable income/freelance
        ],
        inflationRate: 0.04,    // Current inflation rate
        propertyAppreciation: 0.035, // Historical average
        vehicleDepreciation: 0.15,   // Average annual depreciation
        investmentReturns: [
            "conservative": 0.06,
            "moderate": 0.08,
            "aggressive": 0.10
        ]
    )
    
    func calculateAffordableAmount(for category: BudgetCategory) -> Double {
        let monthlyAmount = monthlyIncome * category.allocationPercentage
        let totalDebtPayments = calculateTotalDebtPayments()
        let debtToIncomeRatio = totalDebtPayments / monthlyIncome
        
        switch category.displayType {
        case .monthly:
            return adjustMonthlyAmount(monthlyAmount, for: category)
            
        case .total:
            switch category.id {
            case "house":
                return calculateHouseAffordability(
                    monthlyAmount: monthlyAmount,
                    debtToIncomeRatio: debtToIncomeRatio
                )
                
            case "car":
                return calculateCarAffordability(
                    monthlyAmount: monthlyAmount,
                    debtToIncomeRatio: debtToIncomeRatio
                )
                
            case "emergency_savings":
                return calculateEmergencyFund(monthlyIncome: monthlyIncome)
                
            case "college_savings":
                return calculateCollegeSavings()
                
            case "vacation":
                return calculateVacationBudget(monthlyAmount: monthlyAmount)
                
            default:
                return monthlyAmount * 12
            }
        }
    }
    
    private func calculateHouseAffordability(monthlyAmount: Double, debtToIncomeRatio: Double) -> Double {
        guard let downPaymentStr = getAssumptionValue(for: "house", title: "Down Payment"),
              let downPayment = Double(downPaymentStr),
              let interestRateStr = getAssumptionValue(for: "house", title: "Interest Rate"),
              let interestRate = Double(interestRateStr),
              let propertyTaxStr = getAssumptionValue(for: "house", title: "Property Tax Rate"),
              let propertyTaxRate = Double(propertyTaxStr) else {
            return monthlyIncome * 4
        }
        
        // Adjust maximum payment based on existing debt
        let maxDTI = constants.mortgageRatios.backend
        let availableDTI = maxDTI - debtToIncomeRatio
        let adjustedMaxPayment = monthlyIncome * min(constants.mortgageRatios.frontend, availableDTI)
        
        // Account for property tax and insurance
        let taxAndInsurance = 0.015 // 1.5% annually for taxes and insurance
        let monthlyTaxAndInsurance = taxAndInsurance / 12
        
        let effectivePayment = adjustedMaxPayment - (adjustedMaxPayment * monthlyTaxAndInsurance)
        let monthlyRate = (interestRate / 100) / 12
        let numberOfPayments = 30.0 * 12 // 30-year fixed
        
        // Calculate maximum mortgage using effective payment
        let mortgageAmount = effectivePayment *
            ((pow(1 + monthlyRate, numberOfPayments) - 1) /
            (monthlyRate * pow(1 + monthlyRate, numberOfPayments)))
        
        // Calculate total house price including down payment
        let totalPrice = mortgageAmount / (1 - (downPayment / 100))
        
        // Apply appreciation projection
        let fiveYearAppreciation = pow(1 + constants.propertyAppreciation, 5)
        return totalPrice * fiveYearAppreciation
    }
    
    private func calculateCarAffordability(monthlyAmount: Double, debtToIncomeRatio: Double) -> Double {
        guard let downPaymentStr = getAssumptionValue(for: "car", title: "Down Payment"),
              let downPayment = Double(downPaymentStr),
              let interestRateStr = getAssumptionValue(for: "car", title: "Interest Rate"),
              let interestRate = Double(interestRateStr),
              let termStr = getAssumptionValue(for: "car", title: "Loan Term"),
              let term = Double(termStr) else {
            return monthlyAmount * 12
        }
        
        // Consider total cost of ownership
        let operatingCostRatio = 0.35 // 35% of car budget for operating costs
        let availableForPayment = monthlyAmount * (1 - operatingCostRatio)
        
        // Adjust for debt-to-income ratio
        let maxCarDTI = 0.15 // Maximum 15% DTI for car
        let adjustedPayment = min(availableForPayment, monthlyIncome * (maxCarDTI - debtToIncomeRatio))
        
        let monthlyRate = (interestRate / 100) / 12
        let numberOfPayments = term * 12
        
        // Calculate maximum loan amount
        let loanAmount = adjustedPayment *
            ((pow(1 + monthlyRate, numberOfPayments) - 1) /
            (monthlyRate * pow(1 + monthlyRate, numberOfPayments)))
        
        // Calculate total car price including down payment
        let totalPrice = loanAmount / (1 - (downPayment / 100))
        
        // Account for depreciation
        let threeYearDepreciation = pow(1 - constants.vehicleDepreciation, 3)
        return totalPrice * threeYearDepreciation
    }
    
    private func calculateEmergencyFund(monthlyIncome: Double) -> Double {
        guard let monthsCoverageStr = getAssumptionValue(for: "emergency_savings", title: "Months Coverage"),
              let monthsCoverage = Double(monthsCoverageStr),
              let riskLevel = getAssumptionValue(for: "emergency_savings", title: "Risk Level") else {
            return monthlyIncome * 3
        }
        
        // Calculate essential expenses
        let essentialExpenses = calculateEssentialMonthlyExpenses()
        
        // Adjust coverage based on risk level
        let riskMultiplier = constants.emergencyMultipliers[riskLevel.lowercased()] ?? 6.0
        
        // Consider inflation
        let twoYearInflation = pow(1 + constants.inflationRate, 2)
        
        return essentialExpenses * max(monthsCoverage, riskMultiplier) * twoYearInflation
    }
    
    private func calculateEssentialMonthlyExpenses() -> Double {
        // Define essential categories with their percentages of income
        let essentialExpenses: [(category: String, percentage: Double)] = [
            ("house", 0.28),        // Housing (mortgage/rent)
            ("utilities", 0.08),    // Utilities
            ("groceries", 0.12),    // Food and essentials
            ("healthcare", 0.06),   // Healthcare
            ("car_expenses", 0.10), // Transportation
            ("phone", 0.02),        // Phone/Communications
            ("insurance", 0.05)     // Various insurance premiums
        ]
        
        // Calculate total essential expenses
        let totalEssentials = essentialExpenses.reduce(0.0) { total, expense in
            total + (monthlyIncome * expense.percentage)
        }
        
        // Add a buffer for unexpected essential expenses (5%)
        let buffer = totalEssentials * 0.05
        
        return totalEssentials + buffer
    }
    private func calculateCollegeSavings() -> Double {
        guard let yearsToStr = getAssumptionValue(for: "college_savings", title: "Years to College"),
              let yearsTo = Double(yearsToStr) else {
            return monthlyIncome * 0.05 * 12
        }
        
        let currentAnnualCost = 22_690.0 // Base public university cost
        let privateMultiplier = 2.5 // Private university multiplier
        let inflationAdjusted = currentAnnualCost * pow(1 + constants.inflationRate, yearsTo)
        
        // Calculate both public and private scenarios
        let publicTotal = inflationAdjusted * 4 // 4 years
        let privateTotal = publicTotal * privateMultiplier
        
        // Monthly contribution needed
        let monthlyPublic = (publicTotal / yearsTo) / 12
        let monthlyPrivate = (privateTotal / yearsTo) / 12
        
        // Return weighted average
        return (monthlyPublic * 0.7) + (monthlyPrivate * 0.3)
    }
    
    private func calculateVacationBudget(monthlyAmount: Double) -> Double {
        guard let destinationType = getAssumptionValue(for: "vacation", title: "Destination Type") else {
            return monthlyAmount * 12
        }
        
        let baseAmount = monthlyAmount * 12
        let multiplier: Double
        
        switch destinationType.lowercased() {
        case "domestic":
            multiplier = 1.0
        case "international":
            multiplier = 2.0
        case "luxury":
            multiplier = 3.0
        default:
            multiplier = 1.0
        }
        
        // Adjust for inflation and seasonal pricing
        return baseAmount * multiplier * (1 + constants.inflationRate)
    }
    
    private func adjustMonthlyAmount(_ amount: Double, for category: BudgetCategory) -> Double {
        // Adjust monthly amounts based on income level and location factors
        let incomeLevel = determineIncomeLevel(monthlyIncome)
        let adjustmentFactor = getLocationAdjustmentFactor()
        
        return amount * incomeLevel.multiplier * adjustmentFactor
    }
    
    // Helper methods
    private func calculateTotalDebtPayments() -> Double {
        let debtCategories = ["credit_cards", "student_loans", "personal_loans", "car_loan"]
        return store.categories
            .filter { debtCategories.contains($0.id) }
            .reduce(0) { $0 + ($1.recommendedAmount) }
    }
    
    private func getAssumptionValue(for categoryId: String, title: String) -> String? {
        store.categories
            .first { $0.id == categoryId }?
            .assumptions
            .first { $0.title == title }?
            .value
    }
}

// Supporting types
private struct FinancialConstants {
    let mortgageRatios: (frontend: Double, backend: Double)
    let emergencyMultipliers: [String: Double]
    let inflationRate: Double
    let propertyAppreciation: Double
    let vehicleDepreciation: Double
    let investmentReturns: [String: Double]
}

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
    
    func getLocationAdjustmentFactor() -> Double {
        // In a real app, this would use location data
        return 1.0
    }
}
