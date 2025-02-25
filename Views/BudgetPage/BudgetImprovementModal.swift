import SwiftUI

struct BudgetRecommendation: Identifiable {
    let id: String
    let emoji: String
    let name: String
    let changeAmount: Double
    let currentAmount: Double
    let newAmount: Double
    let explanation: String
    var isEnabled: Bool = false
    let category: BudgetCategory
}

struct BudgetImprovementModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var budgetModel: BudgetModel
    @State private var recommendations: [BudgetRecommendation] = []
    @State private var initialSurplus: Double = 0
    @State private var selectedPeriod: IncomePeriod = .monthly
    
    private var displaySuffix: String {
        switch selectedPeriod {
        case .monthly:
            return "/mo"
        case .annual:
            return "/yr"
        case .perPaycheck:
            return "/paycheck"
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button (fixed at top)
                HStack {
                    Text("Improve Your Budget")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                }
                .padding()
                
                // Fixed Budget Surplus section
                HStack {
                    Text(calculateCurrentSurplus() >= 0 ? "Budget Surplus" : "Budget Deficit")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(formatCurrency(calculateCurrentSurplus()) + displaySuffix)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(calculateCurrentSurplus() >= 0 ? Theme.tint : .red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                
                // Scrollable recommendations
                ScrollView {
                    if recommendations.isEmpty {
                        emptyStateView
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 16) {
                            Text("RECOMMENDED IMPROVEMENTS")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.tint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.tint.opacity(0.1))
                                .cornerRadius(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            
                            // Simplified recommendation cards
                            ForEach(recommendations) { recommendation in
                                SimplifiedRecommendationCard(
                                    recommendation: recommendation,
                                    onToggle: {
                                        if let index = recommendations.firstIndex(where: { $0.id == recommendation.id }) {
                                            withAnimation {
                                                recommendations[index].isEnabled.toggle()
                                            }
                                        }
                                    }
                                )
                                .padding(.horizontal, 16)
                            }
                            
                            Spacer(minLength: 100) // Space for the button
                        }
                    }
                }
                
                Spacer()
                
                // Bottom action button
                VStack {
                    Divider()
                        .background(Theme.separator)
                    
                    // Improve Budget Button (matching affordability view style)
                    Button(action: applyRecommendations) {
                        Text("Improve Budget")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.tint)
                            .cornerRadius(12)
                    }
                    .disabled(!isAnyRecommendationEnabled())
                    .opacity(isAnyRecommendationEnabled() ? 1.0 : 0.6)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
        }
        .onAppear {
            initialSurplus = budgetModel.unusedAmount
            selectedPeriod = .monthly // Default to monthly
            generateRecommendations()
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(Theme.tint)
            
            Text("Your budget is already optimized!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("No recommendations available at this time.")
                .font(.system(size: 17))
                .foregroundColor(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.surfaceBackground)
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }
    
    private func calculateCurrentSurplus() -> Double {
        // Calculate the current budget surplus based on selected recommendations
        let enabledRecommendationsTotal = recommendations
            .filter { $0.isEnabled }
            .reduce(0) { $0 + $1.changeAmount }
        
        return initialSurplus - enabledRecommendationsTotal
    }
    
    private func isAnyRecommendationEnabled() -> Bool {
        recommendations.contains { $0.isEnabled }
    }
    
    private func generateRecommendations() {
        // Ensure we have a valid budget model and positive surplus
        guard initialSurplus > 0 else { return }
        
        let categoryStore = BudgetCategoryStore.shared
        var newRecommendations: [BudgetRecommendation] = []
        
        // Get all active budget items
        let activeBudgetItems = budgetModel.budgetItems.filter { $0.isActive }
        let budgetCategoryIds = Set(activeBudgetItems.map { $0.id })
        
        // 1. Analyze the budget for optimal allocation based on financial best practices
        
        // 1a. Check savings categories (emergency fund, retirement, investments)
        let savingsCategories = ["emergency_savings", "retirement_savings", "investments", "college_savings"]
        let currentSavingsTotal = activeBudgetItems
            .filter { savingsCategories.contains($0.id) }
            .reduce(0) { $0 + $1.allocatedAmount }
        
        let savingsRatio = currentSavingsTotal / budgetModel.monthlyIncome
        
        // Check if total savings are less than 20% of income - a common financial guideline
        if savingsRatio < 0.2 {
            // Look for savings categories to improve
            for savingsId in savingsCategories {
                if let category = categoryStore.category(for: savingsId) {
                    let currentAmount = activeBudgetItems
                        .first(where: { $0.id == savingsId })?.allocatedAmount ?? 0
                    
                    let recommendedAmount = budgetModel.monthlyIncome * category.allocationPercentage
                    let difference = recommendedAmount - currentAmount
                    
                    // Only create recommendation if there's a significant difference
                    // and we can afford it with the current surplus
                    if difference > 20 && difference <= initialSurplus {
                        var explanation = ""
                        switch savingsId {
                        case "emergency_savings":
                            explanation = "Increase from \(formatCurrency(currentAmount))/mo to \(formatCurrency(currentAmount + difference))/mo for better protection against unexpected events."
                        case "retirement_savings":
                            explanation = "Increase from \(formatCurrency(currentAmount))/mo to \(formatCurrency(currentAmount + difference))/mo to improve your future financial security."
                        case "investments":
                            explanation = "Increase from \(formatCurrency(currentAmount))/mo to \(formatCurrency(currentAmount + difference))/mo to help grow your net worth over time."
                        case "college_savings":
                            explanation = "Increase from \(formatCurrency(currentAmount))/mo to \(formatCurrency(currentAmount + difference))/mo to reduce future education costs."
                        default:
                            explanation = "Increase from \(formatCurrency(currentAmount))/mo to \(formatCurrency(currentAmount + difference))/mo for more financial security."
                        }
                        
                        newRecommendations.append(BudgetRecommendation(
                            id: savingsId,
                            emoji: category.emoji,
                            name: category.name,
                            changeAmount: difference,
                            currentAmount: currentAmount,
                            newAmount: currentAmount + difference,
                            explanation: explanation,
                            category: category
                        ))
                    }
                }
            }
        }
        
        // 1b. Check for missing essential categories
        let essentialCategories = ["groceries", "utilities", "rent", "health_insurance"]
        
        for essentialId in essentialCategories {
            if !budgetCategoryIds.contains(essentialId),
               let category = categoryStore.category(for: essentialId) {
                // Calculate recommended amount
                let recommendedAmount = min(budgetModel.monthlyIncome * category.allocationPercentage, initialSurplus)
                
                if recommendedAmount > 0 {
                    let explanation = "Add \(formatCurrency(recommendedAmount))/mo to budget for this important category that is currently missing."
                    
                    newRecommendations.append(BudgetRecommendation(
                        id: essentialId,
                        emoji: category.emoji,
                        name: category.name,
                        changeAmount: recommendedAmount,
                        currentAmount: 0,
                        newAmount: recommendedAmount,
                        explanation: explanation,
                        category: category
                    ))
                }
            }
        }
        
        // 1c. Check for underfunded categories (spending less than recommended)
        for item in activeBudgetItems {
            if let category = categoryStore.category(for: item.id) {
                let recommendedAmount = budgetModel.monthlyIncome * category.allocationPercentage
                let currentAmount = item.allocatedAmount
                
                // If significantly underfunded (>10% less than recommended)
                // and not a savings category (already handled above)
                if currentAmount < recommendedAmount * 0.9 &&
                   !savingsCategories.contains(item.id) &&
                   item.id != "miscellaneous" {
                    
                    let difference = min(recommendedAmount - currentAmount, initialSurplus)
                    
                    // Only create recommendation if significant
                    if difference > 20 {
                        let explanation = "Increase from \(formatCurrency(currentAmount))/mo to \(formatCurrency(currentAmount + difference))/mo to better meet your needs."
                        
                        newRecommendations.append(BudgetRecommendation(
                            id: item.id,
                            emoji: category.emoji,
                            name: category.name,
                            changeAmount: difference,
                            currentAmount: currentAmount,
                            newAmount: currentAmount + difference,
                            explanation: explanation,
                            category: category
                        ))
                    }
                }
            }
        }
        
        // Sort by priority and limit to top 3
        if !newRecommendations.isEmpty {
            // Sort by priority (savings first, then essential expenses, then others)
            newRecommendations.sort { (a, b) -> Bool in
                // If both are savings or both are essentials, sort by amount
                if savingsCategories.contains(a.id) && savingsCategories.contains(b.id) ||
                   essentialCategories.contains(a.id) && essentialCategories.contains(b.id) {
                    return a.changeAmount > b.changeAmount
                }
                
                // Prioritize savings over essentials, essentials over others
                if savingsCategories.contains(a.id) && !savingsCategories.contains(b.id) {
                    return true
                } else if !savingsCategories.contains(a.id) && savingsCategories.contains(b.id) {
                    return false
                } else if essentialCategories.contains(a.id) && !essentialCategories.contains(b.id) {
                    return true
                } else {
                    return false
                }
            }
            
            // Limit to top 3
            if newRecommendations.count > 3 {
                newRecommendations = Array(newRecommendations.prefix(3))
            }
        }
        
        self.recommendations = newRecommendations
    }
    
    private func applyRecommendations() {
        // Get enabled recommendations
        let enabledRecommendations = recommendations.filter { $0.isEnabled }
        
        // Apply each recommendation to the budget model
        for recommendation in enabledRecommendations {
            // Find the corresponding category in the budget
            if let categoryIndex = budgetModel.budgetItems.firstIndex(where: { $0.id == recommendation.id }) {
                // Update existing category
                let currentAmount = budgetModel.budgetItems[categoryIndex].allocatedAmount
                budgetModel.updateAllocation(for: recommendation.id, amount: currentAmount + recommendation.changeAmount)
            } else {
                // Category doesn't exist yet, add it
                let category = recommendation.category
                
                // Determine priority based on category
                let priority = determinePriority(for: category)
                
                // Determine budget type
                let type: BudgetCategoryType = isSavingsCategory(recommendation.id) ? .savings : .expense
                
                // Create and add the budget item
                let newItem = BudgetItem(
                    id: category.id,
                    category: category,
                    allocatedAmount: recommendation.changeAmount,
                    spentAmount: 0,
                    type: type,
                    priority: priority,
                    isActive: true
                )
                
                budgetModel.budgetItems.append(newItem)
            }
        }
        
        // Recalculate unused amount
        budgetModel.calculateUnusedAmount()
        
        // Close modal
        isPresented = false
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
    
    private func isSavingsCategory(_ id: String) -> Bool {
        ["emergency_savings", "investments", "college_savings", "vacation"].contains(id)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct SimplifiedRecommendationCard: View {
    let recommendation: BudgetRecommendation
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main row with category, amount and toggle
            HStack(spacing: 12) {
                Text(recommendation.emoji)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(recommendation.name)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text("+ \(formatCurrency(recommendation.changeAmount))/mo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.tint)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { recommendation.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Theme.tint))
            }
            
            // Description text
            Text(recommendation.explanation)
                .font(.system(size: 14))
                .foregroundColor(Theme.secondaryLabel)
                .lineLimit(3)
        }
        .padding(16)
        .background(Theme.surfaceBackground)
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
