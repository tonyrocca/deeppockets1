import SwiftUI

// MARK: - IncomePeriod Enum
public enum IncomePeriod: String, CaseIterable {
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

// MARK: - BudgetHeader View
public struct BudgetHeader: View {
    let monthlyIncome: Double
    let payPeriod: PayPeriod
    @State private var selectedPeriod: IncomePeriod = .monthly
    
    private let incomePercentiles: [(threshold: Double, percentile: Int)] = [
        (650000, 1),
        (250000, 5),
        (180000, 10),
        (120000, 20),
        (90000, 30),
        (70000, 40),
        (50000, 50),
        (35000, 60),
        (25000, 70)
    ]
    
    public init(monthlyIncome: Double, payPeriod: PayPeriod) {
        self.monthlyIncome = monthlyIncome
        self.payPeriod = payPeriod
    }
    
    private var annualIncome: Double {
        monthlyIncome * 12
    }
    
    private var incomePercentile: Int {
        for (threshold, percentile) in incomePercentiles {
            if annualIncome >= threshold {
                return percentile
            }
        }
        return 80
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                periodToggleBar
                incomeDisplay
            }
            .padding(16)
            .background(Theme.surfaceBackground)
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Theme.background)
    }
    
    // MARK: - Subviews
    private var periodToggleBar: some View {
        HStack(spacing: 0) {
            ForEach(IncomePeriod.allCases, id: \.self) { period in
                toggleButton(for: period)
                
                if period != .perPaycheck {
                    Divider()
                        .background(Theme.separator)
                        .frame(height: 32)
                }
            }
        }
        .background(Theme.surfaceBackground)
        .cornerRadius(8)
    }
    
    private func toggleButton(for period: IncomePeriod) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPeriod = period
            }
        }) {
            Text(period.rawValue)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(selectedPeriod == period ? .black : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    selectedPeriod == period ?
                        Color.white :
                        Theme.surfaceBackground
                )
        }
    }
    
    private var incomeDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Income Row
            HStack(alignment: .center) {
                Text("\(selectedPeriod.rawValue) Income")
                    .font(.system(size: 17))
                    .foregroundColor(Theme.secondaryLabel)
                
                Spacer()
                
                Text(formatCurrency(selectedPeriod.formatIncome(monthlyIncome, payPeriod: payPeriod)))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Theme.label)
            }
            
            // Percentile Row
            HStack(alignment: .center, spacing: 8) {
                Text("You are a top \(incomePercentile)% earner in the USA based on your salary")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.secondaryLabel)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                    Text("Top \(incomePercentile)%")
                }
                .font(.system(size: 13))
                .foregroundColor(Theme.tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.tint.opacity(0.15))
                .cornerRadius(8)
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

// MARK: - Preview Provider
struct BudgetHeader_Previews: PreviewProvider {
    static var previews: some View {
        BudgetHeader(monthlyIncome: 10000, payPeriod: .monthly)
            .preferredColorScheme(.dark)
    }
}
