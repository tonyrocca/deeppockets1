import SwiftUI

// MARK: - IncomePeriod Enum
enum IncomePeriod: String, CaseIterable {
    case annual = "Annual"
    case monthly = "Monthly"
    case perPaycheck = "Per Paycheck"
    
    func formatIncome(_ monthlyIncome: Double, payPeriod: PayPeriod) -> Double {
        switch self {
        case .annual: return monthlyIncome * 12
        case .monthly: return monthlyIncome
        case .perPaycheck: return monthlyIncome / payPeriod.multiplier
        }
    }
}

// MARK: - BudgetHeader View
struct BudgetHeader: View {
    let monthlyIncome: Double
    let payPeriod: PayPeriod
    @State private var selectedPeriod: IncomePeriod = .monthly
    
    private let incomePercentiles: [(threshold: Double, percentile: Int)] = [
        (650000, 1), (250000, 5), (180000, 10),
        (120000, 20), (90000, 30), (70000, 40),
        (50000, 50), (35000, 60), (25000, 70)
    ]
    
    private var annualIncome: Double { monthlyIncome * 12 }
    private var incomePercentile: Int {
        for (threshold, percentile) in incomePercentiles {
            if annualIncome >= threshold { return percentile }
        }
        return 80
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Period Toggle Bar
            HStack(spacing: 0) {
                ForEach(IncomePeriod.allCases, id: \.self) { period in
                    Button(action: {
                        withAnimation { selectedPeriod = period }
                    }) {
                        Text(period.rawValue)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedPeriod == period ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                selectedPeriod == period ? Color.white : Color.clear
                            )
                    }
                }
            }
            .background(Theme.surfaceBackground)
            .cornerRadius(8)
            
            // Income Display
            VStack(alignment: .leading, spacing: 12) {
                // Amount
                Text(formatCurrency(selectedPeriod.formatIncome(monthlyIncome, payPeriod: payPeriod)))
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(Theme.label)
                
                // Percentile badge
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                    Text("Top \(incomePercentile)% Income")
                }
                .font(.system(size: 13))
                .foregroundColor(Theme.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.tint.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Preview Provider
struct BudgetHeader_Previews: PreviewProvider {
    static var previews: some View {
        BudgetHeader(monthlyIncome: 10000, payPeriod: .monthly)
            .preferredColorScheme(.dark)
    }
}
