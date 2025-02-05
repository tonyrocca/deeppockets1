import SwiftUI

struct StickyIncomeHeader: View {
    let monthlyIncome: Double
    let payPeriod: PayPeriod
    @State private var selectedPeriod: IncomePeriod = .annual
    @State private var showPeriodPicker = false
    
    private var annualIncome: Double {
        monthlyIncome * 12
    }
    
    private var displayedAmount: Double {
        switch selectedPeriod {
        case .annual:
            return annualIncome
        case .monthly:
            return monthlyIncome
        case .perPaycheck:
            return monthlyIncome / payPeriod.multiplier
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                // Income Display with Dropdown
                HStack(alignment: .center) {
                    HStack(spacing: 4) {
                        Text("Your")
                            .font(.system(size: 17))
                        
                        // Period Menu
                        Menu {
                            ForEach(IncomePeriod.allCases, id: \.self) { period in
                                Button(action: {
                                    withAnimation {
                                        selectedPeriod = period
                                    }
                                }) {
                                    Text(period.rawValue)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedPeriod.rawValue)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(Theme.tint)
                        }
                        
                        Text("Income")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(Theme.label)
                    
                    Spacer()
                    
                    Text(formatCurrency(displayedAmount))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Theme.label)
                }
            }
            .padding(16)
            .background(Theme.surfaceBackground)
            .cornerRadius(16)
            .padding(.horizontal, 16)
            
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
            .padding(.vertical, 12)
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
