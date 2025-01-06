import SwiftUI

struct BudgetBuilderModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var budgetStore: BudgetStore
    let monthlyIncome: Double
    @State private var currentStep = OnboardingStep.debt
    
    enum OnboardingStep: Int, CaseIterable {
        case debt
        case expenses
        case savings
        
        var title: String {
            switch self {
            case .debt: return "Debt"
            case .expenses: return "Monthly Expenses"
            case .savings: return "Savings Goals"
            }
        }
        
        var description: String {
            switch self {
            case .debt: return "Select any recurring debt payments"
            case .expenses: return "Choose your regular monthly expenses"
            case .savings: return "Set up your savings goals"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Title Section
                        VStack(spacing: 8) {
                            Text("Let's build your budget")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(currentStep.title): \(currentStep.description)")
                                .font(.system(size: 17))
                                .foregroundColor(Theme.secondaryLabel)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Categories List
                        VStack(spacing: 12) {
                            ForEach(filteredCategories) { category in
                                CategoryToggleRow(
                                    category: category,
                                    isSelected: budgetStore.isSelected(category),
                                    monthlyIncome: monthlyIncome,
                                    onToggle: {
                                        budgetStore.toggleCategory(category)
                                    }
                                )
                            }
                        }
                        
                        // Navigation Buttons
                        VStack(spacing: 12) {
                            if currentStep != .debt {
                                Button(action: {
                                    withAnimation {
                                        currentStep = OnboardingStep(
                                            rawValue: currentStep.rawValue - 1
                                        ) ?? .debt
                                    }
                                }) {
                                    Text("Back")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(Theme.surfaceBackground)
                                        .cornerRadius(12)
                                }
                            }
                            
                            Button(action: {
                                withAnimation {
                                    if currentStep == .savings {
                                        isPresented = false
                                    } else {
                                        currentStep = OnboardingStep(
                                            rawValue: currentStep.rawValue + 1
                                        ) ?? .savings
                                    }
                                }
                            }) {
                                Text(currentStep == .savings ? "Complete Budget" : "Next")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Theme.tint)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Theme.background)
            .cornerRadius(20)
            .padding()
        }
    }
    
    private var filteredCategories: [BudgetCategory] {
        let store = BudgetCategoryStore.shared
        switch currentStep {
        case .debt:
            return store.categories.filter { isDebtCategory($0.id) }
        case .expenses:
            return store.categories.filter {
                !isDebtCategory($0.id) && !isSavingsCategory($0.id)
            }
        case .savings:
            return store.categories.filter { isSavingsCategory($0.id) }
        }
    }
    
    private func isDebtCategory(_ id: String) -> Bool {
        ["credit_cards", "student_loans", "personal_loans", "car_loan"].contains(id)
    }
    
    private func isSavingsCategory(_ id: String) -> Bool {
        ["emergency_savings", "investments", "college_savings", "vacation"].contains(id)
    }
}

struct CategoryToggleRow: View {
    let category: BudgetCategory
    let isSelected: Bool
    let monthlyIncome: Double
    let onToggle: () -> Void
    
    private var recommendedAmount: Double {
        monthlyIncome * category.allocationPercentage
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(category.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    
                    Text("\(formatCurrency(recommendedAmount))/month • \(Int(category.allocationPercentage * 100))% of income")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryLabel)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Theme.tint : Theme.secondaryLabel)
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

class BudgetStore: ObservableObject {
    @Published var selectedCategories: Set<String> = []
    
    func isSelected(_ category: BudgetCategory) -> Bool {
        selectedCategories.contains(category.id)
    }
    
    func toggleCategory(_ category: BudgetCategory) {
        if isSelected(category) {
            selectedCategories.remove(category.id)
        } else {
            selectedCategories.insert(category.id)
        }
    }
}
