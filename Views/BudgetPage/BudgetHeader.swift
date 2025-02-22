import SwiftUI

struct EnhancedBudgetHeader: View {
    let income: Double
    let budgetSurplus: Double
    let expenses: Double
    let savings: Double
    let debt: Double
    let periodType: String // "Annual", "Monthly", or "Per Paycheck"
    
    @State private var isExpanded = false
    
    private var totalAllocated: Double {
        return expenses + savings + debt
    }
    
    // Calculate percentage heights (capped at minimum 10% for visibility)
    private var expensesHeight: CGFloat {
        totalAllocated > 0 ? max(0.1, CGFloat(expenses / totalAllocated)) : 0.1
    }
    
    private var savingsHeight: CGFloat {
        totalAllocated > 0 ? max(0.1, CGFloat(savings / totalAllocated)) : 0.1
    }
    
    private var debtHeight: CGFloat {
        totalAllocated > 0 ? max(0.1, CGFloat(debt / totalAllocated)) : 0.1
    }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surfaceBackground)
            
            VStack(spacing: 0) {
                // Header section
                VStack(spacing: 16) {
                    // Income row
                    HStack {
                        Text("\(periodType) Income")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text(formatCurrency(income))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Budget Surplus row
                    HStack {
                        Text("Budget Surplus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text(formatCurrency(budgetSurplus))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.tint)
                    }
                    
                    // Divider with chevron indicator to show expandability
                    HStack {
                        VStack(spacing: 0) {
                            Divider()
                                .background(Theme.separator)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Theme.secondaryLabel)
                            .background(Theme.surfaceBackground)
                            .padding(.horizontal, 8)
                        
                        VStack(spacing: 0) {
                            Divider()
                                .background(Theme.separator)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }
                
                // Expandable budget breakdown with columns
                if isExpanded {
                    VStack(spacing: 24) {
                        // Bar chart
                        HStack(alignment: .bottom, spacing: 24) {
                            // Expenses Column
                            budgetColumn(
                                amount: expenses,
                                label: "Expenses",
                                height: expensesHeight,
                                color: Color.red.opacity(0.7)
                            )
                            
                            // Savings Column
                            budgetColumn(
                                amount: savings,
                                label: "Savings",
                                height: savingsHeight,
                                color: Theme.tint.opacity(0.8)
                            )
                            
                            // Debt Column
                            budgetColumn(
                                amount: debt,
                                label: "Debt",
                                height: debtHeight,
                                color: Color.blue.opacity(0.7)
                            )
                        }
                        .frame(height: 150)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func budgetColumn(amount: Double, label: String, height: CGFloat, color: Color) -> some View {
        VStack(spacing: 8) {
            // Amount label
            Text(formatCurrency(amount))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            
            // Column visualization
            VStack {
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .frame(height: 100 * height)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 100)
            
            // Category label
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(Theme.secondaryLabel)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct EnhancedBudgetHeader_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            EnhancedBudgetHeader(
                income: 4500,
                budgetSurplus: 675,
                expenses: 3562,
                savings: 263,
                debt: 0,
                periodType: "Per Paycheck"
            )
            .padding(.horizontal, 16)
        }
    }
}
