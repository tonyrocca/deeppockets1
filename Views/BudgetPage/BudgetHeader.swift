import SwiftUI

struct EnhancedBudgetHeader: View {
    @Binding var selectedPeriod: IncomePeriod
    let monthlyIncome: Double
    let payPeriod: PayPeriod
    @Binding var showDetailedSummary: Bool
    let debtTotal: Double
    let expenseTotal: Double
    let savingsTotal: Double
    var onAllocationAction: () -> Void
    
    private var periodMultiplier: Double {
        switch selectedPeriod {
        case .annual: return 12
        case .monthly: return 1
        case .perPaycheck: return 1 / payPeriod.multiplier
        }
    }
    
    private var totalIncome: Double {
        monthlyIncome * periodMultiplier
    }
    
    private var totalBudget: Double {
        (debtTotal + expenseTotal + savingsTotal) * periodMultiplier
    }
    
    private var remaining: Double {
        totalIncome - totalBudget
    }
    
    private var periodSuffix: String {
        switch selectedPeriod {
        case .annual: return "/yr"
        case .monthly: return "/mo"
        case .perPaycheck: return "/paycheck"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Simplified Period Selector
            HStack(spacing: 0) {
                ForEach(IncomePeriod.allCases, id: \.self) { period in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedPeriod = period
                        }
                    }) {
                        Text(period.rawValue)
                            .font(.system(size: 14, weight: selectedPeriod == period ? .semibold : .regular))
                            .foregroundColor(selectedPeriod == period ? .white : Theme.secondaryLabel)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                    }
                    .background(
                        ZStack {
                            if selectedPeriod == period {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Theme.tint)
                                    .transition(.opacity)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(4)
            .background(Theme.surfaceBackground)
            .cornerRadius(8)
            
            // Enhanced Income and Budget Summary
            VStack(spacing: 12) {
                // Income Row with improved visual
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(selectedPeriod.rawValue) Income")
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                    
                    Spacer()
                    
                    Text(formatCurrency(totalIncome))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Divider()
                    .background(Theme.separator.opacity(0.5))
                
                // Budget Status with amount
                VStack(spacing: 12) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(remaining >= 0 ? "Budget Surplus" : "Budget Deficit")
                                .font(.system(size: 17))
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            // Visual indicator
                            if remaining >= 0 {
                                Circle()
                                    .fill(Theme.tint)
                                    .frame(width: 8, height: 8)
                            } else {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                            }
                            
                            Text(formatCurrency(abs(remaining)))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(remaining >= 0 ? Theme.tint : .red)
                        }
                    }
                    
                    // Action button below
                    Button(action: onAllocationAction) {
                        HStack {
                            Image(systemName: remaining >= 0 ? "plus.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                            Text(remaining >= 0 ? "Allocate Surplus" : "Fix Deficit")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(remaining >= 0 ? Theme.tint : .red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(
                            (remaining >= 0 ? Theme.tint : Color.red)
                                .opacity(0.15)
                                .cornerRadius(8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    (remaining >= 0 ? Theme.tint : Color.red).opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                    }
                }
                
                // Only show detailed breakdown if enabled
                if showDetailedSummary {
                    Divider()
                        .background(Theme.separator.opacity(0.5))
                        .padding(.vertical, 4)
                    
                    VStack(spacing: 12) {
                        summaryRow(title: "Savings", amount: savingsTotal * periodMultiplier)
                        summaryRow(title: "Expenses", amount: expenseTotal * periodMultiplier)
                        summaryRow(title: "Debt", amount: debtTotal * periodMultiplier)
                    }
                }
            }
            .padding(16)
            .background(Theme.surfaceBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDetailedSummary.toggle()
                }
            }
        }
    }
    
    private func summaryRow(title: String, amount: Double) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
            Spacer()
            Text(formatCurrency(amount))
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        
        VStack {
            EnhancedBudgetHeader(
                selectedPeriod: .constant(.monthly),
                monthlyIncome: 9750,
                payPeriod: .monthly,
                showDetailedSummary: .constant(false),
                debtTotal: 5433,
                expenseTotal: 3000,
                savingsTotal: 1000,
                onAllocationAction: {}
            )
            .padding()
            
            Spacer()
        }
    }
}
