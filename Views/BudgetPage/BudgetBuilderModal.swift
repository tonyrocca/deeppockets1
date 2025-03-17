import SwiftUI

// MARK: - Budget Builder Phase
enum BudgetBuilderPhase {
    case debtSelection
    case debtConfiguration(BudgetCategory)
    case expenseSelection
    case expenseConfiguration(BudgetCategory)
    case savingsSelection
    case savingsConfiguration(BudgetCategory)
    
    var title: String {
        switch self {
        case .debtSelection: return "Debt"
        case .debtConfiguration: return "Configure Debt"
        case .expenseSelection: return "Monthly Expenses"
        case .expenseConfiguration: return "Configure Expense"
        case .savingsSelection: return "Savings Goals"
        case .savingsConfiguration: return "Configure Savings"
        }
    }
    
    var description: String {
        switch self {
        case .debtSelection: return "Select any recurring debt payments"
        case .debtConfiguration: return "Let's plan your debt payoff strategy"
        case .expenseSelection: return "Choose your regular monthly expenses"
        case .expenseConfiguration: return "Set your monthly budget"
        case .savingsSelection: return "Set up your savings goals"
        case .savingsConfiguration: return "Let's plan how to reach your goal"
        }
    }
}

// MARK: - Debt Input Data
struct DebtInputData {
    var debtAmount: String = ""
    var interestRate: String = ""
    var minimumPayment: String = ""
    var payoffPlan: DebtPayoffPlan?
}

// MARK: - DebtPayoffPlan Structure
struct DebtPayoffPlan {
    let debtAmount: Double
    let interestRate: Double
    let minimumPayment: Double
    let monthlyIncome: Double
    
    var monthlyPayment: Double {
        // Simple calculation for demonstration purposes
        max(minimumPayment, monthlyIncome * 0.1)
    }
    
    var payoffDate: Date {
        let months = calculateMonthsToPayoff()
        return Calendar.current.date(byAdding: .month, value: months, to: Date()) ?? Date()
    }
    
    var totalInterest: Double {
        let months = calculateMonthsToPayoff()
        let totalPayments = monthlyPayment * Double(months)
        return totalPayments - debtAmount
    }
    
    var totalCost: Double {
        debtAmount + totalInterest
    }
    
    private func calculateMonthsToPayoff() -> Int {
        let monthlyRate = interestRate / 100 / 12
        // Avoid division by zero or negative scenarios
        guard monthlyPayment > monthlyRate * debtAmount else { return Int.max }
        
        let numerator = log(monthlyPayment / (monthlyPayment - monthlyRate * debtAmount))
        let denominator = log(1 + monthlyRate)
        
        // If numerator or denominator is invalid, return a large number to represent a lengthy payoff
        if numerator.isNaN || denominator.isNaN || denominator == 0 {
            return 999
        }
        
        return Int(ceil(numerator / denominator))
    }
}

