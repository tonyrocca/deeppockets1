import SwiftUI

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
    
    private var periodSuffix: String {
        displayType == .monthly ? "/mo" : " total"
    }
    
    var body: some View {
        ZStack {
            // Background
            Theme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with title and close button
                HStack {
                    Text(category.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                }
                .padding()
                
                // Main content in ScrollView
                ScrollView {
                    VStack(spacing: 16) {
                        // Category Card with amount
                        HStack(spacing: 12) {
                            // Category icon in circle
                            ZStack {
                                Circle()
                                    .fill(Theme.tint.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Text(category.emoji)
                                    .font(.system(size: 24))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.name)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Allocation: \(category.formattedAllocation) of income")
                                    .font(.system(size: 15))
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                            
                            Spacer()
                            
                            Text(formatCurrency(amount) + periodSuffix)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Theme.tint)
                        }
                        .padding()
                        .background(Theme.surfaceBackground)
                        .cornerRadius(16)
                        
                        // Monthly equivalent (if total)
                        if displayType == .total {
                            HStack {
                                Text("Monthly Equivalent:")
                                    .font(.system(size: 17))
                                    .foregroundColor(Theme.secondaryLabel)
                                
                                Spacer()
                                
                                Text(formatCurrency(amount / 12) + "/mo")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Theme.surfaceBackground)
                            .cornerRadius(16)
                        }
                        
                        // Description Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DESCRIPTION")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.tint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.tint.opacity(0.1))
                                .cornerRadius(4)
                            
                            Text(category.description)
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(Theme.surfaceBackground)
                        .cornerRadius(16)
                        
                        // Assumptions Section
                        if !localAssumptions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("ASSUMPTIONS")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.tint)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.tint.opacity(0.1))
                                    .cornerRadius(4)
                                
                                ForEach(localAssumptions.indices, id: \.self) { index in
                                    AssumptionCard(
                                        assumption: $localAssumptions[index],
                                        onChanged: { _ in
                                            onAssumptionsChanged(category.id, localAssumptions)
                                        }
                                    )
                                }
                            }
                            .padding()
                            .background(Theme.surfaceBackground)
                            .cornerRadius(16)
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            // Pin Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    onPinChanged(category.id, !isPinned)
                                }
                            }) {
                                HStack {
                                    Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                                    Text(isPinned ? "Unpin Category" : "Pin Category")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Theme.surfaceBackground)
                                .cornerRadius(12)
                            }
                            
                            // Budget Button (conditionally styled)
                            if !isInBudget {
                                Button(action: { showAddToBudgetConfirmation = true }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add to Budget")
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Theme.tint)
                                    .cornerRadius(12)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Added to Budget")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.tint)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Theme.tint.opacity(0.15))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            // Add to Budget confirmation overlay
            if showAddToBudgetConfirmation {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .overlay(
                        addToBudgetConfirmation
                    )
            }
            
            // Added to Budget notification
            if showingAddedToBudget {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Added to Budget")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Theme.tint)
                    .cornerRadius(12)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    private var addToBudgetConfirmation: some View {
        VStack(spacing: 24) {
            // Title and description
            VStack(spacing: 8) {
                Text("Add to Budget")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Would you like to add \(category.name) to your budget with the recommended amount?")
                    .font(.system(size: 17))
                    .foregroundColor(Theme.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            
            // Amount display
            VStack(spacing: 4) {
                Text("Recommended Monthly Amount")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.secondaryLabel)
                
                Text(formatCurrency(displayType == .monthly ? amount : amount / 12))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    addToBudget()
                    showAddToBudgetConfirmation = false
                }) {
                    Text("Yes, Add to Budget")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.tint)
                        .cornerRadius(12)
                }
                
                Button(action: { showAddToBudgetConfirmation = false }) {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.surfaceBackground)
                        .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .background(Theme.background)
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
    
    private func addToBudget() {
        let monthlyAllocation = (displayType == .monthly)
            ? amount
            : amount / 12
        
        budgetModel.toggleCategory(id: category.id)
        budgetModel.updateAllocation(for: category.id, amount: monthlyAllocation)
        
        withAnimation {
            showingAddedToBudget = true
            showAddToBudgetConfirmation = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingAddedToBudget = false
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// Improved Assumption Card
struct AssumptionCard: View {
    @Binding var assumption: CategoryAssumption
    let onChanged: (CategoryAssumption) -> Void
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title row
            HStack {
                Text(assumption.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(assumption.displayValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.tint)
            }
            
            // Interactive control based on input type
            switch assumption.inputType {
            case .percentageSlider(let step):
                sliderControl(step: step)
                
            case .yearSlider(let min, let max):
                yearSliderControl(min: min, max: max)
                
            case .textField:
                textFieldControl()
                
            case .percentageDistribution:
                // Simplified for this example
                Text("Distribution controls not shown")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
            }
            
            // Description if available
            if let description = assumption.description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
                    .lineSpacing(2)
            }
        }
        .padding(12)
        .background(Theme.elevatedBackground)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func sliderControl(step: Double) -> some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { Double(assumption.value) ?? 0 },
                    set: { newValue in
                        assumption.value = String(format: "%.2f", newValue.rounded(to: step))
                        onChanged(assumption)
                    }
                ),
                in: 0...100,
                step: step
            )
            .tint(Theme.tint)
            
            // Range indicators
            HStack {
                Text("0%")
                    .foregroundColor(Theme.secondaryLabel)
                Spacer()
                Text("100%")
                    .foregroundColor(Theme.secondaryLabel)
            }
            .font(.system(size: 12))
        }
    }
    
    @ViewBuilder
    private func yearSliderControl(min: Int, max: Int) -> some View {
        VStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { Double(assumption.value) ?? Double(min) },
                    set: { newValue in
                        assumption.value = String(format: "%.0f", newValue)
                        onChanged(assumption)
                    }
                ),
                in: Double(min)...Double(max),
                step: 1
            )
            .tint(Theme.tint)
            
            // Range indicators
            HStack {
                Text("\(min) years")
                    .foregroundColor(Theme.secondaryLabel)
                Spacer()
                Text("\(max) years")
                    .foregroundColor(Theme.secondaryLabel)
            }
            .font(.system(size: 12))
        }
    }
    
    @ViewBuilder
    private func textFieldControl() -> some View {
        // Simple text field implementation
        TextField("", text: Binding(
            get: { assumption.value },
            set: { newValue in
                assumption.value = newValue
                onChanged(assumption)
            }
        ))
        .padding(10)
        .background(Theme.surfaceBackground)
        .cornerRadius(8)
        .keyboardType(.numberPad)
    }
}

// Extension to round doubles to specific step
extension Double {
    func rounded(to step: Double) -> Double {
        return (self / step).rounded() * step
    }
}

#Preview {
    CategoryDetailModal(
        category: BudgetCategory(
            id: "investments",
            name: "Investments",
            emoji: "📈",
            description: "Monthly contributions to investment accounts for long-term wealth building. Regular investing helps take advantage of compound interest and market growth over time.",
            allocationPercentage: 0.1,
            recommendedAmount: 500,
            displayType: .monthly,
            assumptions: [
                CategoryAssumption(
                    title: "Expected Return",
                    value: "8.5",
                    inputType: .percentageSlider(step: 0.5),
                    description: "Average annual return on investment"
                ),
                CategoryAssumption(
                    title: "Time Horizon",
                    value: "25",
                    inputType: .yearSlider(min: 5, max: 40),
                    description: "Years until you plan to access these funds"
                )
            ],
            type: .savings,
            priority: 2
        ),
        amount: 500,
        displayType: .monthly,
        isPinned: true,
        isPresented: .constant(true),
        onAssumptionsChanged: { _, _ in },
        onPinChanged: { _, _ in }
    )
    .environmentObject(BudgetModel(monthlyIncome: 5000))
}
