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
    
    var body: some View {
            NavigationView {
                ZStack {
                    Theme.background
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Close button
                        HStack {
                            Spacer()
                            Button(action: { isPresented = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                        
                        // Sticky Header
                        HStack(spacing: 12) {
                        Text(category.emoji)
                            .font(.title2)
                        Text(category.name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                        Text(formatCurrency(amount) + (displayType == .monthly ? "/mo" : " total"))
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Theme.background)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Allocation Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ALLOCATION OF SALARY")
                                    .sectionHeader()
                                Text(category.formattedAllocation)
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                            }
                            
                            // Monthly Allocation (if total)
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
                            
                            // Action Buttons
                            StatusButtonGroup(
                                onExpand: { }, // Not needed in modal
                                onPin: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        onPinChanged(category.id, !isPinned)
                                    }
                                },
                                onAddToBudget: { showAddToBudgetConfirmation = true },
                                isPinned: isPinned,
                                isInBudget: isInBudget
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay {
                if showAddToBudgetConfirmation {
                    addToBudgetConfirmation
                }
            }
        }
    }
    
    private var addToBudgetConfirmation: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Add to Budget")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Would you like to add \(category.name) to your budget with the recommended amount?")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 4) {
                    Text("Recommended Monthly Amount")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.secondaryLabel)
                    Text(formatCurrency(displayType == .monthly ? amount : amount / 12))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
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
// MARK: - Header Height Preference Key
private struct HeaderHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