struct BudgetBuilderModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var budgetStore: BudgetStore
    @ObservedObject var budgetModel: BudgetModel
    let monthlyIncome: Double
    
    @State private var phase: BudgetBuilderPhase = .debtSelection
    @State private var selectedCategories: Set<String> = []
    @State private var temporaryAmounts: [String: Double] = [:]
    @State private var debtInputData: [String: DebtInputData] = [:]
    @State private var showBudgetCompletion = false
    @State private var completedBudgetStep: BudgetCompletionStep = .customBudget
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .opacity(1)
                .ignoresSafeArea()
            
            // Modal Content
            GeometryReader { geometry in
                ZStack {
                    // Main content container
                    VStack(spacing: 0) {
                        // Header
                        ZStack {
                            // Back Button - positioned on the left
                            HStack {
                                if !isInitialPhase {
                                    Button(action: navigateBack) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "chevron.left")
                                            Text("Back")
                                        }
                                        .font(.system(size: 17))
                                        .foregroundColor(Theme.secondaryLabel)
                                    }
                                }
                                Spacer()
                            }
                            
                            // Title - Centered
                            Text(phase.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Close Button - positioned on the right
                            HStack {
                                Spacer()
                                Button(action: { isPresented = false }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Theme.secondaryLabel)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Description Text
                        Text(phase.description)
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                        
                        // Content with ScrollView
                        ScrollView {
                            VStack(spacing: 32) {
                                // Phase Content
                                switch phase {
                                case .debtSelection:
                                    selectionView(
                                        categories: debtCategories,
                                        emptyMessage: "No debt categories available"
                                    )
                                    
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
                                    
                                case .expenseSelection:
                                    selectionView(
                                        categories: expenseCategories,
                                        emptyMessage: "No expense categories available"
                                    )
                                    
                                case .expenseConfiguration(let category):
                                    ExpenseConfigurationView(
                                        category: category,
                                        monthlyIncome: monthlyIncome,
                                        totalCategories: getTotalConfigurableExpenses(),
                                        currentIndex: getCurrentExpenseIndex(for: category),
                                        amount: binding(for: category)
                                    )
                                    .id(category.id)
                                    
                                case .savingsSelection:
                                    selectionView(
                                        categories: savingsCategories,
                                        emptyMessage: "No savings categories available"
                                    )
                                    
                                case .savingsConfiguration(let category):
                                    SavingsConfigurationView(
                                        category: category,
                                        monthlyIncome: monthlyIncome,
                                        amount: binding(for: category)
                                    )
                                    .id(category.id)
                                }
                                
                                // Add extra space at bottom to ensure content scrolls above button
                                Color.clear
                                    .frame(height: 100)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Spacer to push everything up
                        Spacer()
                    }
                    
                    // Fixed Bottom Bar with Next Button
                    VStack {
                        Spacer()
                        ZStack {
                            // Background for bottom bar
                            Rectangle()
                                .fill(Theme.background)
                                .frame(height: 100)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, y: -3)
                                
                            // Next Button
                            Button(action: handleNext) {
                                HStack {
                                    Image(systemName: getButtonIcon())
                                        .font(.system(size: 18))
                                    Text(nextButtonTitle)
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Theme.tint)
                                .cornerRadius(12)
                            }
                            .disabled(!canProgress)
                            .opacity(canProgress ? 1 : 0.6)
                            .shadow(color: Theme.tint.opacity(0.3), radius: 8, x: 0, y: 4)
                            .padding(.horizontal, 36)
                        }
                        .frame(height: 100)
                        .padding(.bottom, geometry.safeAreaInsets.bottom)
                    }
                    .ignoresSafeArea(.all, edges: .bottom)
                }
                .background(Theme.background)
                .cornerRadius(20)
                .padding()
            }
        }
        .fullScreenCover(isPresented: $showBudgetCompletion) {
            BudgetCompletionFlow(
                isPresented: $showBudgetCompletion,
                monthlyIncome: monthlyIncome,
                completedStep: completedBudgetStep
            )
        }
    }
    
    // MARK: - Selection View
    @ViewBuilder
    private func selectionView(categories: [BudgetCategory], emptyMessage: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if categories.isEmpty {
                Text(emptyMessage)
                    .font(.system(size: 17))
                    .foregroundColor(Theme.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                CategorySelectionView(
                    categories: categories,
                    selectedCategories: $selectedCategories,
                    monthlyIncome: monthlyIncome
                )
            }
        }
    }
    
    // MARK: - Button Logic
    private var nextButtonTitle: String {
        switch phase {
        case .debtSelection, .expenseSelection, .savingsSelection:
            return selectedCategories.isEmpty ? "Skip" : "Next"
        case .debtConfiguration, .expenseConfiguration, .savingsConfiguration:
            return "Continue"
        }
    }
    
    private func getButtonIcon() -> String {
        switch phase {
        case .debtSelection, .expenseSelection, .savingsSelection:
            return "arrow.right"
        case .debtConfiguration, .expenseConfiguration, .savingsConfiguration:
            return "checkmark"
        }
    }
    
    private var canProgress: Bool {
        switch phase {
        case .debtSelection, .expenseSelection, .savingsSelection:
            return true
        case .debtConfiguration(let category):
            return debtInputData[category.id]?.payoffPlan != nil
                || debtInputData[category.id]?.debtAmount != ""
        case .expenseConfiguration(let category),
             .savingsConfiguration(let category):
            return temporaryAmounts[category.id] != nil
        }
    }
    
    private var isInitialPhase: Bool {
        switch phase {
        case .debtSelection:
            return true
        default:
            return false
        }
    }
    
    private func navigateBack() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch phase {
            case .debtConfiguration:
                phase = .debtSelection
            case .expenseConfiguration:
                phase = .expenseSelection
            case .savingsConfiguration:
                phase = .savingsSelection
            default:
                break
            }
        }
    }
    
    private func handleNext() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch phase {
            case .debtSelection:
                if let nextCategory = selectedCategories.compactMap({ id in
                    debtCategories.first(where: { $0.id == id })
                }).first {
                    // Initialize new DebtInputData for this category
                    debtInputData[nextCategory.id] = DebtInputData()
                    temporaryAmounts[nextCategory.id] = nil
                    phase = .debtConfiguration(nextCategory)
                } else {
                    phase = .expenseSelection
                }
                
            case .debtConfiguration(let category):
                if let inputData = debtInputData[category.id],
                   let amount = inputData.payoffPlan?.monthlyPayment {
                    budgetStore.setCategory(category, amount: amount)
                    budgetModel.toggleCategory(id: category.id)
                    budgetModel.updateAllocation(for: category.id, amount: amount)
                    selectedCategories.remove(category.id)
                    
                    // Show completion screen for debt category
                    completedBudgetStep = .debtCategory
                    showBudgetCompletion = true
                    
                    if let nextCategory = selectedCategories.compactMap({ id in
                        debtCategories.first(where: { $0.id == id })
                    }).first {
                        // Clear and reset for next category
                        debtInputData.removeAll()
                        debtInputData[nextCategory.id] = DebtInputData()
                        temporaryAmounts.removeAll()
                        phase = .debtConfiguration(nextCategory)
                    } else {
                        phase = .expenseSelection
                    }
                }
                
            case .expenseSelection:
                if let nextCategory = selectedCategories.compactMap({ id in
                    expenseCategories.first(where: { $0.id == id })
                }).first {
                    temporaryAmounts[nextCategory.id] = nil
                    phase = .expenseConfiguration(nextCategory)
                } else {
                    phase = .savingsSelection
                }
                
            case .expenseConfiguration(let category):
                if let amount = temporaryAmounts[category.id] {
                    budgetStore.setCategory(category, amount: amount)
                    budgetModel.toggleCategory(id: category.id)
                    budgetModel.updateAllocation(for: category.id, amount: amount)
                    selectedCategories.remove(category.id)
                    
                    // Show completion screen for expense category
                    completedBudgetStep = .expenseCategory
                    showBudgetCompletion = true
                    
                    if let nextCategory = selectedCategories.compactMap({ id in
                        expenseCategories.first(where: { $0.id == id })
                    }).first {
                        temporaryAmounts[nextCategory.id] = nil
                        phase = .expenseConfiguration(nextCategory)
                    } else {
                        budgetModel.calculateUnusedAmount()
                        phase = .savingsSelection
                    }
                }
                    
            case .savingsSelection:
                if let nextCategory = selectedCategories.compactMap({ id in
                    savingsCategories.first(where: { $0.id == id })
                }).first {
                    temporaryAmounts[nextCategory.id] = nil
                    phase = .savingsConfiguration(nextCategory)
                } else {
                    // Show completion screen for full custom budget
                    completedBudgetStep = .customBudget
                    showBudgetCompletion = true
                    isPresented = false
                }
                
            case .savingsConfiguration(let category):
                if let amount = temporaryAmounts[category.id] {
                    budgetStore.setCategory(category, amount: amount)
                    budgetModel.toggleCategory(id: category.id)
                    budgetModel.updateAllocation(for: category.id, amount: amount)
                    selectedCategories.remove(category.id)
                    
                    // Show completion screen for savings category
                    completedBudgetStep = .savingsCategory
                    showBudgetCompletion = true
                    
                    if let nextCategory = selectedCategories.compactMap({ id in
                        savingsCategories.first(where: { $0.id == id })
                    }).first {
                        temporaryAmounts[nextCategory.id] = nil
                        phase = .savingsConfiguration(nextCategory)
                    } else {
                        budgetModel.setupInitialBudget(selectedCategoryIds: selectedCategories)
                        isPresented = false
                    }
                }
            }
        }
    }
    
    // MARK: - Category Filters and Helpers
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
    
    private func isDebtCategory(_ id: String) -> Bool {
        ["credit_cards", "student_loans", "personal_loans", "car_loan"].contains(id)
    }
    
    private func isSavingsCategory(_ id: String) -> Bool {
        ["emergency_savings", "investments", "college_savings", "vacation"].contains(id)
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
}

