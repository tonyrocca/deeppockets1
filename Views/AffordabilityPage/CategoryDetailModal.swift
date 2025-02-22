import SwiftUI

// MARK: - CategoryDetailModal
struct CategoryDetailModal: View {
    let category: BudgetCategory
    let amount: Double
    let displayType: AmountDisplayType
    let isPinned: Bool
    @Binding var isPresented: Bool
    let onAssumptionsChanged: (String, [CategoryAssumption]) -> Void
    let onPinChanged: (String, Bool) -> Void
    @State private var localAssumptions: [CategoryAssumption]
    @State private var showAddToBudgetConfirmation = false
    @State private var showingAddedToBudget = false
    @EnvironmentObject private var budgetModel: BudgetModel
    @FocusState private var focusedField: String?
    
    init(category: BudgetCategory,
         amount: Double,
         displayType: AmountDisplayType,
         isPinned: Bool,
         isPresented: Binding<Bool>,
         onAssumptionsChanged: @escaping (String, [CategoryAssumption]) -> Void,
         onPinChanged: @escaping (String, Bool) -> Void) {
        self.category = category
        self.amount = amount
        self.displayType = displayType
        self.isPinned = isPinned
        self._isPresented = isPresented
        self.onAssumptionsChanged = onAssumptionsChanged
        self.onPinChanged = onPinChanged
        self._localAssumptions = State(initialValue: category.assumptions)
    }
    
    private var isInBudget: Bool {
        budgetModel.budgetItems.contains { $0.id == category.id && $0.isActive }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text(category.emoji)
                            .font(.title2)
                        Text(category.name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(formatCurrency(amount))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                    
                    // Content sections
                    VStack(alignment: .leading, spacing: 24) {
                        // Allocation Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ALLOCATION OF SALARY")
                                .sectionHeader()
                            Text(category.formattedAllocation)
                                .font(.system(size: 17))
                                .foregroundColor(Theme.label)
                        }
                        
                        // Monthly Section (if total)
                        if displayType == .total {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ESTIMATED MONTHLY ALLOCATION")
                                    .sectionHeader()
                                Text(formatCurrency(amount / 12))
                                    .font(.system(size: 17))
                                    .foregroundColor(Theme.label)
                            }
                        }
                        
                        // Description Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPTION")
                                .sectionHeader()
                            Text(category.description)
                                .font(.system(size: 15))
                                .foregroundColor(Theme.secondaryLabel)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Assumptions Section
                        if !localAssumptions.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("ASSUMPTIONS")
                                    .sectionHeader()
                                
                                ForEach(localAssumptions.indices, id: \.self) { index in
                                    VStack(alignment: .leading, spacing: 4) {
                                        // Title
                                        Text(localAssumptions[index].title)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Theme.label)
                                        
                                        // Description (if available)
                                        if let description = localAssumptions[index].description {
                                            Text(description)
                                                .font(.system(size: 13))
                                                .foregroundColor(Theme.secondaryLabel)
                                                .padding(.bottom, 2)
                                        }
                                        
                                        // Input Field
                                        HStack {
                                            // Different prefix based on input type
                                            if case .textField = localAssumptions[index].inputType {
                                                Text("$")
                                                    .foregroundColor(.white)
                                            }
                                            
                                            // Text Field
                                            TextField("", text: $localAssumptions[index].value)
                                                .keyboardType(.decimalPad)
                                                .focused($focusedField, equals: localAssumptions[index].id)
                                                .font(.system(size: 17))
                                                .foregroundColor(.white)
                                                .onChange(of: localAssumptions[index].value) { newValue in
                                                    // Filter invalid characters
                                                    let filtered = newValue.filter { "0123456789.".contains($0) }
                                                    if filtered != newValue {
                                                        localAssumptions[index].value = filtered
                                                    }
                                                    onAssumptionsChanged(category.id, localAssumptions)
                                                }
                                            
                                            // Different suffix based on input type
                                            switch localAssumptions[index].inputType {
                                            case .percentageSlider:
                                                Text("%")
                                                    .foregroundColor(Theme.secondaryLabel)
                                            case .yearSlider:
                                                Text("yrs")
                                                    .foregroundColor(Theme.secondaryLabel)
                                            default:
                                                EmptyView()
                                            }
                                        }
                                        .padding()
                                        .background(Theme.surfaceBackground)
                                        .cornerRadius(8)
                                    }
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                        
                        // Action Buttons Row
                        VStack(spacing: 12) {
                            if !isInBudget {
                                Button(action: { showAddToBudgetConfirmation = true }) {
                                    HStack {
                                        Text("Add to Budget")
                                        Image(systemName: "plus.circle.fill")
                                    }
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.surfaceBackground)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            } else {
                                HStack {
                                    Text("Added to Budget")
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                .font(.system(size: 15))
                                .foregroundColor(Theme.tint)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Theme.surfaceBackground)
                                .cornerRadius(8)
                            }
                            
                            Button(action: {
                                onPinChanged(category.id, !isPinned)
                            }) {
                                HStack {
                                    Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                                    Text(isPinned ? "Unpin" : "Pin")
                                }
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Theme.surfaceBackground)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.secondaryLabel)
                }
            )
            .background(Theme.background)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                        onAssumptionsChanged(category.id, localAssumptions)
                    }
                }
            }
            .gesture(
                TapGesture()
                    .onEnded { _ in
                        focusedField = nil
                        onAssumptionsChanged(category.id, localAssumptions)
                    }
            )
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
