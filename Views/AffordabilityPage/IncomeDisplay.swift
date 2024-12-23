import SwiftUI

struct StickyIncomeHeader: View {
    let monthlyIncome: Double
    @State private var isAnnual: Bool = true
    
    private var displayAmount: Double {
        isAnnual ? monthlyIncome * 12 : monthlyIncome
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 6) {
                Menu {
                    Button(action: { isAnnual = true }) {
                        Label("Annual Income", systemImage: isAnnual ? "checkmark" : "")
                    }
                    Button(action: { isAnnual = false }) {
                        Label("Monthly Income", systemImage: !isAnnual ? "checkmark" : "")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isAnnual ? "Annual Income" : "Monthly Income")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Theme.label)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.label)
                    }
                }
                
                Spacer()
                
                Text(formatCurrency(displayAmount))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Theme.label)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("What You Can Afford")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.label)
                Text("This is what you can afford based on your income")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.secondaryLabel)
            }
            .padding(.horizontal)
            .padding(.top, 8)
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
