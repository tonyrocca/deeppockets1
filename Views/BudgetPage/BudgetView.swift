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

struct BudgetView: View {
    let monthlyIncome: Double
    let payPeriod: PayPeriod
    @State private var selectedPeriod: IncomePeriod = .monthly
    @State private var showBudgetBuilder = false
    @StateObject private var budgetStore = BudgetStore()  // Keep BudgetStore for the modal
    @EnvironmentObject private var budgetModel: BudgetModel  // Keep BudgetModel for main functionality
    
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
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("Let's build a budget that works for you")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    VStack(spacing: 12) {
                        // Recommended option
                        Button(action: { showBudgetBuilder = true }) {
                            VStack(spacing: 8) {
                                Text("Build on your own")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Recommended")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.tint)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Theme.tint.opacity(0.15))
                                    .cornerRadius(4)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(Theme.surfaceBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.tint, lineWidth: 1)
                            )
                        }
                        
                        // Automated option (disabled for now)
                        Button(action: {}) {
                            VStack(spacing: 4) {
                                Text("Build for me")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Based on your income")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(Theme.surfaceBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Period Selector
                        periodSelector
                            .padding(.horizontal)
                        
                        // Monthly Summary
                        summarySection
                            .padding(.horizontal)
                        
                        // Category Sections
                        categorySection(
                            title: "DEBT",
                            items: budgetModel.budgetItems.filter { $0.type == .expense && isDebtCategory($0.category.id) }
                        )
                        .padding(.horizontal)
                        
                        categorySection(
                            title: "EXPENSES",
                            items: budgetModel.budgetItems.filter { $0.type == .expense && !isDebtCategory($0.category.id) }
                        )
                        .padding(.horizontal)
                        
                        categorySection(
                            title: "SAVINGS",
                            items: budgetModel.budgetItems.filter { $0.type == .savings }
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .sheet(isPresented: $showBudgetBuilder) {
            BudgetBuilderModal(
                isPresented: $showBudgetBuilder,
                budgetStore: budgetStore,
                monthlyIncome: monthlyIncome
            )
        }
    }

    private func categorySection(title: String, items: [BudgetItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.mutedGreen.opacity(0.2))
                    .cornerRadius(4)
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.tint)
                }
            }
            
            if items.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Text("No \(title.lowercased()) categories added")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.secondaryLabel)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
            } else {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        Text(item.category.emoji)
                            .font(.title3)
                        Text(item.category.name)
                            .font(.system(size: 17))
                            .foregroundColor(Theme.label)
                        Spacer()
                        Text(formatCurrency(item.allocatedAmount * periodMultiplier))
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                    .padding()
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(IncomePeriod.allCases, id: \.self) { period in
                Button(action: { withAnimation { selectedPeriod = period }}) {
                    Text(period.rawValue)
                        .font(.system(size: 17))
                        .foregroundColor(selectedPeriod == period ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(selectedPeriod == period ? Color.white : Color.clear)
                }
            }
        }
        .background(Theme.surfaceBackground)
        .cornerRadius(8)
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MONTHLY SUMMARY")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.tint.opacity(0.1))
                .cornerRadius(4)
            
            VStack(spacing: 12) {
                summaryRow(title: "Monthly Income", amount: monthlyIncome * periodMultiplier)
                Divider().background(Theme.separator)
                
                let debtTotal = budgetModel.budgetItems
                    .filter { $0.type == .expense && isDebtCategory($0.category.id) }
                    .reduce(0) { $0 + $1.allocatedAmount }
                summaryRow(title: "Debt Payments", amount: debtTotal * periodMultiplier)
                
                let expenseTotal = budgetModel.budgetItems
                    .filter { $0.type == .expense && !isDebtCategory($0.category.id) }
                    .reduce(0) { $0 + $1.allocatedAmount }
                summaryRow(title: "Monthly Expenses", amount: expenseTotal * periodMultiplier)
                
                let savingsTotal = budgetModel.budgetItems
                    .filter { $0.type == .savings }
                    .reduce(0) { $0 + $1.allocatedAmount }
                summaryRow(title: "Monthly Savings", amount: savingsTotal * periodMultiplier)
                
                Divider().background(Theme.separator)
                
                let totalBudget = debtTotal + expenseTotal + savingsTotal
                summaryRow(
                    title: "Remaining",
                    amount: (monthlyIncome - totalBudget) * periodMultiplier,
                    isTotal: true
                )
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("Let's build a budget that works for you")
                .font(.system(size: 17))
                .foregroundColor(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: { showBudgetBuilder = true }) {
                Text("Start Building Your Budget")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.tint)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            Spacer()
        }
    }
    
    private func summaryRow(title: String, amount: Double, isTotal: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: isTotal ? 17 : 15, weight: isTotal ? .semibold : .regular))
                .foregroundColor(isTotal ? Theme.label : Theme.secondaryLabel)
            Spacer()
            Text(formatCurrency(amount))
                .font(.system(size: isTotal ? 17 : 15, weight: isTotal ? .semibold : .regular))
                .foregroundColor(isTotal ? Theme.label : Theme.secondaryLabel)
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
    
    private func calculateIncomePercentile() -> Int {
        let annualIncome = monthlyIncome * 12
        let percentiles: [(threshold: Double, percentile: Int)] = [
            (650000, 1), (250000, 5), (180000, 10),
            (120000, 20), (90000, 30), (70000, 40),
            (50000, 50), (35000, 60), (25000, 70)
        ]
        
        for (threshold, percentile) in percentiles {
            if annualIncome >= threshold {
                return percentile
            }
        }
        return 80
    }
}
