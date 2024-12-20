import SwiftUI

struct AffordabilityCalculatorModal: View {
    @Binding var isPresented: Bool
    let monthlyIncome: Double
    @State private var selectedCategory: BudgetCategory?
    @State private var amount: String = ""
    @State private var displayType: AmountDisplayType = .monthly
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Content
                VStack(spacing: 24) {
                    // Title Section
                    VStack(spacing: 8) {
                        Text("Affordability Check")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.label)
                        Text("See if you can afford your expenses")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                    .padding(.top, 8)
                    
                    // Category Selection
                    Menu {
                        ForEach(BudgetCategoryStore.shared.categories) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category.name)
                            }
                        }
                    } label: {
                        HStack {
                            if let category = selectedCategory {
                                Text(category.emoji)
                                Text(category.name)
                            } else {
                                Text("Select Category")
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .font(.system(size: 17))
                        .foregroundColor(Theme.label)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Theme.surfaceBackground)
                        .cornerRadius(12)
                    }
                    
                    // Amount Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Theme.label)
                        
                        HStack {
                            Text("$")
                                .foregroundColor(Theme.label)
                            TextField("0", text: $amount)
                                .keyboardType(.decimalPad)
                                .foregroundColor(Theme.label)
                        }
                        .padding()
                        .background(Theme.surfaceBackground)
                        .cornerRadius(12)
                    }
                    
                    // Frequency Selection
                    Picker("Frequency", selection: $displayType) {
                        Text("Monthly").tag(AmountDisplayType.monthly)
                        Text("Total").tag(AmountDisplayType.total)
                    }
                    .pickerStyle(.segmented)
                    
                    // Results (if input is valid)
                    if let category = selectedCategory, let amountValue = Double(amount) {
                        let canAfford = calculateAffordability(amount: amountValue, category: category)
                        VStack(spacing: 16) {
                            Text(canAfford.0 ? "You can afford this! 🎉" : "This might be a stretch 😅")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(canAfford.0 ? Theme.tint : .red)
                            
                            Text(canAfford.1)
                                .font(.system(size: 15))
                                .foregroundColor(Theme.secondaryLabel)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Theme.background)
            .cornerRadius(20)
            .padding()
        }
    }
    
    private func calculateAffordability(amount: Double, category: BudgetCategory) -> (Bool, String) {
        let monthlyAmount = displayType == .monthly ? amount : amount / 12
        let affordableAmount = monthlyIncome * category.allocationPercentage
        let difference = abs(affordableAmount - monthlyAmount)
        
        if monthlyAmount <= affordableAmount {
            return (true, "You're under your recommended monthly budget by \(formatCurrency(difference))")
        } else {
            return (false, "You're over your recommended monthly budget by \(formatCurrency(difference))")
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
