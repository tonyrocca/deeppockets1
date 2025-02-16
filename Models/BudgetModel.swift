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

// MARK: - Improved Smart Budget Generation Extension
extension BudgetModel {
    func generateSmartBudget() {
        budgetItems.removeAll()
        
        // Financial constants with target surplus
        let constants = FinancialConstants(
            emergencyFundMonths: 6.0,
            maxHousingRatio: 0.28,    // Reduced from 0.33 to leave more buffer
            maxDebtToIncomeRatio: 0.36,
            minRetirementPercentage: 0.15,
            minEmergencySavings: 1000.0,
            targetSurplus: 0.15       // Target 15% surplus
        )
        
        // Calculate available income (85% of total)
        let availableIncome = monthlyIncome * (1 - constants.targetSurplus)
        
        // Sort categories by new priority order
        let sortedCategories = store.categories.sorted { (cat1, cat2) -> Bool in
            let p1 = determinePriority(for: cat1)
            let p2 = determinePriority(for: cat2)
            if p1 != p2 {
                return p1.rawValue < p2.rawValue
            }
            return cat1.type.allocationOrder < cat2.type.allocationOrder
        }
        
        // Compute base recommendations using available income
        var baseRecommendations: [String: Double] = [:]
        for category in sortedCategories {
            let amount = calculateBaseAllocation(
                for: category,
                monthlyIncome: availableIncome,
                constants: constants
            )
            baseRecommendations[category.id] = amount
        }
        
        // Group categories by priority
        let essentialCategories = sortedCategories.filter { determinePriority(for: $0) == .essential }
        let importantCategories = sortedCategories.filter { determinePriority(for: $0) == .important }
        let discretionaryCategories = sortedCategories.filter { determinePriority(for: $0) == .discretionary }
        
        let sumEssential = essentialCategories.reduce(0) { $0 + (baseRecommendations[$1.id] ?? 0) }
        let sumImportant = importantCategories.reduce(0) { $0 + (baseRecommendations[$1.id] ?? 0) }
        let sumDiscretionary = discretionaryCategories.reduce(0) { $0 + (baseRecommendations[$1.id] ?? 0) }
        
        // Final allocations dictionary
        var finalAllocations: [String: Double] = [:]
        
        // Allocate essential items
        for category in essentialCategories {
            finalAllocations[category.id] = baseRecommendations[category.id] ?? 0
        }
        
        var remaining = availableIncome - sumEssential
        
        // Allocate important items if funds remain
        if remaining > 0 {
            let importantScale = min(1.0, remaining / sumImportant)
            for category in importantCategories {
                let base = baseRecommendations[category.id] ?? 0
                finalAllocations[category.id] = base * importantScale
            }
            remaining -= sumImportant * importantScale
        }
        
        // Allocate discretionary items with remaining funds
        if remaining > 0 {
            let discretionaryScale = min(1.0, remaining / sumDiscretionary)
            for category in discretionaryCategories {
                let base = baseRecommendations[category.id] ?? 0
                finalAllocations[category.id] = base * discretionaryScale
            }
        }
        
        // Build final budget items
        var allocations: [BudgetItem] = []
        for category in sortedCategories {
            let allocatedAmount = finalAllocations[category.id] ?? 0
            let type: BudgetCategoryType = shouldBeSavingsCategory(category) ? .savings : .expense
            
            // Only add categories with non-zero allocations
            if allocatedAmount > 0 {
                allocations.append(BudgetItem(
                    id: category.id,
                    category: category,
                    allocatedAmount: allocatedAmount,
                    spentAmount: 0,
                    type: type,
                    priority: determinePriority(for: category),
                    isActive: true
                ))
            }
        }
        
        budgetItems = allocations
        calculateUnusedAmount()
    }
    
    /// Computes a base allocation for a given category.
    /// This function uses the category’s allocation percentage along with special rules for certain types.
    private func calculateBaseAllocation(for category: BudgetCategory, monthlyIncome: Double, constants: FinancialConstants) -> Double {
        switch category.type {
        case .savings where category.id == "emergency_savings":
            // For emergency savings, ensure at least a minimum monthly contribution and cap at 20% of income.
            let base = monthlyIncome * category.allocationPercentage
            let minMonthly = constants.minEmergencySavings / 12
            return min(max(base, minMonthly), monthlyIncome * 0.2)
            
        case .housing:
            // For housing, do not exceed the max housing ratio.
            return min(monthlyIncome * constants.maxHousingRatio, monthlyIncome * category.allocationPercentage)
            
        case .debt:
            // **Never recommend any allocation for debt.**
            return 0
            
        case .savings where category.id == "retirement_savings":
            // Ensure a minimum retirement savings percentage.
            return max(monthlyIncome * constants.minRetirementPercentage, monthlyIncome * category.allocationPercentage)
            
        default:
            // For other categories, use the store’s allocation percentage.
            return monthlyIncome * category.allocationPercentage
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
