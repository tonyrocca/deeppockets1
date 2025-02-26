import SwiftUI

struct BudgetRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let category: BudgetCategory
    let changeAmount: Double
    let currentAmount: Double?
    let newAmount: Double
    let explanation: String
    var isEnabled: Bool = false
    
    enum RecommendationType {
        case increase
        case decrease
        case add
        case remove
    }
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
    
    private var enabledCount: Int {
        recommendations.filter { $0.isEnabled }.count
    }
    
    var body: some View {
        ZStack {
            // Background
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
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
                
                // Budget Surplus section
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
                            // Recommendations
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
                    
                    // Apply Button
                    Button(action: applyRecommendations) {
                        Text("Apply \(enabledCount) Improvement\(enabledCount == 1 ? "" : "s")")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.tint)
                            .cornerRadius(12)
                    }
                    .disabled(enabledCount == 0)
                    .opacity(enabledCount > 0 ? 1.0 : 0.6)
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
    
    // Sort recommendations by priority
    private func sortRecommendations() {
        recommendations.sort { a, b in
            // Helper function to get priority value (lower is higher priority)
            func getPriorityValue(_ rec: BudgetRecommendation) -> Int {
                switch rec.type {
                case .add:
                    return determinePriority(for: rec.category) == .essential ? 1 : 3
                case .increase:
                    return 2
                case .decrease:
                    return 4
                case .remove:
                    return 5
                }
            }
            
            let priorityA = getPriorityValue(a)
            let priorityB = getPriorityValue(b)
            
            if priorityA == priorityB {
                // Secondary sort by amount
                return a.changeAmount > b.changeAmount
            }
            
            return priorityA < priorityB
        }
    }
    
    private func calculateCurrentSurplus() -> Double {
        // Calculate the current budget surplus based on selected recommendations
        var newSurplus = initialSurplus
        
        for recommendation in recommendations where recommendation.isEnabled {
            switch recommendation.type {
            case .increase:
                // Increasing allocations reduces surplus
                if let current = recommendation.currentAmount {
                    newSurplus -= (recommendation.newAmount - current)
                }
            case .decrease:
                // Decreasing allocations increases surplus
                if let current = recommendation.currentAmount {
                    newSurplus += (current - recommendation.newAmount)
                }
            case .add:
                // Adding new categories reduces surplus
                newSurplus -= recommendation.newAmount
            case .remove:
                // Removing categories increases surplus
                if let current = recommendation.currentAmount {
                    newSurplus += current
                }
            }
        }
        
        return newSurplus
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
    
    private func generateRecommendations() {
        var newRecommendations: [BudgetRecommendation] = []
        let categoryStore = BudgetCategoryStore.shared
        let monthlyIncome = budgetModel.monthlyIncome
        
        // Get all active budget items
        let activeBudgetItems = budgetModel.budgetItems.filter { $0.isActive }
        let budgetCategoryIds = Set(activeBudgetItems.map { $0.id })
        
        // 1. Check for missing essential categories
        let essentialCategoryIds = ["rent", "groceries", "utilities", "transportation", "emergency_savings"]
        
        for essentialId in essentialCategoryIds {
            if !budgetCategoryIds.contains(essentialId),
               let category = categoryStore.category(for: essentialId) {
                let recommendedAmount = monthlyIncome * category.allocationPercentage
                
                if recommendedAmount <= initialSurplus {
                    let explanation: String
                    switch essentialId {
                    case "rent":
                        explanation = "Housing is typically the largest expense in most budgets and should be included for accuracy."
                    case "groceries":
                        explanation = "Everyone needs to eat! Adding a groceries category helps track this essential expense."
                    case "utilities":
                        explanation = "Basic utilities are an essential monthly expense for most households."
                    case "transportation":
                        explanation = "Transportation costs are a regular expense that should be budgeted for."
                    case "emergency_savings":
                        explanation = "An emergency fund is crucial for financial security - aim for 3-6 months of expenses."
                    default:
                        explanation = "This is an essential category that should be included in your budget."
                    }
                    
                    newRecommendations.append(BudgetRecommendation(
                        type: .add,
                        category: category,
                        changeAmount: recommendedAmount,
                        currentAmount: nil,
                        newAmount: recommendedAmount,
                        explanation: explanation
                    ))
                }
            }
        }
        
        // 2. Check for missing savings categories
        let savingsIds = ["emergency_savings", "investments", "retirement_savings"]
        
        for savingsId in savingsIds where !savingsId.contains("emergency") || !budgetCategoryIds.contains("emergency_savings") {
            if !budgetCategoryIds.contains(savingsId),
               let category = categoryStore.category(for: savingsId) {
                
                let recommendedAmount = min(monthlyIncome * category.allocationPercentage, initialSurplus * 0.5)
                
                if recommendedAmount > 0 && recommendedAmount <= initialSurplus {
                    let explanation: String
                    switch savingsId {
                    case "emergency_savings":
                        explanation = "An emergency fund provides financial security for unexpected expenses or income loss."
                    case "investments":
                        explanation = "Long-term investing helps grow your wealth and beat inflation over time."
                    case "retirement_savings":
                        explanation = "Setting aside money for retirement is crucial for your future financial security."
                    default:
                        explanation = "Adding this savings category will help you build financial stability."
                    }
                    
                    newRecommendations.append(BudgetRecommendation(
                        type: .add,
                        category: category,
                        changeAmount: recommendedAmount,
                        currentAmount: nil,
                        newAmount: recommendedAmount,
                        explanation: explanation
                    ))
                }
            }
        }
        
        // 3. Check for underfunded essential categories
        for item in activeBudgetItems {
            if essentialCategoryIds.contains(item.id) || savingsIds.contains(item.id) {
                let recommendedAmount = monthlyIncome * item.category.allocationPercentage
                let currentAmount = item.allocatedAmount
                
                // If significantly underfunded (>20% less than recommended)
                if currentAmount < recommendedAmount * 0.8 {
                    let difference = min(recommendedAmount - currentAmount, initialSurplus)
                    
                    if difference > 0 && difference > currentAmount * 0.1 { // Only if it's a meaningful increase
                        let explanation = "This essential category is currently underfunded compared to recommended levels."
                        
                        newRecommendations.append(BudgetRecommendation(
                            type: .increase,
                            category: item.category,
                            changeAmount: difference,
                            currentAmount: currentAmount,
                            newAmount: currentAmount + difference,
                            explanation: explanation
                        ))
                    }
                }
            }
        }
        
        // 4. Check for overfunded non-essential categories
        let nonEssentialIds = Set(budgetCategoryIds).subtracting(essentialCategoryIds).subtracting(savingsIds)
        
        for id in nonEssentialIds {
            if let item = activeBudgetItems.first(where: { $0.id == id }) {
                let recommendedAmount = monthlyIncome * item.category.allocationPercentage
                let currentAmount = item.allocatedAmount
                
                // If significantly overfunded (>30% more than recommended)
                if currentAmount > recommendedAmount * 1.3 && initialSurplus < 0 {
                    let reduction = min(currentAmount - recommendedAmount, currentAmount * 0.3)
                    
                    if reduction > 0 && reduction > currentAmount * 0.1 { // Only if it's a meaningful decrease
                        let explanation = "This category is significantly overfunded. Reducing it could help balance your budget."
                        
                        newRecommendations.append(BudgetRecommendation(
                            type: .decrease,
                            category: item.category,
                            changeAmount: reduction,
                            currentAmount: currentAmount,
                            newAmount: currentAmount - reduction,
                            explanation: explanation
                        ))
                    }
                }
            }
        }
        
        // 5. Suggest removal of low-priority, low-allocation categories if budget is tight
        if initialSurplus < 0 {
            for item in activeBudgetItems {
                if !essentialCategoryIds.contains(item.id) &&
                   item.allocatedAmount < monthlyIncome * 0.02 && // Very small allocation
                   item.priority == .discretionary {
                    
                    let explanation = "This low-priority category has a small allocation. Removing it would simplify your budget."
                    
                    newRecommendations.append(BudgetRecommendation(
                        type: .remove,
                        category: item.category,
                        changeAmount: item.allocatedAmount,
                        currentAmount: item.allocatedAmount,
                        newAmount: 0,
                        explanation: explanation
                    ))
                }
            }
        }
        
        // 6. If surplus is large, suggest quality of life categories
        if initialSurplus > monthlyIncome * 0.1 {
            let lifeEnhancementIds = ["entertainment", "dining", "vacation", "personal_development"]
            
            for enhancementId in lifeEnhancementIds {
                if !budgetCategoryIds.contains(enhancementId),
                   let category = categoryStore.category(for: enhancementId) {
                    
                    let recommendedAmount = min(monthlyIncome * category.allocationPercentage, initialSurplus * 0.2)
                    
                    if recommendedAmount > 0 {
                        let explanation = "With your current surplus, you could add this category to enhance your quality of life."
                        
                        newRecommendations.append(BudgetRecommendation(
                            type: .add,
                            category: category,
                            changeAmount: recommendedAmount,
                            currentAmount: nil,
                            newAmount: recommendedAmount,
                            explanation: explanation
                        ))
                    }
                }
            }
        }
        
        // Limit to a reasonable number of recommendations (max 6)
        if newRecommendations.count > 6 {
            // Prioritize by type and potential impact
            newRecommendations.sort { a, b in
                // Helper function to get priority score (lower is higher priority)
                func getPriorityScore(_ rec: BudgetRecommendation) -> Int {
                    switch rec.type {
                    case .add:
                        // Essential additions are highest priority
                        if essentialCategoryIds.contains(rec.category.id) {
                            return 1
                        } else if savingsIds.contains(rec.category.id) {
                            return 3
                        } else {
                            return 5
                        }
                    case .increase:
                        // Increasing essentials is high priority
                        if essentialCategoryIds.contains(rec.category.id) {
                            return 2
                        } else {
                            return 4
                        }
                    case .decrease:
                        return 6
                    case .remove:
                        return 7
                    }
                }
                
                let scoreA = getPriorityScore(a)
                let scoreB = getPriorityScore(b)
                
                if scoreA == scoreB {
                    // If same type, sort by amount (higher first)
                    return a.changeAmount > b.changeAmount
                }
                
                return scoreA < scoreB
            }
            
            // Keep top 6
            newRecommendations = Array(newRecommendations.prefix(6))
        }
        
        self.recommendations = newRecommendations
    }
    
    private func applyRecommendations() {
        // Get enabled recommendations
        let enabledRecommendations = recommendations.filter { $0.isEnabled }
        
        for recommendation in enabledRecommendations {
            switch recommendation.type {
            case .increase:
                budgetModel.updateAllocation(for: recommendation.category.id, amount: recommendation.newAmount)
                
            case .decrease:
                budgetModel.updateAllocation(for: recommendation.category.id, amount: recommendation.newAmount)
                
            case .add:
                let type: BudgetCategoryType = isSavingsCategory(recommendation.category.id) ? .savings : .expense
                let priority = determinePriority(for: recommendation.category)
                
                let newItem = BudgetItem(
                    id: recommendation.category.id,
                    category: recommendation.category,
                    allocatedAmount: recommendation.newAmount,
                    spentAmount: 0,
                    type: type,
                    priority: priority,
                    isActive: true
                )
                
                budgetModel.budgetItems.append(newItem)
                
            case .remove:
                budgetModel.deleteCategory(id: recommendation.category.id)
            }
        }
        
        // Recalculate unused amount
        budgetModel.calculateUnusedAmount()
        
        // Close modal
        isPresented = false
    }
    
    private func isSavingsCategory(_ id: String) -> Bool {
        ["emergency_savings", "investments", "college_savings", "vacation", "retirement_savings"].contains(id)
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
        VStack(alignment: .leading, spacing: 8) {
            // Category name and emoji at the top
            HStack {
                Text(recommendation.category.emoji)
                    .font(.title3)
                
                Text(recommendation.category.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Action badge and amount on same line
            HStack {
                // Action badge
                let (text, color) = actionDetails
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color)
                    .cornerRadius(6)
                
                // Amount text
                amountText
                
                Spacer()
            }
            
            // Explanation text
            Text(recommendation.explanation)
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surfaceBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(recommendation.isEnabled ? Theme.tint.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .overlay(
            // Toggle positioned at right center
            HStack {
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { recommendation.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Theme.tint))
                .frame(width: 50)
                .padding(.trailing, 8)
            }
        )
    }
    
    // Amount text based on recommendation type
    private var amountText: some View {
        Group {
            switch recommendation.type {
            case .increase:
                if let current = recommendation.currentAmount {
                    Text("\(formatCurrency(current)) → \(formatCurrency(recommendation.newAmount))/mo")
                        .foregroundColor(Theme.tint)
                } else {
                    Text("\(formatCurrency(recommendation.newAmount))/mo")
                        .foregroundColor(Theme.tint)
                }
                
            case .decrease:
                if let current = recommendation.currentAmount {
                    Text("\(formatCurrency(current)) → \(formatCurrency(recommendation.newAmount))/mo")
                        .foregroundColor(.orange)
                } else {
                    Text("\(formatCurrency(recommendation.newAmount))/mo")
                        .foregroundColor(.orange)
                }
                
            case .add:
                Text("Add \(formatCurrency(recommendation.newAmount))/mo")
                    .foregroundColor(Theme.tint)
                
            case .remove:
                if let current = recommendation.currentAmount {
                    Text("Remove \(formatCurrency(current))/mo")
                        .foregroundColor(.red)
                }
            }
        }
        .font(.system(size: 15, weight: .medium))
        .padding(.leading, 4)
    }
    
    // Get action text and color based on recommendation type
    private var actionDetails: (String, Color) {
        switch recommendation.type {
        case .increase:
            return ("INCREASE", Color.green)
        case .decrease:
            return ("DECREASE", Color.orange)
        case .add:
            return ("ADD", Theme.tint)
        case .remove:
            return ("REMOVE", Color.red)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
