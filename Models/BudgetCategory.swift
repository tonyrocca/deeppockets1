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