// MARK: - CategorySelectionView with Toggles
struct CategorySelectionView: View {
    let categories: [BudgetCategory]
    @Binding var selectedCategories: Set<String>
    let monthlyIncome: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(categories) { category in
                CategoryToggleRow(
                    category: category,
                    isSelected: selectedCategories.contains(category.id),
                    onToggle: { toggleCategory(category) }
                )
            }
        }
    }
    
    private func toggleCategory(_ category: BudgetCategory) {
        if selectedCategories.contains(category.id) {
            selectedCategories.remove(category.id)
        } else {
            selectedCategories.insert(category.id)
        }
    }
}

// MARK: - CategoryToggleRow
struct CategoryToggleRow: View {
    let category: BudgetCategory
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            // Category Info
            HStack(spacing: 12) {
                Text(category.emoji)
                    .font(.title2)
                
                Text(category.name)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Toggle Component
            Toggle("", isOn: Binding<Bool>(
                get: { isSelected },
                set: { _ in onToggle() }
            ))
            .toggleStyle(SwitchToggleStyle(tint: Theme.tint))
            .labelsHidden()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.surfaceBackground)
                .overlay(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.tint.opacity(0.5), lineWidth: 1.5)
                        }
                    }
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - DebtConfigurationView with Fixed Binding Issues
struct DebtConfigurationView: View {
    let category: BudgetCategory
    let monthlyIncome: Double
    @Binding var inputData: DebtInputData
    @State private var inputMode: DebtInputMode? = nil
    
