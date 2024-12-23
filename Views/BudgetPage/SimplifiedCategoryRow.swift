import SwiftUI

struct SimplifiedCategoryRow: View {
    let item: BudgetItem
    @ObservedObject var budgetModel: BudgetModel
    @State private var isExpanded = false
    @State private var isCustomAmount = false
    @State private var customAmount = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Row
            HStack {
                Text(item.category.emoji)
                    .font(.system(size: 20))
                Text(item.category.name)
                    .font(.system(size: 17))
                    .foregroundColor(Theme.label)
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.secondaryLabel)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.leading, 4)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { item.isActive },
                    set: { newValue in
                        withAnimation {
                            budgetModel.toggleCategory(id: item.id)
                            if newValue {
                                isExpanded = true
                            }
                        }
                    }
                ))
                .tint(Theme.tint)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 16) {
                    // Description
                    Text(item.category.description)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryLabel.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    
                    // Amount Section (if active)
                    if item.isActive {
                        VStack(spacing: 12) {
                            // Recommended Amount Display
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recommended monthly amount")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.secondaryLabel)
                                
                                if isCustomAmount {
                                    TextField("Enter amount", text: $customAmount)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(8)
                                        .background(Theme.surfaceBackground)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                } else {
                                    Text(formatCurrency(item.allocatedAmount))
                                        .font(.system(size: 17))
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Theme.surfaceBackground)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                }
                            }
                            
                            // Edit/Update Button
                            Button(action: {
                                if isCustomAmount {
                                    if let amount = Double(customAmount) {
                                        budgetModel.updateAllocation(for: item.id, amount: amount)
                                    }
                                    isCustomAmount = false
                                } else {
                                    customAmount = String(format: "%.0f", item.allocatedAmount)
                                    isCustomAmount = true
                                }
                            }) {
                                Text(isCustomAmount ? "Update Amount" : "Edit Amount")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Theme.tint)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 16)
            }
        }
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
