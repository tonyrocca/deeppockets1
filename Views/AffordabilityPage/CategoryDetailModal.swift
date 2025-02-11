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
    
    init(
        category: BudgetCategory,
        amount: Double,
        displayType: AmountDisplayType,
        isPinned: Bool,
        isPresented: Binding<Bool>,
        onAssumptionsChanged: @escaping (String, [CategoryAssumption]) -> Void,
        onPinChanged: @escaping (String, Bool) -> Void
    ) {
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
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                modalHeader()
                ScrollView { modalContent() }
                modalButtons()
            }
            .background(Theme.background)
            .cornerRadius(20)
            .padding(.horizontal, 20)
        }
        .overlay { if showAddToBudgetConfirmation { addToBudgetConfirmation } }
        .overlay { if showingAddedToBudget { addedToBudgetOverlay } }
    }
    
    // MARK: - Header
    private func modalHeader() -> some View {
        HStack {
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
            }
            Spacer()
            Text(category.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "xmark")
                .font(.system(size: 17))
                .foregroundColor(.clear) // Invisible for alignment
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Modal Content
    private func modalContent() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            categoryHeader()
            allocationSection()
            estimatedMonthlyAllocation()
            descriptionSection()
            assumptionsSection()
        }
        .padding(.vertical, 16)
    }
    
    private func categoryHeader() -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(category.emoji).font(.title3)
            Text(category.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.label)
            Spacer()
            Text(formatCurrency(amount) + (displayType == .monthly ? "/mo" : " total"))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.secondaryLabel)
        }
        .padding(.horizontal, 20)
    }
    
    private func allocationSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ALLOCATION OF SALARY").sectionHeader()
            Text(category.formattedAllocation)
                .font(.system(size: 17))
                .foregroundColor(Theme.label)
        }
        .padding(.horizontal, 20)
    }
    
    private func estimatedMonthlyAllocation() -> some View {
        if displayType == .total {
            let monthlyAmount = amount / 12
            return AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    Text("ESTIMATED MONTHLY ALLOCATION").sectionHeader()
                    Text(formatCurrency(monthlyAmount))
                        .font(.system(size: 17))
                        .foregroundColor(Theme.label)
                }
                .padding(.horizontal, 20)
            )
        }
        return AnyView(EmptyView())
    }
    
    private func descriptionSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DESCRIPTION").sectionHeader()
            Text(category.description)
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
    }
    
    private func assumptionsSection() -> some View {
        if !localAssumptions.isEmpty {
            return AnyView(
                VStack(alignment: .leading, spacing: 12) {
                    Text("ASSUMPTIONS").sectionHeader()
                    ForEach(localAssumptions.indices, id: \.self) { index in
                        AssumptionView(
                            assumption: $localAssumptions[index],
                            onChanged: { _ in
                                onAssumptionsChanged(category.id, localAssumptions)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            )
        }
        return AnyView(EmptyView())
    }
    
    // MARK: - Helpers (Fixing Missing Methods)
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private var addedToBudgetOverlay: some View {
        VStack {
            Text("Added to Budget")
                .padding()
                .background(Theme.tint)
                .cornerRadius(8)
                .foregroundColor(.white)
        }
        .transition(.scale.combined(with: .opacity))
        .animation(.easeInOut, value: showingAddedToBudget)
    }
    
    private var addToBudgetConfirmation: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Add to Budget")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text("Would you like to add \(category.name) to your budget with the recommended amount?")
                    .font(.system(size: 17))
                    .foregroundColor(Theme.secondaryLabel)
                    .multilineTextAlignment(.center)
                budgetAmountDisplay(amount: amount)
                confirmCancelButtons()
            }
            .padding(24)
            .background(Theme.background)
            .cornerRadius(20)
            .padding(.horizontal, 20)
        }
    }
    
    private func budgetAmountDisplay(amount: Double) -> some View {
        VStack(spacing: 4) {
            Text("Recommended Monthly Amount")
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
            Text(formatCurrency(amount))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Buttons Section (Fixed Missing `modalButtons()`)
    private func modalButtons() -> some View {
        HStack(spacing: 12) {
            pinButton()
            budgetButton()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private func pinButton() -> some View {
        Button(action: {
            onPinChanged(category.id, !isPinned)
            isPresented = false
        }) {
            HStack {
                Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                Text(isPinned ? "Unpin" : "Pin")
            }
        }
        .buttonStyle(DefaultButtonStyle())
    }
    
    private func budgetButton() -> some View {
        Button(action: { showAddToBudgetConfirmation = true }) {
            HStack {
                Text("Budget")
                Image(systemName: "plus")
            }
        }
        .buttonStyle(DefaultButtonStyle())
    }
    
    private func confirmCancelButtons() -> some View {
        VStack(spacing: 12) {
            Button(action: {
                showAddToBudgetConfirmation = false
            }) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
            }
        }
    }
}
