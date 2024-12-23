import SwiftUI

struct BudgetItemRow: View {
    let item: BudgetItem
    let onAmountChanged: (Double) -> Void
    let onDelete: () -> Void
    @State private var isEditing = false
    @State private var tempAmount: String = ""
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text(item.category.emoji)
                    .font(.title2)
                Text(item.category.name)
                    .font(.system(size: 17))
                    .foregroundColor(Theme.label)
                Spacer()
                
                if isEditing {
                    HStack {
                        Text("$")
                            .foregroundColor(Theme.label)
                        TextField("Amount", text: $tempAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(Theme.label)
                    }
                    .padding(8)
                    .background(Theme.elevatedBackground)
                    .cornerRadius(8)
                    
                    Button(action: {
                        if let amount = Double(tempAmount) {
                            onAmountChanged(amount)
                        }
                        isEditing = false
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.tint)
                    }
                } else {
                    Text(formatCurrency(item.allocatedAmount))
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .onTapGesture {
                            tempAmount = String(format: "%.0f", item.allocatedAmount)
                            isEditing = true
                        }
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.elevatedBackground)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(getProgressColor(percentage: item.percentageSpent))
                        .frame(width: geometry.size.width * CGFloat(min(item.percentageSpent / 100, 1)))
                        .frame(height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            // Details
            HStack {
                Text("Spent: \(formatCurrency(item.spentAmount))")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.secondaryLabel)
                Spacer()
                Text("Remaining: \(formatCurrency(item.remainingAmount))")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.secondaryLabel)
            }
        }
        .padding()
        .background(Theme.surfaceBackground)
        .cornerRadius(12)
        .contextMenu {
            if item.category.id.hasPrefix("custom_") {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Category", systemImage: "trash")
                }
            }
        }
    }
    
    private func getProgressColor(percentage: Double) -> Color {
        switch percentage {
        case 0..<80: return Theme.tint
        case 80..<100: return .orange
        default: return .red
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
