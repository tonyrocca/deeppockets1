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
    
    // Called explicitly when you want to set up items from selected category IDs.
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
    
    private func isDebtCategory(_ id: String) -> Bool {
        ["credit_cards", "student_loans", "personal_loans", "car_loan", "medical_debt", "mortgage"].contains(id)
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
            priority: priority.rawValue
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
    
    /// Deletes a category from the budget and updates related state.
    func deleteCategory(id: String) {
        budgetItems.removeAll(where: { $0.id == id })
        calculateUnusedAmount()
        objectWillChange.send()
    }
}

// MARK: - Extension: Additional Methods
extension BudgetModel {
    /// Checks if a category can be deleted.
    func canDeleteCategory(id: String) -> Bool {
        guard let item = budgetItems.first(where: { $0.id == id }) else {
            return false
        }
        
        if item.category.id.hasPrefix("custom_") {
            return true
        }
        
        switch item.priority {
        case .essential:
            return false
        case .important, .discretionary:
            return true
        }
    }
}

// MARK: - Supporting Types
private struct FinancialConstants {
    let emergencyFundMonths: Double
    let maxHousingRatio: Double
    let maxDebtToIncomeRatio: Double
    let minRetirementPercentage: Double
    let minEmergencySavings: Double
    let targetSurplus: Double    // Added target surplus percentage
}

private extension CategoryType {
    // Updated allocation order to prioritize savings and push debt lower
    var allocationOrder: Int {
        switch self {
        case .savings: return 1      // Moved savings to top priority
        case .housing: return 2
        case .utilities: return 3
        case .food: return 4
        case .health: return 5
        case .insurance: return 6
        case .transportation: return 7
        case .debt: return 12        // Moved debt near the bottom
        case .family: return 8
        case .education: return 9
        case .personal: return 10
        case .entertainment: return 11
        case .other: return 13
        }
    }
}

// MARK: - Budget Optimization Models
enum BudgetOptimizationType {
    case increase(String, Double) // categoryId, recommended amount
    case decrease(String, Double) // categoryId, recommended amount
    case add(BudgetCategory, Double) // category to add, recommended amount
    case remove(String) // categoryId to remove
}

struct BudgetOptimization: Identifiable {
    let id = UUID()
    let type: BudgetOptimizationType
    let reason: String
    var isSelected: Bool = false
    
