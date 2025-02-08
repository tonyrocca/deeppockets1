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

struct BudgetCategory: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let allocationPercentage: Double
    var recommendedAmount: Double = 0
    let displayType: AmountDisplayType
    var assumptions: [CategoryAssumption]
    
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
        switch displayType {
        case .monthly:
            recommendedAmount = monthlyIncome * allocationPercentage
            
        case .total:
            switch id {
            case "home":
                // Complex home affordability calculation
                let monthlyPayment = monthlyIncome * allocationPercentage
                if let interestRateStr = assumptions.first(where: { $0.title == "Interest Rate" })?.value,
                   let downPaymentStr = assumptions.first(where: { $0.title == "Down Payment" })?.value,
                   let interestRate = Double(interestRateStr),
                   let downPayment = Double(downPaymentStr) {
                    
                    let monthlyRate = (interestRate / 100) / 12
                    let numberOfPayments = 30.0 * 12 // 30 year fixed
                    
                    if monthlyRate > 0 {
                        let loanAmount = monthlyPayment * ((pow(1 + monthlyRate, numberOfPayments) - 1) / (monthlyRate * pow(1 + monthlyRate, numberOfPayments)))
                        recommendedAmount = loanAmount / (1 - (downPayment / 100))
                    } else {
                        recommendedAmount = monthlyPayment * numberOfPayments
                    }
                } else {
                    recommendedAmount = monthlyPayment * 12
                }
                
            case "vacation":
                // Simple yearly calculation
                recommendedAmount = monthlyIncome * allocationPercentage * 12
                
                // Apply multiplier based on destination type
                if let destinationType = assumptions.first(where: { $0.title == "Destination Type" })?.value {
                    switch destinationType.lowercased() {
                    case "international":
                        recommendedAmount *= 2.0
                    case "luxury":
                        recommendedAmount *= 3.0
                    default: // domestic
                        break
                    }
                }
                
            case "college_savings":
                // Calculate based on years to college
                if let yearsToStr = assumptions.first(where: { $0.title == "Years to College" })?.value,
                   let yearsTo = Double(yearsToStr) {
                    let baseAmount = monthlyIncome * allocationPercentage * 12
                    let inflation = 0.04 // 4% education inflation
                    recommendedAmount = baseAmount * pow(1 + inflation, yearsTo)
                } else {
                    recommendedAmount = monthlyIncome * allocationPercentage * 12
                }
                
            default:
                // Default total calculation
                recommendedAmount = monthlyIncome * allocationPercentage * 12
            }
        }
    }
}
