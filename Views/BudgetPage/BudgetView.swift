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

// MARK: - BudgetView (Updated with EnhancedBudgetHeader)
struct BudgetView: View {
    let monthlyIncome: Double
    let payPeriod: PayPeriod
    
    @State private var selectedPeriod: IncomePeriod = .monthly
    @State private var showImprovements = false
    @State private var showBudgetBuilder = false
    @State private var showDetailedSummary = false
    @StateObject private var budgetStore = BudgetStore()
    @State private var showingDebtSheet = false
    @State private var showingExpenseSheet = false
    @State private var showingSavingsSheet = false
    @State private var selectedCategories: Set<String> = []
    @State private var selectedDebtPhase: BudgetBuilderPhase = .debtSelection
    @State private var selectedExpensePhase: BudgetBuilderPhase = .expenseSelection
    @State private var selectedSavingsPhase: BudgetBuilderPhase = .savingsSelection
    @State private var debtInputData: [String: DebtInputData] = [:]
    @State private var temporaryAmounts: [String: Double] = [:]
    
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

    // Filtered category getters
    private var availableDebtCategories: [BudgetCategory] {
        debtCategories.filter { category in
            !budgetModel.budgetItems.contains { $0.category.id == category.id }
        }
    }

    private var availableExpenseCategories: [BudgetCategory] {
        expenseCategories.filter { category in
            !budgetModel.budgetItems.contains { $0.category.id == category.id }
        }
    }

    private var availableSavingsCategories: [BudgetCategory] {
        savingsCategories.filter { category in
            !budgetModel.budgetItems.contains { $0.category.id == category.id }
        }
    }
    
    private func getTotalConfigurableExpenses() -> Int {
        selectedCategories.filter { id in
            expenseCategories.contains(where: { $0.id == id })
        }.count
    }

    private func getCurrentExpenseIndex(for category: BudgetCategory) -> Int {
        let selectedExpenseIds = selectedCategories
            .filter { id in
                expenseCategories.contains(where: { $0.id == id })
            }
            .sorted()
        
        return selectedExpenseIds.firstIndex(of: category.id) ?? 0
    }

    private func binding(for category: BudgetCategory) -> Binding<Double?> {
        Binding(
            get: { temporaryAmounts[category.id] },
            set: { temporaryAmounts[category.id] = $0 }
        )
    }

