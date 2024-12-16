import Foundation

enum AmountDisplayType {
    case monthly
    case total
}

struct CategoryAssumption {
    let title: String
    let value: String
}

struct BudgetCategory: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let allocationPercentage: Double
    var recommendedAmount: Double = 0
    let displayType: AmountDisplayType
    let assumptions: [CategoryAssumption]
    
    // Add the formatted allocation computed property
    var formattedAllocation: String {
        let percentage = allocationPercentage * 100
        return String(format: "%.1f%%", percentage)
    }
}
