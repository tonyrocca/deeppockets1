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
    @Published var budgetItems: [BudgetItem] = []
    @Published var unusedAmount: Double = 0
    
    private let store = BudgetCategoryStore.shared
    
    init(monthlyIncome: Double) {
        self.monthlyIncome = monthlyIncome
        calculateUnusedAmount()
    }
    
    // Called explicitly when you want to set up items from selected category IDs
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
        let totalAllocated = budgetItems
            .filter { $0.isActive }
            .reduce(0) { $0 + $1.allocatedAmount }
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
    
    func addCustomCategory(name: String, emoji: String, allocation: Double,
                           type: BudgetCategoryType, priority: BudgetCategoryPriority) {
        let categoryType: CategoryType = (type == .savings) ? .savings : .other
        
        let newCategory = BudgetCategory(
            id: "custom_\(UUID().uuidString)",
            name: name,
            emoji: emoji,
            description: "Custom category",
            allocationPercentage: allocation / monthlyIncome,
            displayType: .monthly,
            assumptions: [],
            type: categoryType,
            priority: priority.rawValue // Pass the raw value of the enum
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
    
    /// Deletes a category from the budget and updates related state
    func deleteCategory(id: String) {
        // Remove the category from budgetItems
        budgetItems.removeAll(where: { $0.id == id })
        
        // Recalculate unused amount after deletion
        calculateUnusedAmount()
        
        // Notify observers of the change
        objectWillChange.send()
    }
}

// MARK: - Extension: Additional Methods
extension BudgetModel {
    /// Checks if a category can be deleted
    func canDeleteCategory(id: String) -> Bool {
        // Get the category if it exists
        guard let item = budgetItems.first(where: { $0.id == id }) else {
            return false
        }
        
        // If it's a custom category, always allow deletion
        if item.category.id.hasPrefix("custom_") {
            return true
        }
        
        // For standard categories, disallow if essential, else allow
        switch item.priority {
        case .essential:
            return false
        case .important, .discretionary:
            return true
        }
    }
}

// MARK: - Smart Budget Generation Extension
extension BudgetModel {
    /// Generates a smart budget allocation based on income and financial best practices
    func generateSmartBudget() {
        // Clear existing items
        budgetItems.removeAll()
        
        // Financial constants
        let constants = FinancialConstants(
            emergencyFundMonths: 6.0,
            maxHousingRatio: 0.33,
            maxDebtToIncomeRatio: 0.36,
            minRetirementPercentage: 0.15,
            minEmergencySavings: 1000.0
        )
        
        var remainingIncome = monthlyIncome
        var allocations: [BudgetItem] = []
        
        // 1. First allocate essentials (Priority 1)
        let essentialCategories = store.categories.filter {
            determinePriority(for: $0) == .essential
        }.sorted { $0.type.allocationOrder < $1.type.allocationOrder }
        
        for category in essentialCategories {
            let amount = calculateSmartAllocation(
                for: category,
                monthlyIncome: monthlyIncome,
                remainingIncome: remainingIncome,
                constants: constants
            )
            
            if amount > 0 {
                let type: BudgetCategoryType = shouldBeSavingsCategory(category) ? .savings : .expense
                
                allocations.append(BudgetItem(
                    id: category.id,
                    category: category,
                    allocatedAmount: amount,
                    spentAmount: 0,
                    type: type,
                    priority: .essential,
                    isActive: true
                ))
                
                remainingIncome -= amount
            }
        }
        
        // 2. Then allocate important items (Priority 2)
        let importantCategories = store.categories.filter {
            determinePriority(for: $0) == .important
        }.sorted { $0.type.allocationOrder < $1.type.allocationOrder }
        
        for category in importantCategories {
            let amount = calculateSmartAllocation(
                for: category,
                monthlyIncome: monthlyIncome,
                remainingIncome: remainingIncome,
                constants: constants
            )
            
            if amount > 0 {
                let type: BudgetCategoryType = shouldBeSavingsCategory(category) ? .savings : .expense
                
                allocations.append(BudgetItem(
                    id: category.id,
                    category: category,
                    allocatedAmount: amount,
                    spentAmount: 0,
                    type: type,
                    priority: .important,
                    isActive: true
                ))
                
                remainingIncome -= amount
            }
        }
        
        // 3. Finally, allocate discretionary items if there's remaining income
        if remainingIncome > 0 {
            let discretionaryCategories = store.categories.filter {
                determinePriority(for: $0) == .discretionary
            }.sorted { $0.type.allocationOrder < $1.type.allocationOrder }
            
            for category in discretionaryCategories {
                let amount = calculateSmartAllocation(
                    for: category,
                    monthlyIncome: monthlyIncome,
                    remainingIncome: remainingIncome,
                    constants: constants
                )
                
                if amount > 0 {
                    let type: BudgetCategoryType = shouldBeSavingsCategory(category) ? .savings : .expense
                    
                    allocations.append(BudgetItem(
                        id: category.id,
                        category: category,
                        allocatedAmount: amount,
                        spentAmount: 0,
                        type: type,
                        priority: .discretionary,
                        isActive: true
                    ))
                    
                    remainingIncome -= amount
                }
            }
        }
        
        // Update budget items
        budgetItems = allocations
        calculateUnusedAmount()
    }
    
    private func calculateSmartAllocation(
        for category: BudgetCategory,
        monthlyIncome: Double,
        remainingIncome: Double,
        constants: FinancialConstants
    ) -> Double {
        switch category.type {
        case .savings where category.id == "emergency_savings":
            // Calculate emergency fund contribution
            let monthlyExpenses = calculateBasicMonthlyExpenses()
            let targetEmergencyFund = max(constants.minEmergencySavings, monthlyExpenses * constants.emergencyFundMonths)
            return min(remainingIncome * 0.2, targetEmergencyFund / 12)
            
        case .housing:
            // Limit housing to recommended ratio
            return min(monthlyIncome * constants.maxHousingRatio,
                      monthlyIncome * category.allocationPercentage)
            
        case .debt:
            // Calculate debt payments considering debt-to-income ratio
            let currentDebtPayments = calculateCurrentDebtPayments()
            let maxNewDebt = (monthlyIncome * constants.maxDebtToIncomeRatio) - currentDebtPayments
            return min(maxNewDebt, monthlyIncome * category.allocationPercentage)
            
        case .savings where category.id == "retirement_savings":
            // Ensure minimum retirement savings
            return max(monthlyIncome * constants.minRetirementPercentage,
                      monthlyIncome * category.allocationPercentage)
            
        default:
            // For other categories, use standard allocation if affordable
            let suggestedAmount = monthlyIncome * category.allocationPercentage
            return min(suggestedAmount, remainingIncome * 0.5)
        }
    }
    
    private func calculateBasicMonthlyExpenses() -> Double {
        let essentialCategories = budgetItems.filter {
            $0.priority == .essential && $0.type == .expense
        }
        return essentialCategories.reduce(0) { $0 + $1.allocatedAmount }
    }
    
    private func calculateCurrentDebtPayments() -> Double {
        let debtCategories = budgetItems.filter {
            $0.category.type == .debt
        }
        return debtCategories.reduce(0) { $0 + $1.allocatedAmount }
    }
}

// MARK: - Supporting Types
private struct FinancialConstants {
    let emergencyFundMonths: Double
    let maxHousingRatio: Double
    let maxDebtToIncomeRatio: Double
    let minRetirementPercentage: Double
    let minEmergencySavings: Double
}

private extension CategoryType {
    // Order in which category types should be allocated
    var allocationOrder: Int {
        switch self {
        case .housing: return 1
        case .utilities: return 2
        case .food: return 3
        case .health: return 4
        case .insurance: return 5
        case .savings: return 6
        case .debt: return 7
        case .transportation: return 8
        case .family: return 9
        case .education: return 10
        case .personal: return 11
        case .entertainment: return 12
        case .other: return 13
        }
    }
}