    var title: String {
        switch type {
        case .increase(let categoryId, let amount):
            guard let category = BudgetCategoryStore.shared.category(for: categoryId) else { return "" }
            return "Increase \(category.name) to \(formatCurrency(amount))"
        case .decrease(let categoryId, let amount):
            guard let category = BudgetCategoryStore.shared.category(for: categoryId) else { return "" }
            return "Decrease \(category.name) to \(formatCurrency(amount))"
        case .add(let category, let amount):
            return "Add \(category.name) with \(formatCurrency(amount))"
        case .remove(let categoryId):
            guard let category = BudgetCategoryStore.shared.category(for: categoryId) else { return "" }
            return "Remove \(category.name)"
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Smart Budget Generation Extension
extension BudgetModel {
    func generateSmartBudget() {
        budgetItems.removeAll()
        
        // Define a core set of essential categories we want to include
        // This ensures we have the most important budget categories covered
        let coreCategories = [
            "rent", "mortgage", // Housing (will include only one)
            "groceries",        // Food
            "utilities",        // Basic utilities
            "transportation",   // Getting around
            "emergency_savings" // Safety net
        ]
        
        // Define secondary categories based on income level
        let secondaryCategories: [String]
        if monthlyIncome < 3000 {
            // Lower income - focus on essentials plus minimal additional categories
            secondaryCategories = [
                "personal_care",
                "medical_expenses"
            ]
        } else if monthlyIncome < 6000 {
            // Middle income - add some saving and quality of life categories
            secondaryCategories = [
                "retirement_savings",
                "personal_care",
                "medical_expenses",
                "entertainment"
            ]
        } else {
            // Higher income - more comprehensive with optional categories
            secondaryCategories = [
                "retirement_savings",
                "investments",
                "personal_care",
                "medical_expenses",
                "entertainment",
                "dining",
                "vacation_savings"
            ]
        }
        
        // Financial constants
        let constants = FinancialConstants(
            emergencyFundMonths: 6.0,
            maxHousingRatio: 0.30,
            maxDebtToIncomeRatio: 0.36,
            minRetirementPercentage: 0.15,
            minEmergencySavings: 1000.0,
            targetSurplus: 0.10  // Target 10% surplus
        )
        
        // Calculate available income (90% of total)
        let availableIncome = monthlyIncome * (1 - constants.targetSurplus)
        
        // First pass - allocate to housing
        var remainingIncome = availableIncome
        var allocations: [String: Double] = [:]
        
        // Housing allocation (choose rent or mortgage but not both)
        let housingCategories = store.categories.filter { $0.id == "rent" || $0.id == "mortgage" }
        if let housingCategory = housingCategories.first {
            let housingAmount = min(monthlyIncome * constants.maxHousingRatio, availableIncome * 0.3)
            allocations[housingCategory.id] = housingAmount
            remainingIncome -= housingAmount
        }
        
        // Core categories allocation
        let filteredCoreCategories = store.categories.filter {
            coreCategories.contains($0.id) && $0.id != "rent" && $0.id != "mortgage"
        }
        
        // Allocate a substantial portion to core categories
        let coreRatio = 0.6 // Allocate 60% of remaining to core categories
        let coreAmount = remainingIncome * coreRatio
        let coreCount = filteredCoreCategories.count
        
        if coreCount > 0 {
            // Weighted allocation based on category importance
            for category in filteredCoreCategories {
                var allocationWeight: Double
                
                switch category.id {
                case "groceries":
                    allocationWeight = 0.35 // 35% of core budget
                case "utilities":
                    allocationWeight = 0.25 // 25% of core budget
                case "transportation":
                    allocationWeight = 0.20 // 20% of core budget
                case "emergency_savings":
                    allocationWeight = 0.20 // 20% of core budget
                default:
                    allocationWeight = 0.0
                }
                
                allocations[category.id] = coreAmount * allocationWeight
            }
        }
        
        remainingIncome -= coreAmount
        
        // Secondary categories allocation - select based on income and category relevance
        let filteredSecondaryCategories = store.categories.filter { secondaryCategories.contains($0.id) }
        let secondaryCount = filteredSecondaryCategories.count
        
        if secondaryCount > 0 && remainingIncome > 0 {
            var weightedAllocations: [String: Double] = [:]
            var totalWeight = 0.0
            
            // Assign weights based on category importance and income level
            for category in filteredSecondaryCategories {
                var weight: Double
                switch category.id {
                case "retirement_savings":
                    weight = 0.30
                case "investments":
                    weight = 0.15
                case "medical_expenses":
                    weight = 0.15
                case "personal_care":
                    weight = 0.10
                case "entertainment":
                    weight = 0.10
                case "dining":
                    weight = 0.10
                case "vacation_savings":
                    weight = 0.10
                default:
                    weight = 0.05
                }
                
                weightedAllocations[category.id] = weight
                totalWeight += weight
            }
            
            // Normalize weights and allocate
            for (id, weight) in weightedAllocations {
                let normalizedWeight = weight / totalWeight
                allocations[id] = remainingIncome * normalizedWeight
            }
        }
        
        // Build final budget items
        for category in store.categories {
            if let amount = allocations[category.id], amount > 0 {
                // Only add if the allocation is meaningful (above a minimum threshold)
                let minThreshold = monthlyIncome * 0.01 // 1% of income minimum
                
                if amount >= minThreshold {
                    let type: BudgetCategoryType = shouldBeSavingsCategory(category) ? .savings : .expense
                    
                    budgetItems.append(BudgetItem(
                        id: category.id,
                        category: category,
                        allocatedAmount: amount,
                        spentAmount: 0,
                        type: type,
                        priority: determinePriority(for: category),
                        isActive: true
                    ))
                }
            }
        }
        
        // Ensure we don't have too many categories
        let maxCategories = 10
        if budgetItems.count > maxCategories {
            // Sort by allocation amount and keep only the top categories
            budgetItems.sort { $0.allocatedAmount > $1.allocatedAmount }
            budgetItems = Array(budgetItems.prefix(maxCategories))
        }
        
        calculateUnusedAmount()
    }
}
