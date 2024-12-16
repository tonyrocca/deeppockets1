import SwiftUI

struct SalaryInputView: View {
    @StateObject private var affordabilityModel = AffordabilityModel()
    @State private var paycheck: String = ""
    @State private var selectedPayPeriod: PayPeriod = .biweekly
    @State private var showAffordability = false
    
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Text("Deep Pockets")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(Theme.label)
                
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Enter your paycheck amount")
                            .font(.headline)
                            .foregroundColor(Theme.label)
                        
                        TextField("Amount", text: $paycheck)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(Theme.CustomTextFieldStyle())
                            .tint(Theme.tint)
                            .foregroundColor(Theme.label)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How often are you paid?")
                            .font(.headline)
                            .foregroundColor(Theme.label)
                        
                        Picker("Pay Period", selection: $selectedPayPeriod) {
                            ForEach(PayPeriod.allCases, id: \.self) { period in
                                Text(period.rawValue)
                                    .foregroundColor(Theme.label)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .tint(Theme.tint)
                    }
                }
                .padding(.horizontal)
                
                Button {
                    if let amount = Double(paycheck) {
                        affordabilityModel.monthlyIncome = amount * selectedPayPeriod.multiplier
                        showAffordability = true
                    }
                } label: {
                    Text("Calculate What You Can Afford")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.tint)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationDestination(isPresented: $showAffordability) {
            AffordabilityView(model: affordabilityModel)
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
