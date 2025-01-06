import SwiftUI

struct BudgetView: View {
    let monthlyIncome: Double
    let payPeriod: PayPeriod
    @State private var selectedTimePeriod: IncomePeriod = .monthly
    @State private var showBudgetBuilder = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Income Display Section
            VStack(spacing: 16) {
                // Time Period Selector
                HStack(spacing: 0) {
                    ForEach(IncomePeriod.allCases, id: \.self) { period in
                        Button(action: {
                            withAnimation { selectedTimePeriod = period }
                        }) {
                            Text(period.rawValue)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(selectedTimePeriod == period ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(
                                    selectedTimePeriod == period ? Color.white : Color.clear
                                )
                        }
                    }
                }
                .background(Theme.surfaceBackground)
                .cornerRadius(8)
                .padding(.horizontal, 16)
                
                // Income Amount
                Text(formatIncome())
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(Theme.label)
                
                // Income Percentile Badge
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                    Text("Top \(calculateIncomePercentile())% Income")
                }
                .font(.system(size: 13))
                .foregroundColor(Theme.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.tint.opacity(0.15))
                .cornerRadius(8)
            }
            .padding(.vertical, 24)
            .background(Theme.background)
            
            // Empty State / Build Budget Button
            if !showBudgetBuilder {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Text("Let's build a budget that works for you")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button(action: {
                        withAnimation {
                            showBudgetBuilder = true
                        }
                    }) {
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
        }
    }
    
    private func formatIncome() -> String {
        let amount = selectedTimePeriod.formatIncome(monthlyIncome, payPeriod: payPeriod)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
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
