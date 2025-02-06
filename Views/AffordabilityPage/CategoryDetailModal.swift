import SwiftUI

// MARK: - CategoryDetailModal
struct CategoryDetailModal: View {
    let category: BudgetCategory
    let amount: Double
    let displayType: AmountDisplayType
    let isPinned: Bool
    @Binding var isPresented: Bool
    @State private var localAssumptions: [CategoryAssumption]
    let onAssumptionsChanged: (String, [CategoryAssumption]) -> Void
    let onPinChanged: (String, Bool) -> Void
    @EnvironmentObject private var budgetModel: BudgetModel
    @State private var showAddToBudgetConfirmation = false
    @State private var showingAddedToBudget = false
    
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
        self._localAssumptions = State(initialValue: category.assumptions)
        self.onAssumptionsChanged = onAssumptionsChanged
        self.onPinChanged = onPinChanged
    }
    
    private var isInBudget: Bool {
        budgetModel.budgetItems.contains { $0.id == category.id && $0.isActive }
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background that dismisses the modal on tap.
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Centered modal content (using similar styling to AffordabilityCalculatorModal)
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text(category.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        // Placeholder for alignment
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.clear)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Category Header
                            VStack(alignment: .center, spacing: 8) {
                                Text(category.emoji)
                                    .font(.system(size: 48))
                                Text(formatCurrency(amount) + (displayType == .monthly ? "/mo" : " total"))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            
                            // Allocation Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ALLOCATION OF SALARY")
                                    .sectionHeader()
                                Text(category.formattedAllocation)
                                    .font(.system(size: 17))
                                    .foregroundColor(Theme.label)
                            }
                            
                            // Monthly Allocation (for total amounts)
                            if displayType == .total {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("ESTIMATED MONTHLY ALLOCATION")
                                        .sectionHeader()
                                    let monthlyAmount = amount / 12
                                    Text(formatCurrency(monthlyAmount))
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
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("ASSUMPTIONS")
                                        .sectionHeader()
                                    
                                    ForEach(localAssumptions.indices, id: \.self) { index in
                                        AssumptionView(
                                            assumption: $localAssumptions[index],
                                            onChanged: { _ in
                                                onAssumptionsChanged(category.id, localAssumptions)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    
                    // Bottom Action Buttons
                    VStack(spacing: 12) {
                        // Add to Budget Button
                        if !isInBudget {
                            Button(action: { showAddToBudgetConfirmation = true }) {
                                HStack {
                                    Text("Budget")
                                    Image(systemName: "plus.circle.fill")
                                }
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Theme.tint)
                                .cornerRadius(12)
                            }
                        } else {
                            HStack {
                                Text("Added to Budget")
                                Image(systemName: "checkmark.circle.fill")
                            }
                            .font(.system(size: 17))
                            .foregroundColor(Theme.tint)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.surfaceBackground)
                            .cornerRadius(12)
                        }
                        
                        // Pin/Unpin Button
                        Button(action: {
                            onPinChanged(category.id, !isPinned)
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                                Text(isPinned ? "Unpin" : "Pin")
                            }
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.surfaceBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Theme.background)
                }
                .background(Theme.background)
                .cornerRadius(20)
                .padding(.horizontal, 20)
                Spacer()
            }
            
            // Add to Budget Confirmation Sheet
            if showAddToBudgetConfirmation {
                addToBudgetConfirmation
            }
            
            // Added to Budget Toast
            if showingAddedToBudget {
                VStack {
                    Text("Added to Budget")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Theme.tint)
                        .cornerRadius(8)
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut, value: showingAddedToBudget)
            }
        }
    }
    
    private var addToBudgetConfirmation: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Add to Budget")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Would you like to add \(category.name) to your budget with the recommended amount?")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                
                // Amount Display
                VStack(spacing: 4) {
                    Text("Recommended Monthly Amount")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.secondaryLabel)
                    Text(formatCurrency(displayType == .monthly ? amount : amount / 12))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Buttons
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(24)
            .background(Theme.background)
            .cornerRadius(20)
            .padding(.horizontal, 20)
        }
    }
    
    private func addToBudget() {
        // Calculate the recommended monthly amount
        let monthlyAllocation = displayType == .monthly ? amount : amount / 12
        
        // First activate the category
        budgetModel.toggleCategory(id: category.id)
        
        // Then set its allocation
        budgetModel.updateAllocation(for: category.id, amount: monthlyAllocation)
        
        // Show feedback
        withAnimation {
            showingAddedToBudget = true
            showAddToBudgetConfirmation = false
        }
        
        // Hide feedback after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingAddedToBudget = false
            }
        }
        
        // Close the modal
        isPresented = false
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - ActionButton (File Scope)
struct ActionButton: View {
    let icon: String
    let text: String
    let action: () -> Void
    let type: ButtonType
    let isModal: Bool
    
    enum ButtonType {
        case expand
        case pin
        case budget
        case added
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: isModal ? 17 : 15))
                Text(text)
            }
            .font(.system(size: isModal ? 17 : 15, weight: .medium))
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: isModal ? 56 : 44)
            .background(buttonBackground)
            .cornerRadius(isModal ? 12 : 8)
            .overlay(
                RoundedRectangle(cornerRadius: isModal ? 12 : 8)
                    .stroke(buttonBorder, lineWidth: 1)
            )
        }
    }
    
    private var buttonBackground: Color {
        switch type {
        case .budget where !isAdded:
            return Theme.background.opacity(0.3)
        case .expand, .pin, .budget, .added:
            return Theme.background.opacity(0.15)
        }
    }
    
    private var buttonBorder: Color {
        Color.white.opacity(0.1)
    }
    
    private var textColor: Color {
        switch type {
        case .added:
            return Theme.tint
        default:
            return .white
        }
    }
    
    private var isAdded: Bool {
        type == .added
    }
}

// MARK: - CategoryDetailModal Modal Buttons Extension
extension CategoryDetailModal {
    var modalButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Budget Button
                if !isInBudget {
                    ActionButton(
                        icon: "plus",
                        text: "Add to Budget",
                        action: { showAddToBudgetConfirmation = true },
                        type: .budget,
                        isModal: true
                    )
                } else {
                    ActionButton(
                        icon: "checkmark.circle.fill",
                        text: "Added",
                        action: {},
                        type: .added,
                        isModal: true
                    )
                }
                
                // Pin Button
                ActionButton(
                    icon: isPinned ? "pin.slash.fill" : "pin.fill",
                    text: isPinned ? "Unpin" : "Pin",
                    action: {
                        onPinChanged(category.id, !isPinned)
                        isPresented = false
                    },
                    type: .pin,
                    isModal: true
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Theme.background)
    }
}
