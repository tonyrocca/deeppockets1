import SwiftUI

struct StickyIncomeHeader: View {
    let monthlyIncome: Double
    let payPeriod: PayPeriod
    @State private var selectedPeriod: IncomePeriod = .annual
    
    private var displayedAmount: Double {
        switch selectedPeriod {
        case .annual:
            return monthlyIncome * 12
        case .monthly:
            return monthlyIncome
        case .perPaycheck:
            return monthlyIncome / payPeriod.multiplier
        }
    }
    
    private var displayPeriodText: String {
        switch selectedPeriod {
        case .annual:
            return "/year"
        case .monthly:
            return "/month"
        case .perPaycheck:
            return "/paycheck"
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Income Display Container
            VStack(spacing: 12) {
                // Income Amount with Period
                HStack(spacing: 0) {
                    Text(formatCurrency(displayedAmount))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Theme.label)
                    
                    Text(displayPeriodText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Theme.secondaryLabel)
                }
                
                // Period Selector
                HStack(spacing: 0) {
                    ForEach(IncomePeriod.allCases, id: \.self) { period in
                        Button(action: {
                            withAnimation {
                                selectedPeriod = period
                            }
                        }) {
                            Text(period.displayText)
                                .font(.system(size: 15))
                                .foregroundColor(selectedPeriod == period ? Theme.tint : Theme.secondaryLabel)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .frame(width: UIScreen.main.bounds.width - 64) // Matches the original width
                .background(Theme.surfaceBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(width: UIScreen.main.bounds.width - 32) // Matches the original container width
            .background(Theme.surfaceBackground)
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
        .background(Theme.background)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

extension IncomePeriod {
    var displayText: String {
        switch self {
        case .annual:
            return "Year"
        case .monthly:
            return "Month"
        case .perPaycheck:
            return "Paycheck"
        }
    }
}
