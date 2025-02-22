import SwiftUI

struct EnhancedBudgetHeader: View {
    @Binding var selectedPeriod: IncomePeriod
    let monthlyIncome: Double
    let payPeriod: PayPeriod
    @Binding var showDetailedSummary: Bool
    let debtTotal: Double
    let expenseTotal: Double
    let savingsTotal: Double
    
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
    
    var body: some View {
        VStack(spacing: 16) {
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
            
            // Income and Budget Summary
            VStack(spacing: 8) {
                // Monthly Income Row
                HStack {
                    Text("\(selectedPeriod.rawValue) Income")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(formatCurrency(totalIncome))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Budget Status
                HStack {
                    Text(remaining >= 0 ? "Budget Surplus" : "Budget Deficit")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(formatCurrency(abs(remaining)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(remaining >= 0 ? Theme.tint : .red)
                }
            }
            .padding(16)
            .background(Theme.surfaceBackground)
            .cornerRadius(16)
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
    EnhancedBudgetHeader(
        selectedPeriod: .constant(.monthly),
        monthlyIncome: 5000,
        payPeriod: .monthly,
        showDetailedSummary: .constant(false),
        debtTotal: 1000,
        expenseTotal: 2000,
        savingsTotal: 500
    )
    .padding()
    .background(Theme.background)
}

