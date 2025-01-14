// BudgetModel.swift
import SwiftUI
import Combine

enum BudgetCategoryType {
    case expense
    case savings
}

enum BudgetCategoryPriority: Int, CaseIterable {
    case essential = 1
    case important = 2
    case discretionary = 3
    
    var label: String {
        switch self {
        case .essential: return "Essential"
        case .important: return "Important"
        case .discretionary: return "Optional"
        }
    }
    
    var color: Color {
        switch self {
        case .essential: return .red
        case .important: return .orange
        case .discretionary: return .blue
        }
    }
}

struct BudgetItem: Identifiable {
    let id: String
    var category: BudgetCategory
    var allocatedAmount: Double
    var spentAmount: Double
    var type: BudgetCategoryType
    var priority: BudgetCategoryPriority
    var isActive: Bool
    
    var remainingAmount: Double {
        allocatedAmount - spentAmount
    }
    
    var percentageSpent: Double {
        guard allocatedAmount > 0 else { return 0 }
        return (spentAmount / allocatedAmount) * 100
    }
}

class BudgetModel: ObservableObject {
    @Published var monthlyIncome: Double
    @Published var budgetItems: [BudgetItem] = []  // Start with empty array
    @Published var unusedAmount: Double = 0
    private let store = BudgetCategoryStore.shared
    
    init(monthlyIncome: Double) {
        self.monthlyIncome = monthlyIncome
        calculateUnusedAmount()  // Just calculate unused amount, don't setup items
    }
    
    // Move setupInitialBudget to be called explicitly when needed
    func setupInitialBudget(selectedCategoryIds: Set<String>) {
        budgetItems = store.categories
            .filter { selectedCategoryIds.contains($0.id) }
            .map { category in
                let type: BudgetCategoryType = shouldBeSavingsCategory(category) ? .savings : .expense
                let priority = determinePriority(for: category)
                let recommendedAmount = monthlyIncome * category.allocationPercentage

                return BudgetItem(
                    id: category.id,
                    category: category,
                    allocatedAmount: recommendedAmount,
                    spentAmount: 0,
                    type: type,
                    priority: priority,
                    isActive: true
                )
            }
        calculateUnusedAmount()
    }
    
    private func shouldBeSavingsCategory(_ category: BudgetCategory) -> Bool {
        let savingsCategories = ["emergency_savings", "investments", "college_savings", "vacation"]
        return savingsCategories.contains(category.id)
    }
    
    private func determinePriority(for category: BudgetCategory) -> BudgetCategoryPriority {
        switch category.id {
        case "house", "rent", "groceries", "home_utilities", "medical", "emergency_savings":
            return .essential
        case "car", "public_transportation", "investments",
             "credit_cards", "student_loans", "personal_loans", "car_loan":
            return .important
        default:
            return .discretionary
        }
    }
    
    func calculateUnusedAmount() {
        let totalAllocated = budgetItems.filter { $0.isActive }.reduce(0) { $0 + $1.allocatedAmount }
        unusedAmount = monthlyIncome - totalAllocated
    }
    
    func updateAllocation(for itemId: String, amount: Double) {
        if let index = budgetItems.firstIndex(where: { $0.id == itemId }) {
            budgetItems[index].allocatedAmount = amount
            calculateUnusedAmount()
        }
    }
    
    func updateSpentAmount(for itemId: String, amount: Double) {
        if let index = budgetItems.firstIndex(where: { $0.id == itemId }) {
            budgetItems[index].spentAmount = amount
        }
    }
    
    func toggleCategory(id: String) {
        if let index = budgetItems.firstIndex(where: { $0.id == id }) {
            budgetItems[index].isActive.toggle()
            calculateUnusedAmount()
        }
    }
    
    func addCustomCategory(name: String, emoji: String, allocation: Double, type: BudgetCategoryType, priority: BudgetCategoryPriority) {
        let newCategory = BudgetCategory(
            id: "custom_\(UUID().uuidString)",
            name: name,
            emoji: emoji,
            description: "Custom category",
            allocationPercentage: allocation / monthlyIncome,
            displayType: .monthly,
            assumptions: []
        )
        
        let newItem = BudgetItem(
            id: newCategory.id,
            category: newCategory,
            allocatedAmount: allocation,
            spentAmount: 0,
            type: type,
            priority: priority,
            isActive: true
        )
        
        budgetItems.append(newItem)
        calculateUnusedAmount()
    }
    
    func deleteCategory(id: String) {
        budgetItems.removeAll(where: { $0.id == id && $0.category.id.hasPrefix("custom_") })
        calculateUnusedAmount()
    }
}
