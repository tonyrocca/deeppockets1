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
    @StateObject private var budgetStore = BudgetStore()
    
    private var periodMultiplier: Double {
        switch selectedPeriod {
        case .annual: return 12
        case .monthly: return 1
        case .perPaycheck: return 1 / payPeriod.multiplier
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if budgetStore.configurations.isEmpty {
                // Empty State (unchanged)
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Period Selector
                        HStack(spacing: 0) {
                            ForEach(IncomePeriod.allCases, id: \.self) { period in
                                Button(action: {
                                    withAnimation { selectedPeriod = period }
                                }) {
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
                        .padding(.horizontal)
                        
                        // Monthly Summary
                        VStack(alignment: .leading, spacing: 16) {
                            Text("MONTHLY SUMMARY")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.tint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.tint.opacity(0.1))
                                .cornerRadius(4)
                            
                            VStack(spacing: 12) {
                                // Income row
                                budgetSummaryRow(
                                    title: "\(selectedPeriod == .monthly ? "Monthly" : selectedPeriod == .annual ? "Annual" : "Per Paycheck") Income",
                                    amount: monthlyIncome * periodMultiplier
                                )
                                
                                Divider().background(Theme.separator)
                                
                                budgetSummaryRow(
                                    title: "Debt Payments",
                                    amount: budgetStore.totalDebtPayments * periodMultiplier
                                )
                                
                                budgetSummaryRow(
                                    title: "Monthly Expenses",
                                    amount: budgetStore.totalMonthlyExpenses * periodMultiplier
                                )
                                
                                budgetSummaryRow(
                                    title: "Monthly Savings",
                                    amount: budgetStore.totalMonthlySavings * periodMultiplier
                                )
                                
                                Divider().background(Theme.separator)
                                
                                budgetSummaryRow(
                                    title: "Remaining",
                                    amount: (monthlyIncome - budgetStore.totalMonthlyBudget) * periodMultiplier,
                                    isTotal: true
                                )
                            }
                            .padding()
                            .background(Theme.surfaceBackground)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Categories
                        let debtCategories = budgetStore.debtCategories()
                        let expenseCategories = budgetStore.expenseCategories()
                        let savingsCategories = budgetStore.savingsCategories()
                        
                        // Category sections with adjusted amounts
                        if !debtCategories.isEmpty {
                            categorySection(title: "Debt", configurations: debtCategories)
                                .padding(.horizontal)
                        }
                        
                        if !expenseCategories.isEmpty {
                            categorySection(title: "Monthly Expenses", configurations: expenseCategories)
                                .padding(.horizontal)
                        }
                        
                        if !savingsCategories.isEmpty {
                            categorySection(title: "Savings Goals", configurations: savingsCategories)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
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
    
    // Modified category section to show period-adjusted amounts
    private func categorySection(title: String, configurations: [BudgetStore.CategoryConfiguration]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.tint)
            
            ForEach(configurations, id: \.category.id) { config in
                // Single row with horizontal layout
                HStack(spacing: 12) {
                    Text(config.category.emoji)
                        .font(.system(size: 20))
                    
                    Text(config.category.name)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    
                    Spacer(minLength: 16)
                    
                    Text("\(formatCurrency(config.amount * periodMultiplier))/\(periodSuffix)")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.secondaryLabel)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
            }
        }
    }
    
    private var periodSuffix: String {
            switch selectedPeriod {
            case .monthly: return "mo"
            case .annual: return "yr"
            case .perPaycheck: return "check"
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
    
    private func budgetSummaryRow(title: String, amount: Double, isTotal: Bool = false) -> some View {
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