    init(category: BudgetCategory, monthlyIncome: Double, inputData: Binding<DebtInputData>) {
        self.category = category
        self.monthlyIncome = monthlyIncome
        self._inputData = inputData
        self._inputMode = State(initialValue: nil)
    }
    
    enum DebtInputMode {
        case recommended
        case custom
    }
    
    private var recommendedAmount: Double {
        monthlyIncome * category.allocationPercentage
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack(spacing: 8) {
                Text(category.emoji)
                    .font(.title)
                Text(category.name)
                    .font(.title)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Options Section
            VStack(spacing: 16) {
                // Recommended Amount Toggle Option
                DebtOptionToggleRow(
                    title: "\(formatCurrency(recommendedAmount))/month",
                    subtitle: "(\(Int(category.allocationPercentage * 100))% of income)",
                    isSelected: inputMode == .recommended,
                    onToggle: { selectMode(.recommended) }
                )
                
                // Custom Payment Section
                VStack(spacing: 0) {
                    DebtOptionToggleRow(
                        title: "Custom debt setup",
                        subtitle: nil,
                        isSelected: inputMode == .custom,
                        onToggle: { selectMode(.custom) }
                    )
                    
                    if inputMode == .custom {
                        VStack(spacing: 16) {
                            // Debt Amount Input
                            InputField(
                                title: "Total Debt Amount",
                                text: $inputData.debtAmount,
                                placeholder: "Enter amount",
                                prefix: "",
                                suffix: "",
                                onChange: { calculatePayoffPlan() }
                            )
                            
                            // Interest Rate Input
                            InputField(
                                title: "Interest Rate",
                                text: $inputData.interestRate,
                                placeholder: "Enter rate",
                                prefix: "",
                                suffix: "%",
                                onChange: { calculatePayoffPlan() }
                            )
                            
                            // Minimum Payment Input
                            InputField(
                                title: "Minimum Payment",
                                text: $inputData.minimumPayment,
                                placeholder: "Enter amount",
                                prefix: "$",
                                suffix: "",
                                onChange: { calculatePayoffPlan() }
                            )
                        }
                        .padding()
                    }
                }
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
                
                // Payoff Plan Summary (if applicable)
                if let plan = inputData.payoffPlan {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payoff Plan Summary")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        payoffSummaryRow("Monthly Payment", formatCurrency(plan.monthlyPayment))
                        payoffSummaryRow("Total Interest", formatCurrency(plan.totalInterest))
                        payoffSummaryRow("Total Cost", formatCurrency(plan.totalCost))
                        payoffSummaryRow("Payoff Date", formatDate(plan.payoffDate))
                    }
                    .padding()
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
            
            Text("Almost done! One final review after this.")
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
        }
        .onAppear {
            // Initialize with empty values on appear
            inputMode = nil
            inputData.debtAmount = ""
            inputData.interestRate = ""
            inputData.minimumPayment = ""
            inputData.payoffPlan = nil
        }
    }
    
    private func payoffSummaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
    }
    