    private func getButtonTitle(for phase: BudgetBuilderPhase) -> String {
        switch phase {
        case .debtSelection, .expenseSelection, .savingsSelection:
            return selectedCategories.isEmpty ? "Skip" : "Next"
        case .debtConfiguration, .expenseConfiguration, .savingsConfiguration:
            return "Continue"
        default:
            return ""
        }
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
                        // Enhanced Budget Header
                        EnhancedBudgetHeader(
                            selectedPeriod: $selectedPeriod,
                            monthlyIncome: monthlyIncome,
                            payPeriod: payPeriod,
                            showDetailedSummary: $showDetailedSummary,
                            debtTotal: budgetModel.budgetItems
                                .filter { $0.type == .expense && isDebtCategory($0.category.id) }
                                .reduce(0) { $0 + $1.allocatedAmount },
                            expenseTotal: budgetModel.budgetItems
                                .filter { $0.type == .expense && !isDebtCategory($0.category.id) }
                                .reduce(0) { $0 + $1.allocatedAmount },
                            savingsTotal: budgetModel.budgetItems
                                .filter { $0.type == .savings }
                                .reduce(0) { $0 + $1.allocatedAmount }
                        )
                        .padding(.horizontal)
                        
                        if !budgetModel.budgetItems.isEmpty {
                            Button(action: { showImprovements = true }) {
                                                            HStack {
                                                                Image(systemName: "sparkles")
                                                                    .font(.system(size: 16))
                                                                Text("Enhance Your Budget")
                                                                    .font(.system(size: 17, weight: .medium))
                                                            }
                                                            .foregroundColor(Theme.tint)
                                                            .frame(maxWidth: .infinity)
                                                            .frame(height: 48)
                                                            .background(Theme.tint.opacity(0.15))
                                                            .cornerRadius(12)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 12)
                                                                    .stroke(Theme.tint.opacity(0.3), lineWidth: 1)
                                                            )
                                                        }
                                                        .padding(.horizontal)
                        }
                        
                        // Categories List
                        VStack(spacing: 16) {
                            // Savings Categories
                            let savingsItems = budgetModel.budgetItems.filter {
                                $0.isActive && $0.type == .savings
                            }
                            categorySection(title: "SAVINGS", items: savingsItems)
                            
                            // Expense Categories
                            let expenseItems = budgetModel.budgetItems.filter {
                                $0.isActive && $0.type == .expense && !isDebtCategory($0.category.id)
                            }
                            categorySection(title: "EXPENSES", items: expenseItems)
                            
                            // Debt Categories
                            let debtItems = budgetModel.budgetItems.filter {
                                $0.isActive && $0.type == .expense && isDebtCategory($0.category.id)
                            }
                            categorySection(title: "DEBT", items: debtItems)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .background(Theme.background)
        // At the end of the VStack, with other .sheet modifiers
        .fullScreenCover(isPresented: $showImprovements) {
            BudgetImprovementModal(isPresented: $showImprovements)
                .environmentObject(budgetModel)
        }
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
            ZStack {
                Color.black
                    .opacity(1)
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Header
                        ZStack {
                            if case .debtConfiguration = selectedDebtPhase {
                                // Back Button
                                HStack {
                                    Button(action: { selectedDebtPhase = .debtSelection }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "chevron.left")
                                            Text("Back")
                                        }
                                        .font(.system(size: 17))
                                        .foregroundColor(Theme.secondaryLabel)
                                    }
                                    Spacer()
                                }
                            }
                            
                            // Title alignment
                            Text(selectedDebtPhase.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                            
                            // Close Button
                            HStack {
                                Spacer()
                                Button(action: {
                                    selectedDebtPhase = .debtSelection
                                    showingDebtSheet = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Description
                        Text(selectedDebtPhase.description)
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                        
                        // Content
                        ScrollView {
                            VStack(spacing: 32) {
                                switch selectedDebtPhase {
                                case .debtSelection:
                                    CategorySelectionView(
                                        categories: availableDebtCategories,
                                        selectedCategories: $selectedCategories,
                                        monthlyIncome: monthlyIncome
                                    )
                                    .padding(.top, 32)
                                    
                                case .debtConfiguration(let category):
                                    DebtConfigurationView(
                                        category: category,
                                        monthlyIncome: monthlyIncome,
                                        inputData: Binding(
                                            get: { debtInputData[category.id] ?? DebtInputData() },
                                            set: { debtInputData[category.id] = $0 }
                                        )
                                    )
                                    .id(category.id)
                                    
                                default:
                                    EmptyView()
                                }
                                
                                Color.clear.frame(height: 100)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Next/Add Button
                        VStack {
                            Spacer()
                            Button(action: {
                                switch selectedDebtPhase {
                                case .debtSelection:
                                    if let nextCategory = selectedCategories.compactMap({ id in
                                        availableDebtCategories.first(where: { $0.id == id })
                                    }).first {
                                        debtInputData[nextCategory.id] = DebtInputData()
                                        selectedDebtPhase = .debtConfiguration(nextCategory)
                                    } else {
                                        showingDebtSheet = false
                                    }
                                    
                                case .debtConfiguration(let category):
                                    if let inputData = debtInputData[category.id],
                                       let amount = inputData.payoffPlan?.monthlyPayment {
                                        // Create the budget item
                                        let newItem = BudgetItem(
                                            id: category.id,
                                            category: category,
                                            allocatedAmount: amount,
                                            spentAmount: 0,
                                            type: .expense,
                                            priority: .important,
                                            isActive: true
                                        )
                                        
                                        // Add to budget model if not already present
                                        if !budgetModel.budgetItems.contains(where: { $0.id == category.id }) {
                                            budgetModel.budgetItems.append(newItem)
                                        }
                                        
                                        // Update BudgetStore
                                        budgetStore.setCategory(category, amount: amount)
                                        selectedCategories.remove(category.id)
                                        
                                        if let nextCategory = selectedCategories.compactMap({ id in
                                            availableDebtCategories.first(where: { $0.id == id })
                                        }).first {
                                            debtInputData.removeAll()
                                            debtInputData[nextCategory.id] = DebtInputData()
                                            selectedDebtPhase = .debtConfiguration(nextCategory)
                                        } else {
                                            budgetModel.calculateUnusedAmount()
                                            selectedDebtPhase = .debtSelection
                                            showingDebtSheet = false
                                        }
                                    }
                                    
                                default:
                                    break
                                }
                            }) {
                                Text(getButtonTitle(for: selectedDebtPhase))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Theme.tint)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 36)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 36)
                        }
                    }
                    .background(Theme.background)
                    .cornerRadius(20)
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingExpenseSheet) {
            ZStack {
                Color.black
                    .opacity(1)
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Header
                        ZStack {
                            if case .expenseConfiguration = selectedExpensePhase {
                                // Back Button
                                HStack {
                                    Button(action: { selectedExpensePhase = .expenseSelection }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "chevron.left")
                                            Text("Back")
                                        }
                                        .font(.system(size: 17))
                                        .foregroundColor(Theme.secondaryLabel)
                                    }
                                    Spacer()
                                }
                            }
                            
                            // Title alignment
                            Text(selectedExpensePhase.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                            
                            // Close Button
                            HStack {
                                Spacer()
                                Button(action: {
                                    selectedExpensePhase = .expenseSelection
                                    showingExpenseSheet = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Description
                        Text(selectedExpensePhase.description)
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                        
                        // Content
                        ScrollView {
                            VStack(spacing: 32) {
                                switch selectedExpensePhase {
                                case .expenseSelection:
                                    CategorySelectionView(
                                        categories: availableExpenseCategories,
                                        selectedCategories: $selectedCategories,
                                        monthlyIncome: monthlyIncome
                                    )
                                    .padding(.top, 32)
                                    
                                case .expenseConfiguration(let category):
                                    ExpenseConfigurationView(
                                        category: category,
                                        monthlyIncome: monthlyIncome,
                                        totalCategories: getTotalConfigurableExpenses(),
                                        currentIndex: getCurrentExpenseIndex(for: category),
                                        amount: binding(for: category)
                                    )
                                    .id(category.id)
                                    
                                default:
                                    EmptyView()
                                }
                                
                                Color.clear.frame(height: 100)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Next/Add Button
                        VStack {
                            Spacer()
                            Button(action: {
                                switch selectedExpensePhase {
                                case .expenseSelection:
                                    if let nextCategory = selectedCategories.compactMap({ id in
                                        expenseCategories.first(where: { $0.id == id })
                                    }).first {
                                        temporaryAmounts[nextCategory.id] = nil
                                        selectedExpensePhase = .expenseConfiguration(nextCategory)
                                    } else {
                                        showingExpenseSheet = false
                                    }
                                    
                                case .expenseConfiguration(let category):
                                    if let amount = temporaryAmounts[category.id] {
                                        // Create the budget item
                                        let newItem = BudgetItem(
                                            id: category.id,
                                            category: category,
                                            allocatedAmount: amount,
                                            spentAmount: 0,
                                            type: .expense,
                                            priority: determinePriority(for: category),
                                            isActive: true
                                        )
                                        
                                        // Add to budget model if not already present
                                        if !budgetModel.budgetItems.contains(where: { $0.id == category.id }) {
                                            budgetModel.budgetItems.append(newItem)
                                        }
                                        
                                        // Update BudgetStore
                                        budgetStore.setCategory(category, amount: amount)
                                        selectedCategories.remove(category.id)
                                        
                                        if let nextCategory = selectedCategories.compactMap({ id in
                                            expenseCategories.first(where: { $0.id == id })
                                        }).first {
                                            temporaryAmounts[nextCategory.id] = nil
                                            selectedExpensePhase = .expenseConfiguration(nextCategory)
                                        } else {
                                            budgetModel.calculateUnusedAmount()
                                            selectedExpensePhase = .expenseSelection
                                            showingExpenseSheet = false
                                        }
                                    }
                                default:
                                    break
                                }
                            }) {
                                Text(getButtonTitle(for: selectedExpensePhase))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Theme.tint)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 36)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 36)
                        }
                    }
                    .background(Theme.background)
                    .cornerRadius(20)
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingSavingsSheet) {
            ZStack {
                Color.black
                    .opacity(1)
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Header
                        ZStack {
                            if case .savingsConfiguration = selectedSavingsPhase {
                                // Back Button
                                HStack {
                                    Button(action: { selectedSavingsPhase = .savingsSelection }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "chevron.left")
                                            Text("Back")
                                        }
                                        .font(.system(size: 17))
                                        .foregroundColor(Theme.secondaryLabel)
                                    }
                                    Spacer()
                                }
                            }
                            
                            // Title alignment
                            Text(selectedSavingsPhase.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                            
                            // Close Button
                            HStack {
                                Spacer()
                                Button(action: {
                                    selectedSavingsPhase = .savingsSelection
                                    showingSavingsSheet = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Description
                        Text(selectedSavingsPhase.description)
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                        
                        // Content
                        ScrollView {
                            VStack(spacing: 32) {
                                switch selectedSavingsPhase {
                                case .savingsSelection:
                                    CategorySelectionView(
                                        categories: availableSavingsCategories,
                                        selectedCategories: $selectedCategories,
                                        monthlyIncome: monthlyIncome
                                    )
                                    .padding(.top, 32)
                                    
                                case .savingsConfiguration(let category):
                                    SavingsConfigurationView(
                                        category: category,
                                        monthlyIncome: monthlyIncome,
                                        amount: binding(for: category)
                                    )
                                    .id(category.id)
                                    
                                default:
                                    EmptyView()
                                }
                                
                                Color.clear.frame(height: 100)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Next/Add Button
                        VStack {
                            Spacer()
                            Button(action: {
                                switch selectedSavingsPhase {
                                case .savingsSelection:
                                    if let nextCategory = selectedCategories.compactMap({ id in
                                        savingsCategories.first(where: { $0.id == id })
                                    }).first {
                                        temporaryAmounts[nextCategory.id] = nil
                                        selectedSavingsPhase = .savingsConfiguration(nextCategory)
                                    } else {
                                        showingSavingsSheet = false
                                    }
                                    
                                case .savingsConfiguration(let category):
                                    if let amount = temporaryAmounts[category.id] {
                                        // Create the budget item
                                        let newItem = BudgetItem(
                                            id: category.id,
                                            category: category,
                                            allocatedAmount: amount,
                                            spentAmount: 0,
                                            type: .savings,
                                            priority: determinePriority(for: category),
                                            isActive: true
                                        )
                                        
                                        // Add to budget model if not already present
                                        if !budgetModel.budgetItems.contains(where: { $0.id == category.id }) {
                                            budgetModel.budgetItems.append(newItem)
                                        }
                                        
                                        // Update BudgetStore
                                        budgetStore.setCategory(category, amount: amount)
                                        selectedCategories.remove(category.id)
                                        
                                        if let nextCategory = selectedCategories.compactMap({ id in
                                            savingsCategories.first(where: { $0.id == id })
                                        }).first {
                                            temporaryAmounts[nextCategory.id] = nil
                                            selectedSavingsPhase = .savingsConfiguration(nextCategory)
                                        } else {
                                            budgetModel.calculateUnusedAmount()
                                            selectedSavingsPhase = .savingsSelection
                                            showingSavingsSheet = false
                                        }
                                    }
                                default:
                                    break
                                }
                            }) {
                                Text(getButtonTitle(for: selectedSavingsPhase))
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Theme.tint)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 36)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 36)
                        }
                    }
                    .background(Theme.background)
                    .cornerRadius(20)
                    .padding()
                }
            }
        }
    }
    
    private func addSelectedCategoriesToBudget() {
        for categoryId in selectedCategories {
            if let category = BudgetCategoryStore.shared.categories.first(where: { $0.id == categoryId }) {
                let recommendedAmount = monthlyIncome * category.allocationPercentage
                
                // Update BudgetStore
                budgetStore.setCategory(category, amount: recommendedAmount)
                
                // Update BudgetModel
                let type: BudgetCategoryType = isSavingsCategory(category.id) ? .savings : .expense
                let priority = determinePriority(for: category)
                
                let newItem = BudgetItem(
                    id: category.id,
                    category: category,
                    allocatedAmount: recommendedAmount,
                    spentAmount: 0,
                    type: type,
                    priority: priority,
                    isActive: true
                )
                
                // Add to budgetItems if not already present
                if !budgetModel.budgetItems.contains(where: { $0.id == category.id }) {
                    budgetModel.budgetItems.append(newItem)
                }
            }
        }
        
        // Recalculate unused amount
        budgetModel.calculateUnusedAmount()
        selectedCategories.removeAll()
    }

    private func determinePriority(for category: BudgetCategory) -> BudgetCategoryPriority {
        switch category.id {
        case "house", "rent", "groceries", "home_utilities", "medical", "emergency_savings":
            return .essential
        case "car", "public_transportation", "investments",
             "credit_cards", "student_loans", "personal_loans", "car_loan":
            return .important
        default:
            return .discretionary
        }
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
        VStack(spacing: 24) {
            // Header section
            VStack(alignment: .leading, spacing: 8) {
                Text("Build Your Budget")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Choose how you want to create your personalized budget")
                    .font(.system(size: 17))
                    .foregroundColor(Theme.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            
            // Inside emptyStateView
            VStack(spacing: 12) {
                // Smart Budget Builder (Recommended)
                Button(action: {
                    // Just generate the smart budget
                    budgetModel.generateSmartBudget()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Build for me")
                                        .font(.system(size: 17, weight: .semibold))
                                    Text("Smart budget based on your income")
                                        .font(.system(size: 15))
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                Text("Recommended")
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(Theme.tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.tint.opacity(0.15))
                            .cornerRadius(6)
                        }
                        .foregroundColor(.white)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                }
                
                // Manual Budget Builder
                Button(action: { showBudgetBuilder = true }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Build on your own")
                                .font(.system(size: 17, weight: .semibold))
                            Text("Create your budget step by step")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                    .foregroundColor(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                }
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
