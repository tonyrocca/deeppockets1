import Foundation

struct CategoryAssumption: Identifiable {
   let title: String
   var value: String
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
