import SwiftUI

struct StickyIncomeHeader: View {
   let monthlyIncome: Double
   let payPeriod: PayPeriod  // Add PayPeriod parameter
   
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
   
   @State private var selectedPeriod: IncomePeriod = .annual
   
   var body: some View {
       VStack(spacing: 0) {
           VStack(spacing: 12) {
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
               
               // Income Display
               HStack(alignment: .center) {
                   Text("Your \(selectedPeriod.rawValue) Income")
                       .font(.system(size: 17))
                       .foregroundColor(Theme.label)
                   
                   Spacer()
                   
                   Text(formatCurrency(displayedAmount))
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
           .padding(.vertical, 16)
       }
       .background(Theme.background)
   }
   
   private var incomePercentile: Int {
       for (threshold, percentile) in incomePercentiles {
           if annualIncome >= threshold {
               return percentile
           }
       }
       return 80 // Default if below all thresholds
   }
   
   private func formatCurrency(_ value: Double) -> String {
       let formatter = NumberFormatter()
       formatter.numberStyle = .currency
       formatter.maximumFractionDigits = 0
       return formatter.string(from: NSNumber(value: value)) ?? "$0"
   }
}
