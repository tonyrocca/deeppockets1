import SwiftUI

// MARK: - Income Period Enum
enum IncomePeriod: String, CaseIterable {
    case annual = "Annual"
    case monthly = "Monthly"
    case perPaycheck = "Per Paycheck"
    
    func formatIncome(_ monthlyIncome: Double, payPeriod: PayPeriod) -> Double {
        switch self {
        case .annual:
            return monthlyIncome * 12
        case .monthly:
            return monthlyIncome
        case .perPaycheck:
            return monthlyIncome / payPeriod.multiplier
        }
    }
}

// MARK: - CategoryItemView
struct CategoryItemView: View {
    let item: BudgetItem
    let periodMultiplier: Double
    let selectedPeriod: IncomePeriod
    let payPeriod: PayPeriod
    
    @State private var isExpanded = false
    @State private var showDeleteConfirmation = false
    
    // States for editing allocation
    @State private var showEditModal = false
    @State private var editAmount: String = ""
    
    @EnvironmentObject private var budgetModel: BudgetModel
    
    // Computed property for the “current displayed amount”
    private var currentAmount: Double {
        item.allocatedAmount * periodMultiplier
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Row
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    Text(item.category.emoji)
                        .font(.title3)
                    Text(item.category.name)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    Spacer()
                    Text(formatCurrency(currentAmount))
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Theme.surfaceBackground)
            }
            
            // Expanded Details
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Allocation Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ALLOCATION OF INCOME")
                            .sectionHeader()
                        Text("\(Int(item.category.allocationPercentage * 100))%")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                    }
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DESCRIPTION")
                            .sectionHeader()
                        Text(item.category.description)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            // Prepare edit state
                            editAmount = String(format: "%.0f", currentAmount)
                            showEditModal = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit")
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
                        
                        Button(action: { showDeleteConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Theme.surfaceBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding()
                .background(Theme.elevatedBackground)
            }
            
            // Divider if expanded
            if isExpanded {
                Divider()
                    .background(Theme.separator)
            }
        }
        // Overlays
        .overlay {
            if showDeleteConfirmation {
                deleteConfirmationOverlay
            }
        }
        .sheet(isPresented: $showEditModal) {
            EditAmountModal(
                isPresented: $showEditModal,
                category: item.category,
                currentAmount: currentAmount,
                selectedPeriod: selectedPeriod,
                payPeriod: payPeriod,
                onSave: { newAmount in
                    let monthlyAmount: Double
                    switch selectedPeriod {
                    case .annual:
                        monthlyAmount = newAmount / 12
                    case .monthly:
                        monthlyAmount = newAmount
                    case .perPaycheck:
                        monthlyAmount = newAmount * payPeriod.multiplier
                    }
                    budgetModel.updateAllocation(for: item.id, amount: monthlyAmount)
                }
            )
        }
    }
    
    // MARK: - Delete Confirmation Overlay
    private var deleteConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Delete Category")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Are you sure you want to delete \(item.category.name) from your budget?")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        budgetModel.deleteCategory(id: item.id)
                        showDeleteConfirmation = false
                    }) {
                        Text("Yes, Delete")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    
                    Button(action: { showDeleteConfirmation = false }) {
                        Text("No, Keep It")
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
    
    // MARK: - Helper
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct EditAmountModal: View {
    @Binding var isPresented: Bool
    let category: BudgetCategory
    let currentAmount: Double
    let selectedPeriod: IncomePeriod
    let payPeriod: PayPeriod
    let onSave: (Double) -> Void
    
    @State private var editAmount: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Current Amount Display
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Amount")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                    Text(formatCurrency(currentAmount))
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // New Amount Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Amount")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack {
                        Text("$")
                            .foregroundColor(.white)
                        TextField("", text: $editAmount)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                            .placeholder(when: editAmount.isEmpty) {
                                Text("e.g. \(String(format: "%.0f", currentAmount))")
                                    .foregroundColor(Color.white.opacity(0.6))
                            }
                        Group {
                            switch selectedPeriod {
                            case .annual:
                                Text("/yr")
                            case .monthly:
                                Text("/mo")
                            case .perPaycheck:
                                Text("/paycheck")
                            }
                        }
                        .foregroundColor(Color.white.opacity(0.6))
                    }
                    .padding(16)
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.separator, lineWidth: 1)
                    )
                }
                
                Spacer()
            }
            .padding()
            .background(Theme.background)
            .navigationTitle("Edit \(category.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let newAmount = Double(editAmount) {
                            onSave(newAmount)
                        }
                        isPresented = false
                    }
                    .disabled(editAmount.isEmpty)
                    .foregroundColor(editAmount.isEmpty ? Color.white.opacity(0.6) : .white)
                }
            }
            .onAppear {
                editAmount = String(format: "%.0f", currentAmount)
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

// MARK: - BudgetView
struct BudgetView: View {
    let monthlyIncome: Double
    let payPeriod: PayPeriod
    
    @State private var selectedPeriod: IncomePeriod = .monthly
    @State private var showBudgetBuilder = false
    @State private var showDetailedSummary = false
    @StateObject private var budgetStore = BudgetStore()
    @State private var showingDebtSheet = false
    @State private var showingExpenseSheet = false
    @State private var showingSavingsSheet = false
    @State private var selectedCategories: Set<String> = []
    
    @EnvironmentObject private var budgetModel: BudgetModel
    
    private var periodMultiplier: Double {
        switch selectedPeriod {
        case .annual: return 12
        case .monthly: return 1
        case .perPaycheck: return 1 / payPeriod.multiplier
        }
    }
    
    private var debtCategories: [BudgetCategory] {
        BudgetCategoryStore.shared.categories.filter { isDebtCategory($0.id) }
    }

    private var expenseCategories: [BudgetCategory] {
        BudgetCategoryStore.shared.categories.filter {
            !isDebtCategory($0.id) && !isSavingsCategory($0.id)
        }
    }

    private var savingsCategories: [BudgetCategory] {
        BudgetCategoryStore.shared.categories.filter { isSavingsCategory($0.id) }
    }

    private func isSavingsCategory(_ id: String) -> Bool {
        ["emergency_savings", "investments", "college_savings", "vacation"].contains(id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if budgetModel.budgetItems.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Period Selector
                        HStack(spacing: 0) {
                            ForEach(IncomePeriod.allCases, id: \.self) { period in
                                Button(action: { withAnimation { selectedPeriod = period }}) {
                                    Text(period.rawValue)
                                        .font(.system(size: 15))
                                        .foregroundColor(selectedPeriod == period ? .white : Theme.secondaryLabel)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 32)
                                        .background(
                                            selectedPeriod == period
                                            ? Theme.tint
                                            : Color.clear
                                        )
                                }
                            }
                        }
                        .background(Theme.surfaceBackground)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        // Budget Summary
                        VStack(spacing: 0) {
                            // Calculations
                            let debtTotal = budgetModel.budgetItems
                                .filter { $0.type == .expense && isDebtCategory($0.category.id) }
                                .reduce(0) { $0 + $1.allocatedAmount }
                            let expenseTotal = budgetModel.budgetItems
                                .filter { $0.type == .expense && !isDebtCategory($0.category.id) }
                                .reduce(0) { $0 + $1.allocatedAmount }
                            let savingsTotal = budgetModel.budgetItems
                                .filter { $0.type == .savings }
                                .reduce(0) { $0 + $1.allocatedAmount }
                            let totalBudget = debtTotal + expenseTotal + savingsTotal
                            let remaining = monthlyIncome - totalBudget
                            
                            // Income Row
                            HStack {
                                Text("\(selectedPeriod.rawValue) Income")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(formatCurrency(monthlyIncome * periodMultiplier))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 8)
                            
                            // Surplus/Deficit Row
                            HStack {
                                Text(remaining >= 0 ? "Budget Surplus" : "Budget Deficit")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(formatCurrency(abs(remaining * periodMultiplier)))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(remaining >= 0 ? Theme.tint : .red)
                            }
                            .padding(.bottom, 6)
                            
                            if showDetailedSummary {
                                Divider()
                                    .background(Theme.separator)
                                    .padding(.vertical, 8)
                                
                                VStack(spacing: 12) {
                                    summaryRow(title: "Debt", amount: debtTotal * periodMultiplier)
                                    summaryRow(title: "Expenses", amount: expenseTotal * periodMultiplier)
                                    summaryRow(title: "Savings", amount: savingsTotal * periodMultiplier)
                                }
                            }
                        }
                        .padding(16)
                        .background(Theme.surfaceBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .onTapGesture {
                            withAnimation {
                                showDetailedSummary.toggle()
                            }
                        }
                        
                        // Categories List
                        VStack(spacing: 16) {
                            // Debt
                            let debtItems = budgetModel.budgetItems.filter {
                                $0.isActive && $0.type == .expense && isDebtCategory($0.category.id)
                            }
                            categorySection(title: "DEBT", items: debtItems)
                            
                            // Expenses
                            let expenseItems = budgetModel.budgetItems.filter {
                                $0.isActive && $0.type == .expense && !isDebtCategory($0.category.id)
                            }
                            categorySection(title: "EXPENSES", items: expenseItems)
                            
                            // Savings
                            let savingsItems = budgetModel.budgetItems.filter {
                                $0.isActive && $0.type == .savings
                            }
                            categorySection(title: "SAVINGS", items: savingsItems)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .background(Theme.background)
        .sheet(isPresented: $showBudgetBuilder, onDismiss: {
            budgetModel.setupInitialBudget(selectedCategoryIds: Set(budgetStore.configurations.keys))
            budgetModel.calculateUnusedAmount()
        }) {
            BudgetBuilderModal(
                isPresented: $showBudgetBuilder,
                budgetStore: budgetStore,
                budgetModel: budgetModel,
                monthlyIncome: monthlyIncome
            )
        }
        .sheet(isPresented: $showingDebtSheet) {
            NavigationView {
                CategorySelectionView(
                    categories: debtCategories,
                    selectedCategories: $selectedCategories,
                    monthlyIncome: monthlyIncome
                )
                // ... rest of debt sheet content
            }
            .background(Theme.background)
        }
        .sheet(isPresented: $showingExpenseSheet) {
            // Expense sheet content
        }
        .sheet(isPresented: $showingSavingsSheet) {
            // Savings sheet content
        }
    }
    
    private func addSelectedCategoriesToBudget() {
        for categoryId in selectedCategories {
            if let category = BudgetCategoryStore.shared.categories.first(where: { $0.id == categoryId }) {
                let recommendedAmount = monthlyIncome * category.allocationPercentage
                budgetStore.setCategory(category, amount: recommendedAmount)
                budgetModel.toggleCategory(id: category.id)
                budgetModel.updateAllocation(for: category.id, amount: recommendedAmount)
            }
        }
        budgetModel.calculateUnusedAmount()
        selectedCategories.removeAll()
    }
    
    // MARK: - Helpers
    private func categorySection(title: String, items: [BudgetItem]) -> some View {
        VStack(spacing: 8) {
            categoryHeader(title: title)
            if items.isEmpty {
                Text("No categories in budget")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.secondaryLabel)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                categoryItems(items: items)
            }
        }
    }
    
    private func categoryHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.tint.opacity(0.1))
                .cornerRadius(4)
            Spacer()
            
            Button(action: {
                selectedCategories.removeAll()
                switch title {
                case "DEBT": showingDebtSheet = true
                case "EXPENSES": showingExpenseSheet = true
                case "SAVINGS": showingSavingsSheet = true
                default: break
                }
            }) {
                HStack(spacing: 4) {
                    Text("Add")
                    Image(systemName: "plus")
                }
                .foregroundColor(Theme.tint)
                .font(.system(size: 17))
            }
        }
    }
    
    private func categoryItems(items: [BudgetItem]) -> some View {
        VStack(spacing: 1) {
            ForEach(items) { item in
                CategoryItemView(
                    item: item,
                    periodMultiplier: periodMultiplier,
                    selectedPeriod: selectedPeriod,
                    payPeriod: payPeriod
                )
                .environmentObject(budgetModel)
            }
        }
        .cornerRadius(12)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Text("Let's build a budget that works for you")
                .font(.system(size: 17))
                .foregroundColor(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            VStack(spacing: 12) {
                Button(action: {
                    showBudgetBuilder = true  // This triggers the modal
                }) {
                    VStack(spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Build on your own")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Create your budget step by step")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("Recommended")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Theme.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.tint.opacity(0.15))
                        .cornerRadius(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
                .buttonStyle(PressableButtonStyle())
                
                // Auto Build Button
                Button(action: {}) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Build for me")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Based on your income")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 16)
        }
    }
    
    struct PressableButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .opacity(configuration.isPressed ? 0.8 : 1.0)
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
    
    private func summaryRow(title: String, amount: Double) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
            Spacer()
            Text(formatCurrency(amount))
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
    }
    
    private func isDebtCategory(_ id: String) -> Bool {
        ["credit_cards", "student_loans", "personal_loans", "car_loan"].contains(id)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
