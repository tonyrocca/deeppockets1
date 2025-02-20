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
                        .background(selectedPayPeriod == period ? Theme.tint.opacity(0.2) : Color.clear)
                }
                if period != PayPeriod.allCases.last {
                    Divider().background(Theme.separator)
                }
            }
        }
        .background(Theme.surfaceBackground)
        .cornerRadius(12)
    }
}

struct SalaryInputView: View {
    @AppStorage("paycheck") var paycheck: String = ""
    @AppStorage("selectedPayPeriod") var selectedPayPeriodRaw: String = "Monthly"
    @AppStorage("monthlyIncome") var monthlyIncome: Double = 0
    
    // Computed property for selected pay period.
    var selectedPayPeriod: PayPeriod {
        get { PayPeriod(rawValue: selectedPayPeriodRaw) ?? .monthly }
        set { selectedPayPeriodRaw = newValue.rawValue }
    }
    
    @StateObject private var affordabilityModel = AffordabilityModel()
    @State private var showAffordability = false
    @State private var showPicker = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                // Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
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
                            Text(selectedPayPeriod.rawValue)
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
                        CustomPickerView(
                            selectedPayPeriod: Binding<PayPeriod?>(
                                get: { PayPeriod(rawValue: selectedPayPeriodRaw) ?? .monthly },
                                set: { newValue in
                                    if let newValue = newValue {
                                        selectedPayPeriodRaw = newValue.rawValue
                                    }
                                }
                            ),
                            isPresented: $showPicker
                        )
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 16)
                
                // Take Home Pay Section
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
                            .foregroundColor(.white)
                        TextField("e.g. 2000", text: $paycheck)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .placeholder(when: paycheck.isEmpty) {
                                Text("e.g. 2000")
                                    .foregroundColor(Color.white.opacity(0.6))
                            }
                        Text("/\(selectedPayPeriod.rawValue.lowercased())")
                            .font(.system(size: 17))
                            .foregroundColor(Color.white.opacity(0.6))
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
                
                Spacer()
                
                // Calculate Button
                if !paycheck.isEmpty {
                    Button {
                        if let amount = Double(paycheck) {
                            monthlyIncome = amount * selectedPayPeriod.multiplier
                            affordabilityModel.monthlyIncome = monthlyIncome
                            // Mark onboarding as complete
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
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
                    .padding(.bottom, 16)
                    .transition(.opacity)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showAffordability) {
            MainContentView()
        }
    }
}

#Preview {
    NavigationStack {
        SalaryInputView()
            .preferredColorScheme(.dark)
    }
}
