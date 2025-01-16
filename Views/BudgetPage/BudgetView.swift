import SwiftUI

// MARK: - Income Period Enum
enum IncomePeriod: String, CaseIterable {
    case annual = "Annual"
    case monthly = "Monthly"
    case perPaycheck = "Per Paycheck"
    
    func formatIncome(_ monthlyIncome: Double, payPeriod: PayPeriod) -> Double {
        switch self {
        case .annual:
            return monthlyIncome * 12
        case .monthly:
            return monthlyIncome
        case .perPaycheck:
            return monthlyIncome / payPeriod.multiplier
        }
    }
}

struct CategoryItemView: View {
    let item: BudgetItem
    let periodMultiplier: Double
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Row
            Button(action: { withAnimation { isExpanded.toggle() }}) {
                HStack(spacing: 12) {
                    Text(item.category.emoji)
                        .font(.title3)
                    Text(item.category.name)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    Spacer()
                    Text(formatCurrency(item.allocatedAmount * periodMultiplier))
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Theme.surfaceBackground)
            }
            
            // Expanded Details
            if isExpanded {
                VStack(spacing: 16) {
                    // Allocation Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ALLOCATION OF INCOME")
                            .sectionHeader()
                            .frame(maxWidth: .infinity, alignment: .leading)  // Add this
                        Text("\(Int(item.category.allocationPercentage * 100))%")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                    }
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DESCRIPTION")
                            .sectionHeader()
                            .frame(maxWidth: .infinity, alignment: .leading)  // Add this
                        Text(item.category.description)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)  // Add this
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Theme.surfaceBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Theme.surfaceBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding()
                .background(Theme.elevatedBackground)
            }
            
            if isExpanded {
                Divider()
                    .background(Theme.separator)
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct BudgetView: View {
    let monthlyIncome: Double
    let payPeriod: PayPeriod
    @State private var selectedPeriod: IncomePeriod = .monthly
    @State private var showBudgetBuilder = false
    @State private var showDetailedSummary = false
    @StateObject private var budgetStore = BudgetStore()
    @EnvironmentObject private var budgetModel: BudgetModel
    
    private var periodMultiplier: Double {
        switch selectedPeriod {
        case .annual: return 12
        case .monthly: return 1
        case .perPaycheck: return 1 / payPeriod.multiplier
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if budgetModel.budgetItems.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Period Selector
                        HStack(spacing: 0) {
                            ForEach(IncomePeriod.allCases, id: \.self) { period in
                                Button(action: { withAnimation { selectedPeriod = period }}) {
                                    Text(period.rawValue)
                                        .font(.system(size: 15))
                                        .foregroundColor(selectedPeriod == period ? .white : Theme.secondaryLabel)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 32)
                                        .background(
                                            selectedPeriod == period
                                            ? Theme.tint
                                            : Color.clear
                                        )
                                }
                            }
                        }
                        .background(Theme.surfaceBackground)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        // Budget Summary Card
                        VStack(spacing: 16) {
                            // Income Section
                            HStack {
                                Text("\(selectedPeriod.rawValue) Income")
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(formatCurrency(monthlyIncome * periodMultiplier))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            let debtTotal = budgetModel.budgetItems
                                .filter { $0.type == .expense && isDebtCategory($0.category.id) }
                                .reduce(0) { $0 + $1.allocatedAmount }
                            let expenseTotal = budgetModel.budgetItems
                                .filter { $0.type == .expense && !isDebtCategory($0.category.id) }
                                .reduce(0) { $0 + $1.allocatedAmount }
                            let savingsTotal = budgetModel.budgetItems
                                .filter { $0.type == .savings }
                                .reduce(0) { $0 + $1.allocatedAmount }
                            let totalBudget = debtTotal + expenseTotal + savingsTotal
                            let remaining = monthlyIncome - totalBudget
                            
                            // Budget Status Section
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(remaining >= 0 ? "Budget Surplus" : "Budget Deficit")
                                        .font(.system(size: 15))
                                        .foregroundColor(Theme.secondaryLabel)
                                    Spacer()
                                    Button(action: { withAnimation { showDetailedSummary.toggle() }}) {
                                        HStack(spacing: 4) {
                                            Text(showDetailedSummary ? "Hide" : "Show")
                                            Image(systemName: "chevron.down")
                                                .rotationEffect(.degrees(showDetailedSummary ? 180 : 0))
                                        }
                                        .font(.system(size: 15))
                                        .foregroundColor(Theme.tint)
                                    }
                                }
                                
                                Text(formatCurrency(abs(remaining * periodMultiplier)))
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(remaining >= 0 ? Theme.tint : .red)
                                
                                if showDetailedSummary {
                                    VStack(spacing: 12) {
                                        Divider().background(Theme.separator)
                                        
                                        summaryRow(title: "Debt", amount: debtTotal * periodMultiplier)
                                        summaryRow(title: "Expenses", amount: expenseTotal * periodMultiplier)
                                        summaryRow(title: "Savings", amount: savingsTotal * periodMultiplier)
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        }
                        .padding()
                        .background(Theme.surfaceBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Categories List
                        VStack(spacing: 16) {
                            // Debt Items
                            if !budgetModel.budgetItems.filter({ $0.isActive && $0.type == .expense && isDebtCategory($0.category.id) }).isEmpty {
                                categoryHeader(title: "DEBT")
                                categoryItems(items: budgetModel.budgetItems.filter { $0.isActive && $0.type == .expense && isDebtCategory($0.category.id) })
                            }
                            
                            // Expense Items
                            if !budgetModel.budgetItems.filter({ $0.isActive && $0.type == .expense && !isDebtCategory($0.category.id) }).isEmpty {
                                categoryHeader(title: "EXPENSES")
                                categoryItems(items: budgetModel.budgetItems.filter { $0.isActive && $0.type == .expense && !isDebtCategory($0.category.id) })
                            }
                            
                            // Savings Items
                            if !budgetModel.budgetItems.filter({ $0.isActive && $0.type == .savings }).isEmpty {
                                categoryHeader(title: "SAVINGS")
                                categoryItems(items: budgetModel.budgetItems.filter { $0.isActive && $0.type == .savings })
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .background(Theme.background)
        .sheet(isPresented: $showBudgetBuilder, onDismiss: {
            budgetModel.setupInitialBudget(selectedCategoryIds: Set(budgetStore.configurations.keys))
            budgetModel.calculateUnusedAmount()
        }) {
            BudgetBuilderModal(
                isPresented: $showBudgetBuilder,
                budgetStore: budgetStore,
                budgetModel: budgetModel,
                monthlyIncome: monthlyIncome
            )
        }
    }
    
    private func categoryHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.tint.opacity(0.1))
                .cornerRadius(4)
            
            Spacer()
            
            Button(action: {}) {
                HStack(spacing: 4) {
                    Text("Add")
                        .font(.system(size: 15))
                    Image(systemName: "plus")
                }
                .foregroundColor(Theme.tint)
            }
        }
    }
    
    private func categoryItems(items: [BudgetItem]) -> some View {
        VStack(spacing: 1) {
            ForEach(items) { item in
                CategoryItemView(item: item, periodMultiplier: periodMultiplier)
            }
        }
        .cornerRadius(12)
    }
    
    private var emptyStateView: some View {
            VStack(spacing: 20) {
                Text("Let's build a budget that works for you")
                    .font(.system(size: 17))
                    .foregroundColor(Theme.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                VStack(spacing: 12) {
                    // Manual Build Button
                    Button(action: { showBudgetBuilder = true }) {
                        VStack(spacing: 6) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Build on your own")
                                        .font(.system(size: 17, weight: .semibold))
                                    Text("Create your budget step by step")
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                Text("Recommended")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(Theme.tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.tint.opacity(0.15))
                            .cornerRadius(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                    
                    // Auto Build Button
                    Button(action: {}) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Build for me")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Based on your income")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
            }
        }
    
    private func summaryRow(title: String, amount: Double) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
            Spacer()
            Text(formatCurrency(amount))
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
    }
    
    private func isDebtCategory(_ id: String) -> Bool {
        ["credit_cards", "student_loans", "personal_loans", "car_loan"].contains(id)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

