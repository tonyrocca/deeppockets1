import SwiftUI

class BudgetStore: ObservableObject {
    struct CategoryConfiguration {
        let category: BudgetCategory
        var amount: Double
        var displayType: AmountDisplayType // Using AmountDisplayType from BudgetCategory
    }
    
    @Published private(set) var configurations: [String: CategoryConfiguration] = [:]
    private let categoryStore = BudgetCategoryStore.shared
    
    func isSelected(_ category: BudgetCategory) -> Bool {
        configurations.keys.contains(category.id)
    }
    
    func setCategory(_ category: BudgetCategory, amount: Double) {
        configurations[category.id] = CategoryConfiguration(
            category: category,
            amount: amount,
            displayType: category.displayType
        )
    }
    
    func removeCategory(_ category: BudgetCategory) {
        configurations.removeValue(forKey: category.id)
    }
    
    func getAmount(for category: BudgetCategory) -> Double? {
        configurations[category.id]?.amount
    }
    
    // Helper methods for filtering categories by type
    func debtCategories() -> [CategoryConfiguration] {
        let debtIds = ["credit_cards", "student_loans", "personal_loans", "car_loan"]
        return configurations.values
            .filter { debtIds.contains($0.category.id) }
            .sorted { $0.category.name < $1.category.name }
    }
    
    func expenseCategories() -> [CategoryConfiguration] {
        let debtIds = ["credit_cards", "student_loans", "personal_loans", "car_loan"]
        let savingsIds = ["emergency_savings", "investments", "college_savings", "vacation"]
        
        return configurations.values
            .filter { !debtIds.contains($0.category.id) && !savingsIds.contains($0.category.id) }
            .sorted { $0.category.name < $1.category.name }
    }
    
    func savingsCategories() -> [CategoryConfiguration] {
        let savingsIds = ["emergency_savings", "investments", "college_savings", "vacation"]
        return configurations.values
            .filter { savingsIds.contains($0.category.id) }
            .sorted { $0.category.name < $1.category.name }
    }
    
    var totalMonthlyBudget: Double {
        configurations.values.reduce(0) { total, config in
            switch config.displayType {
            case .monthly:
                return total + config.amount
            case .total:
                return total + (config.amount / 12) // Convert annual to monthly
            }
        }
    }
    
    var totalDebtPayments: Double {
        debtCategories().reduce(0) { $0 + $1.amount }
    }
    
    var totalMonthlyExpenses: Double {
        expenseCategories().reduce(0) { $0 + $1.amount }
    }
    
    var totalMonthlySavings: Double {
        savingsCategories().reduce(0) {
            let config = $1
            switch config.displayType {
            case .monthly:
                return $0 + config.amount
            case .total:
                return $0 + (config.amount / 12) // Convert annual to monthly
            }
        }
    }
}
