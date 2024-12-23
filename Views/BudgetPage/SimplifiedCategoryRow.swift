import SwiftUI

struct SimplifiedCategoryRow: View {
    let item: BudgetItem
    @ObservedObject var budgetModel: BudgetModel
    @State private var isCustomAmount = false
    @State private var customAmount = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // Main Row
            HStack {
                Text(item.category.emoji)
                    .font(.system(size: 20))
                Text(item.category.name)
                    .font(.system(size: 17))
                    .foregroundColor(Theme.label)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { item.isActive },
                    set: { newValue in
                        withAnimation {
                            budgetModel.toggleCategory(id: item.id)
                        }
                    }
                ))
                .tint(Theme.tint)
            }
            
            // Description (more subtle)
            Text(item.category.description)
                .font(.system(size: 13))
                .foregroundColor(Theme.secondaryLabel.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Amount Section (if active)
            if item.isActive {
                HStack {
                    Text("Recommended monthly amount")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.secondaryLabel)
                    Spacer()
                    if isCustomAmount {
                        TextField("Enter amount", text: $customAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(Theme.label)
                            .onChange(of: customAmount) { newValue in
                                if let amount = Double(newValue) {
                                    budgetModel.updateAllocation(for: item.id, amount: amount)
                                }
                            }
                        Button("Reset") {
                            isCustomAmount = false
                            budgetModel.updateAllocation(for: item.id, amount: item.allocatedAmount)
                        }
                        .font(.system(size: 13))
                        .foregroundColor(Theme.tint)
                        .padding(.leading, 8)
                    } else {
                        Text(formatCurrency(item.allocatedAmount))
                            .font(.system(size: 17))
                            .foregroundColor(Theme.label)
                        Button("Edit") {
                            customAmount = String(format: "%.0f", item.allocatedAmount)
                            isCustomAmount = true
                        }
                        .font(.system(size: 13))
                        .foregroundColor(Theme.tint)
                        .padding(.leading, 8)
                    }
                }
            }
        }
        .padding()
        .background(Theme.surfaceBackground)
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
