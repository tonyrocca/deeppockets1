import SwiftUI

struct CustomPickerView: View {
    @Binding var selectedPayPeriod: PayPeriod?
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(PayPeriod.allCases, id: \.self) { period in
                Button(action: {
                    selectedPayPeriod = period
                    isPresented = false
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            selectedPayPeriod == period ?
                            Theme.tint.opacity(0.2) :
                            Color.clear
                        )
                }
                
                if period != PayPeriod.allCases.last {
                    Divider()
                        .background(Theme.separator)
                }
            }
        }
        .background(Theme.surfaceBackground)
        .cornerRadius(12)
    }
}

struct SalaryInputView: View {
    @StateObject private var affordabilityModel = AffordabilityModel()
    @State private var paycheck: String = ""
    @State private var selectedPayPeriod: PayPeriod?
    @State private var showAffordability = false
    @State private var showPicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    // Pay Period Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pay Frequency")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.label)
                        Text("How often do you receive your paycheck?")
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                            .padding(.bottom, 4)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showPicker.toggle()
                            }
                        }) {
                            HStack {
                                Text(selectedPayPeriod?.rawValue ?? "Select frequency")
                                    .font(.system(size: 17))
                                    .foregroundColor(Theme.label)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16))
                                    .foregroundColor(Theme.label)
                                    .rotationEffect(showPicker ? .degrees(180) : .degrees(0))
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity)
                            .background(Theme.surfaceBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.separator, lineWidth: 1)
                            )
                        }
                        
                        if showPicker {
                            CustomPickerView(selectedPayPeriod: $selectedPayPeriod, isPresented: $showPicker)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Take Home Pay Section
                    if selectedPayPeriod != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Take Home Pay")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Theme.label)
                            Text("Enter your take-home pay per paycheck")
                                .font(.system(size: 17))
                                .foregroundColor(Theme.secondaryLabel)
                                .padding(.bottom, 4)
                            
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
                            .frame(maxWidth: .infinity)
                            .background(Theme.surfaceBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.separator, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 16)
                        .transition(.opacity)
                    }
                    
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
                                .frame(height: 56)
                                .background(Theme.tint)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 16)
                        .transition(.opacity)
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

struct SalaryInputView_Previews: PreviewProvider {
    static var previews: some View {
        SalaryInputView()
            .preferredColorScheme(.dark)
    }
}
