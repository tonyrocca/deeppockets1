import SwiftUI

struct StickyIncomeHeader: View {
    let monthlyIncome: Double
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
    
    private var annualIncome: Double {
        monthlyIncome * 12
    }
    
    private var incomePercentile: Int {
        for (threshold, percentile) in incomePercentiles {
            if annualIncome >= threshold {
                return percentile
            }
        }
        return 80 // Default if below all thresholds
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Income Section
            VStack(spacing: 12) {
                // Income Row
                HStack {
                    Text("Annual Income")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.label)
                    
                    Spacer()
                    
                    Text(formatCurrency(annualIncome))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.label)
                }
                
                // Percentile Row
                HStack {
                    Text("You are a top \(incomePercentile)% earner in the United States based on your salary")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.secondaryLabel)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                        Text("Top \(incomePercentile)%")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(Theme.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(Theme.tint.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            .padding(16)
            .background(Theme.surfaceBackground)
            .cornerRadius(16)
            
            Divider()
                .background(Theme.separator)
                .padding(.vertical, 12)
            
            // Title Section
            VStack(alignment: .leading, spacing: 4) {
                Text("What You Can Afford")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.label)
                Text("This is what you can afford based on your income")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.secondaryLabel)
            }
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