    private func selectMode(_ mode: DebtInputMode) {
        withAnimation {
            inputMode = mode
            if mode == .recommended {
                // For recommended mode, create a DebtPayoffPlan with the recommended amount
                let recommendedValue = recommendedAmount
                inputData.debtAmount = "\(recommendedValue)"
                inputData.payoffPlan = DebtPayoffPlan(
                    debtAmount: recommendedValue,
                    interestRate: 0,
                    minimumPayment: recommendedValue,
                    monthlyIncome: monthlyIncome
                )
            } else {
                // For custom mode, reset values
                inputData.debtAmount = ""
                inputData.interestRate = ""
                inputData.minimumPayment = ""
                inputData.payoffPlan = nil
            }
        }
    }
    
    private func calculatePayoffPlan() {
        // Only calculate if all fields have valid values
        guard let debt = Double(inputData.debtAmount),
              let rate = Double(inputData.interestRate),
              let minPayment = Double(inputData.minimumPayment),
              debt > 0, minPayment > 0
        else {
            // If any fields are invalid, clear the plan
            inputData.payoffPlan = nil
            return
        }
        
        // Create a new payoff plan with the user-provided values
        inputData.payoffPlan = DebtPayoffPlan(
            debtAmount: debt,
            interestRate: rate,
            minimumPayment: minPayment,
            monthlyIncome: monthlyIncome
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - ExpenseConfigurationView with Toggles
struct ExpenseConfigurationView: View {
    let category: BudgetCategory
    let monthlyIncome: Double
    let totalCategories: Int
    let currentIndex: Int
    @Binding var amount: Double?
    @State private var inputMode: ExpenseInputMode? = nil
    @State private var customAmount: String = ""
    
    init(category: BudgetCategory, monthlyIncome: Double, totalCategories: Int, currentIndex: Int, amount: Binding<Double?>) {
        self.category = category
        self.monthlyIncome = monthlyIncome
        self.totalCategories = totalCategories
        self.currentIndex = currentIndex
        self._amount = amount
        self._inputMode = State(initialValue: nil)
        self._customAmount = State(initialValue: "")
    }
    
    enum ExpenseInputMode {
        case recommended
        case custom
    }
    
    private var recommendedAmount: Double {
        monthlyIncome * category.allocationPercentage
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Category Header
            HStack(spacing: 8) {
                Text(category.emoji)
                    .font(.title)
                Text(category.name)
                    .font(.title)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Options Section
            VStack(spacing: 16) {
                // Recommended Amount Toggle Option
                OptionToggleRow(
                    title: "\(formatCurrency(recommendedAmount))/month",
                    subtitle: "(\(Int(category.allocationPercentage * 100))% of income)",
                    isSelected: inputMode == .recommended,
                    onToggle: { selectMode(.recommended) }
                )
                
                // Custom Amount Option
                VStack(spacing: 0) {
                    OptionToggleRow(
                        title: "Custom amount",
                        subtitle: nil,
                        isSelected: inputMode == .custom,
                        onToggle: { selectMode(.custom) }
                    )
                    
                    if inputMode == .custom {
                        VStack(spacing: 12) {
                            HStack {
                                Text("$")
                                    .foregroundColor(.white)
                                TextField("", text: $customAmount)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                                    .placeholder(when: customAmount.isEmpty) {
                                        Text("Enter amount")
                                            .foregroundColor(Theme.secondaryLabel)
                                    }
                                    .onChange(of: customAmount) { newValue in
                                        if let value = Double(newValue) {
                                            amount = value
                                        } else {
                                            amount = nil
                                        }
                                    }
                                Text("/month")
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                            .padding()
                            .background(Theme.elevatedBackground)
                            .cornerRadius(8)
                            
                            if let customValue = Double(customAmount) {
                                let difference = customValue - recommendedAmount
                                let percentDifference = (difference / recommendedAmount) * 100
                                
                                HStack {
                                    Image(systemName: difference >= 0 ? "arrow.up-right" : "arrow.down-right")
                                    Text("\(String(format: "%.1f", abs(percentDifference)))% \(difference >= 0 ? "above" : "below") recommended")
                                        .font(.system(size: 13))
                                        .foregroundColor(difference >= 0 ? .red : Theme.tint)
                                }
                                .padding(.horizontal)
                                .padding(.bottom)
                            }
                        }
                        .padding()
                    }
                }
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("Almost done! One final review after this.")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            inputMode = nil
            customAmount = ""
            amount = nil
        }
    }
    
    private func selectMode(_ mode: ExpenseInputMode) {
        withAnimation {
            if inputMode != mode {
                inputMode = mode
                customAmount = ""
                amount = mode == .recommended ? recommendedAmount : nil
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

struct SavingsConfigurationView: View {
    let category: BudgetCategory
    let monthlyIncome: Double
    @Binding var amount: Double?
    @State private var inputMode: SavingsInputMode? = nil
    @State private var targetAmount: String = ""
    @State private var targetDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
    
    init(category: BudgetCategory, monthlyIncome: Double, amount: Binding<Double?>) {
        self.category = category
        self.monthlyIncome = monthlyIncome
        self._amount = amount
        self._inputMode = State(initialValue: nil)
        self._targetAmount = State(initialValue: "")
    }
    
    enum SavingsInputMode {
        case recommended
        case custom
    }
    
    private var recommendedAmount: Double {
        monthlyIncome * category.allocationPercentage
    }
    
    private var monthsToGoal: Int {
        Calendar.current.dateComponents([.month], from: Date(), to: targetDate).month ?? 12
    }
    
    private var requiredMonthlySavings: Double? {
        guard let target = Double(targetAmount) else { return nil }
        return target / Double(max(1, monthsToGoal))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header - simplified to just emoji and name
            HStack(spacing: 8) {
                Text(category.emoji)
                    .font(.title)
                Text(category.name)
                    .font(.title)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Options Section
            VStack(spacing: 16) {
                // Recommended Amount Toggle Option
                OptionToggleRow(
                    title: "\(formatCurrency(recommendedAmount))/month",
                    subtitle: "(\(Int(category.allocationPercentage * 100))% of income)",
                    isSelected: inputMode == .recommended,
                    onToggle: { selectMode(.recommended) }
                )
                
                // Custom Goal Section
                VStack(spacing: 0) {
                    OptionToggleRow(
                        title: "Set savings goal",
                        subtitle: nil,
                        isSelected: inputMode == .custom,
                        onToggle: { selectMode(.custom) }
                    )
                    
                    if inputMode == .custom {
                        VStack(spacing: 16) {
                            // Goal toggle
                            Toggle("Set savings goal", isOn: .constant(true))
                                .tint(Theme.tint)
                                .padding(.horizontal)
                                .padding(.top, 12)
                            
                            // Target Amount
                            HStack {
                                Text("$")
                                    .foregroundColor(.white)
                                TextField("", text: $targetAmount)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                                    .placeholder(when: targetAmount.isEmpty) {
                                        Text("Enter goal amount")
                                            .foregroundColor(Theme.secondaryLabel)
                                    }
                                    .onChange(of: targetAmount) { _ in
                                        updateCalculation()
                                    }
                                Text("total goal")
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                            .padding()
                            .background(Theme.elevatedBackground)
                            .cornerRadius(8)
                            .padding(.horizontal)
                            
                            // Target Date
                            HStack {
                                Text("By")
                                    .foregroundColor(.white)
                                Spacer()
                                DatePicker("", selection: $targetDate,
                                          in: Date()...,
                                          displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .colorScheme(.dark)
                                    .onChange(of: targetDate) { _ in
                                        updateCalculation()
                                    }
                            }
                            .padding()
                            .background(Theme.elevatedBackground)
                            .cornerRadius(8)
                            .padding(.horizontal)
                            
                            // Required Monthly Savings
                            if let monthlySavings = requiredMonthlySavings {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Required monthly savings:")
                                            .foregroundColor(Theme.secondaryLabel)
                                        Spacer()
                                        Text(formatCurrency(monthlySavings))
                                            .foregroundColor(.white)
                                    }
                                    
                                    let difference = monthlySavings - recommendedAmount
                                    let percentDifference = (difference / recommendedAmount) * 100
                                    
                                    HStack {
                                        Image(systemName: difference >= 0 ? "arrow.up.right" : "arrow.down.right")
                                        Text("\(String(format: "%.1f", abs(percentDifference)))% \(difference >= 0 ? "above" : "below") recommended")
                                            .font(.system(size: 13))
                                            .foregroundColor(difference >= 0 ? .red : Theme.tint)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom)
                            }
                        }
                    }
                }
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
            }
            
            Spacer()
        }
        .onAppear {
            // Initialize with recommended value by default
            selectMode(.recommended)
        }
    }
    
    private func selectMode(_ mode: SavingsInputMode) {
        withAnimation {
            if inputMode != mode {
                inputMode = mode
                targetAmount = ""
                amount = mode == .recommended ? recommendedAmount : nil
            }
        }
    }
    
    private func updateCalculation() {
        if let savings = requiredMonthlySavings {
            amount = savings
        } else {
            amount = nil
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct OptionToggleRow: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding<Bool>(
                    get: { isSelected },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: Theme.tint))
                .labelsHidden()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.surfaceBackground)
                    .overlay(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.tint.opacity(0.5), lineWidth: 1.5)
                            }
                        }
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// Debt Option Toggle Row (Circular Toggle)
struct DebtOptionToggleRow: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Circle()
                    .stroke(Theme.secondaryLabel, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if isSelected {
                            Circle()
                                .fill(Theme.tint)
                                .frame(width: 16, height: 16)
                        }
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.surfaceBackground)
                    .overlay(
                        Group {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Theme.tint.opacity(0.5), lineWidth: 1.5)
                            }
                        }
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Input Field Component
struct InputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let prefix: String
    let suffix: String
    let onChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
            
            HStack {
                if !prefix.isEmpty {
                    Text(prefix)
                        .foregroundColor(.white)
                }
                
                TextField("", text: $text)
                    .keyboardType(.decimalPad)
                    .foregroundColor(.white)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(Theme.secondaryLabel)
                    }
                    .onChange(of: text) { _ in
                        onChange()
                    }
                
                if !suffix.isEmpty {
                    Text(suffix)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Theme.elevatedBackground)
            .cornerRadius(8)
        }
    }
}

