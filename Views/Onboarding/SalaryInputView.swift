import SwiftUI

struct SalaryInputView: View {
    @StateObject private var affordabilityModel = AffordabilityModel()
    @State private var paycheck: String = ""
    @State private var selectedPayPeriod: PayPeriod?
    @State private var showAffordability = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Take Home Pay Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Take Home Pay")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.label)
                        Text("Enter your take-home pay per paycheck")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                            .padding(.bottom, 8)
                        
                        HStack {
                            Text("$")
                                .font(.system(size: 17))
                                .foregroundColor(Theme.label)
                            TextField("0", text: $paycheck)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 17))
                                .foregroundColor(Theme.label)
                        }
                        .padding(16)
                        .background(Theme.surfaceBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.separator, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Pay Period Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pay Frequency")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.label)
                        Text("How often do you receive this amount?")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                            .padding(.bottom, 8)
                        
                        Menu {
                            ForEach(PayPeriod.allCases, id: \.self) { period in
                                Button(action: {
                                    selectedPayPeriod = period
                                }) {
                                    HStack {
                                        Text(period.rawValue)
                                            .foregroundColor(Theme.label)
                                        Spacer()
                                        if period == selectedPayPeriod {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(Theme.label)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedPayPeriod?.rawValue ?? "Select frequency")
                                    .font(.system(size: 17))
                                    .foregroundColor(Theme.label)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.label)
                            }
                            .padding(16)
                            .background(Theme.surfaceBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.separator, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Calculate Button
                    if !paycheck.isEmpty && selectedPayPeriod != nil {
                        Button {
                            if let amount = Double(paycheck),
                               let period = selectedPayPeriod {
                                affordabilityModel.monthlyIncome = amount * period.multiplier
                                showAffordability = true
                            }
                        } label: {
                            Text("Calculate What You Can Afford")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.tint)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 34)
                    }
                }
                .padding(.top, 60)
            }
            .navigationDestination(isPresented: $showAffordability) {
                MainContentView(monthlyIncome: affordabilityModel.monthlyIncome)
            }
        }
    }
}

// Preview Provider
struct SalaryInputView_Previews: PreviewProvider {
   static var previews: some View {
       SalaryInputView()
           .preferredColorScheme(.dark)
   }
}
