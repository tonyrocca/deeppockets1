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

struct BudgetBuilderModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var budgetStore: BudgetStore
    let monthlyIncome: Double
    
    @State private var phase: BudgetBuilderPhase = .debtSelection
    @State private var selectedCategories: Set<String> = []
    @State private var temporaryAmounts: [String: Double] = [:]
    @State private var debtInputData: [String: DebtInputData] = [:]
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.75)
                .ignoresSafeArea()
            
            // Modal Content
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header
                    ZStack {
                        // Back Button
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
                        
                        // Close Button
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
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 32) {
                            // Title Section
                            VStack(spacing: 8) {
                                Text(phase.title)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Text(phase.description)
                                    .font(.system(size: 17))
                                    .foregroundColor(Theme.secondaryLabel)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Phase Content
                            AnyView(
                                VStack {
                                    switch phase {
                                    case .debtSelection:
                                        CategorySelectionView(
                                            categories: debtCategories,
                                            selectedCategories: $selectedCategories,
                                            monthlyIncome: monthlyIncome
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
                                        
                                    case .expenseSelection:
                                        CategorySelectionView(
                                            categories: expenseCategories,
                                            selectedCategories: $selectedCategories,
                                            monthlyIncome: monthlyIncome
                                        )
                                        
                                    case .expenseConfiguration(let category):
                                        ExpenseConfigurationView(
                                            category: category,
                                            monthlyIncome: monthlyIncome,
                                            totalCategories: getTotalConfigurableExpenses(),
                                            currentIndex: getCurrentExpenseIndex(for: category),
                                            amount: binding(for: category)
                                        )
                                        
                                    case .savingsSelection:
                                        CategorySelectionView(
                                            categories: savingsCategories,
                                            selectedCategories: $selectedCategories,
                                            monthlyIncome: monthlyIncome
                                        )
                                        
                                    case .savingsConfiguration(let category):
                                        SavingsConfigurationView(
                                            category: category,
                                            monthlyIncome: monthlyIncome,
                                            amount: binding(for: category)
                                        )
                                    }
                                }
                            )
                            
                            // Spacer to ensure content scrolls above button
                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .background(Theme.background)
                .cornerRadius(20)
                .padding()
                
                // Floating Next Button
                VStack {
                    Spacer()
                    nextButton
                        .padding(.horizontal, 36)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 36)
                }
                .ignoresSafeArea()
            }
        }
    }
    
    private var nextButton: some View {
        Button(action: handleNext) {
            Text(nextButtonTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.tint)
                .cornerRadius(12)
        }
        .disabled(!canProgress)
        .opacity(canProgress ? 1 : 0.6)
        .shadow(color: Theme.tint.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var nextButtonTitle: String {
        switch phase {
        case .debtSelection, .expenseSelection, .savingsSelection:
            return selectedCategories.isEmpty ? "Skip" : "Next"
        case .debtConfiguration, .expenseConfiguration, .savingsConfiguration:
            return "Continue"
        }
    }
    
    private var canProgress: Bool {
        switch phase {
        case .debtSelection, .expenseSelection, .savingsSelection:
            return true // Can always skip
        case .debtConfiguration(let category):
            // We only enable the button if there's a valid payoff plan
            if let inputData = debtInputData[category.id],
               let _ = inputData.payoffPlan {
                return true
            }
            return false
        case .expenseConfiguration(let category),
             .savingsConfiguration(let category):
            return temporaryAmounts[category.id] != nil
        }
    }
    
    private var isInitialPhase: Bool {
        switch phase {
        case .debtSelection: return true
        default: return false
        }
    }
    
    private func binding(for category: BudgetCategory) -> Binding<Double?> {
        Binding(
            get: { temporaryAmounts[category.id] },
            set: { temporaryAmounts[category.id] = $0 }
        )
    }
    
    private func navigateBack() {
        switch phase {
        case .debtConfiguration: phase = .debtSelection
        case .expenseConfiguration: phase = .expenseSelection
        case .savingsConfiguration: phase = .savingsSelection
        default: break
        }
    }
    
    private func handleNext() {
        switch phase {
        case .debtSelection:
            if let nextCategory = selectedCategories.compactMap({ id in
                debtCategories.first(where: { $0.id == id })
            }).first {
                // Initialize DebtInputData for the first selected debt
                debtInputData[nextCategory.id] = DebtInputData()
                phase = .debtConfiguration(nextCategory)
            } else {
                phase = .expenseSelection
            }
            
        case .debtConfiguration(let category):
            // Pull the payoff plan from the stored input data
            if let inputData = debtInputData[category.id],
               let amount = inputData.payoffPlan?.monthlyPayment {
                budgetStore.setCategory(category, amount: amount)
                selectedCategories.remove(category.id)
                
                if let nextCategory = selectedCategories.compactMap({ id in
                    debtCategories.first(where: { $0.id == id })
                }).first {
                    debtInputData[nextCategory.id] = DebtInputData()
                    phase = .debtConfiguration(nextCategory)
                } else {
                    phase = .expenseSelection
                }
            }
            
        case .expenseSelection:
            if let nextCategory = selectedCategories.compactMap({ id in
                expenseCategories.first(where: { $0.id == id })
            }).first {
                phase = .expenseConfiguration(nextCategory)
            } else {
                phase = .savingsSelection
            }
            
        case .expenseConfiguration(let category):
            if let amount = temporaryAmounts[category.id] {
                budgetStore.setCategory(category, amount: amount)
                selectedCategories.remove(category.id)
                
                if let nextCategory = selectedCategories.compactMap({ id in
                    expenseCategories.first(where: { $0.id == id })
                }).first {
                    phase = .expenseConfiguration(nextCategory)
                } else {
                    phase = .savingsSelection
                }
            }
            
        case .savingsSelection:
            if let nextCategory = selectedCategories.compactMap({ id in
                savingsCategories.first(where: { $0.id == id })
            }).first {
                phase = .savingsConfiguration(nextCategory)
            } else {
                isPresented = false
            }
            
        case .savingsConfiguration(let category):
            if let amount = temporaryAmounts[category.id] {
                budgetStore.setCategory(category, amount: amount)
                selectedCategories.remove(category.id)
                
                if let nextCategory = selectedCategories.compactMap({ id in
                    savingsCategories.first(where: { $0.id == id })
                }).first {
                    phase = .savingsConfiguration(nextCategory)
                } else {
                    isPresented = false
                }
            }
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
    
    private func isDebtCategory(_ id: String) -> Bool {
        ["credit_cards", "student_loans", "personal_loans", "car_loan"].contains(id)
    }
    
    private func isSavingsCategory(_ id: String) -> Bool {
        ["emergency_savings", "investments", "college_savings", "vacation"].contains(id)
    }
    
    private func getTotalConfigurableExpenses() -> Int {
        return selectedCategories.filter { id in
            expenseCategories.contains(where: { $0.id == id })
        }.count
    }

    private func getCurrentExpenseIndex(for category: BudgetCategory) -> Int {
        let selectedExpenseIds = selectedCategories.filter { id in
            expenseCategories.contains(where: { $0.id == id })
        }.sorted() // Sort to maintain consistent order
        
        if let index = selectedExpenseIds.firstIndex(of: category.id) {
            return index
        }
        return 0
    }
}

// A container for user input in the debt configuration phase
struct DebtInputData {
    var debtAmount: String = ""
    var interestRate: String = ""
    var minimumPayment: String = ""
    var payoffPlan: DebtPayoffPlan?
}

// MARK: - Category Selection View
struct CategorySelectionView: View {
    let categories: [BudgetCategory]
    @Binding var selectedCategories: Set<String>
    let monthlyIncome: Double
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(categories) { category in
                Button(action: { toggleCategory(category) }) {
                    HStack {
                        Text(category.emoji)
                            .font(.title2)
                        
                        Text(category.name)
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: selectedCategories.contains(category.id) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(selectedCategories.contains(category.id) ? Theme.tint : Theme.secondaryLabel)
                    }
                    .padding()
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                }
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
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Configuration Views
struct DebtConfigurationView: View {
    let category: BudgetCategory
    let monthlyIncome: Double
    @Binding var inputData: DebtInputData
    
    var body: some View {
        VStack(spacing: 24) {
            // Selected Category Header
            HStack(alignment: .center, spacing: 12) {
                Text(category.emoji)
                    .font(.system(size: 28))
                Text(category.name)
                    .font(.title)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Debt Amount Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Total \(category.name) Debt")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                
                HStack {
                    Text("$")
                        .foregroundColor(.white)
                    TextField("", text: $inputData.debtAmount)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .placeholder(when: inputData.debtAmount.isEmpty) {
                            Text("0")
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        .onChange(of: inputData.debtAmount) { _ in
                            calculatePayoffPlan()
                        }
                }
                .padding()
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
            }
            
            // Interest Rate Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Interest Rate (%)")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                
                HStack {
                    TextField("", text: $inputData.interestRate)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .placeholder(when: inputData.interestRate.isEmpty) {
                            Text("0.0")
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        .onChange(of: inputData.interestRate) { _ in
                            calculatePayoffPlan()
                        }
                    Text("%")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
            }
            
            // Minimum Payment Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Monthly Minimum Payment")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                
                HStack {
                    Text("$")
                        .foregroundColor(.white)
                    TextField("", text: $inputData.minimumPayment)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .placeholder(when: inputData.minimumPayment.isEmpty) {
                            Text("0")
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        .onChange(of: inputData.minimumPayment) { _ in
                            calculatePayoffPlan()
                        }
                }
                .padding()
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
            }
            
            // Payoff Plan Summary
            if let plan = inputData.payoffPlan {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Payoff Plan Summary")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Monthly Payment")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.secondaryLabel)
                            Text(formatCurrency(plan.monthlyPayment))
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Payoff Date")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.secondaryLabel)
                            Text(formatDate(plan.payoffDate))
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Interest")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.secondaryLabel)
                            Text(formatCurrency(plan.totalInterest))
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Cost")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.secondaryLabel)
                            Text(formatCurrency(plan.totalCost))
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
            }
        }
    }
    
    private func calculatePayoffPlan() {
        guard
            let debt = Double(inputData.debtAmount),
            let rate = Double(inputData.interestRate),
            let minPayment = Double(inputData.minimumPayment)
        else {
            inputData.payoffPlan = nil
            return
        }
        
        let plan = DebtPayoffPlan(
            debtAmount: debt,
            interestRate: rate,
            minimumPayment: minPayment,
            monthlyIncome: monthlyIncome
        )
        
        inputData.payoffPlan = plan
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

struct ExpenseConfigurationView: View {
    let category: BudgetCategory
    let monthlyIncome: Double
    let totalCategories: Int
    let currentIndex: Int
    @Binding var amount: Double?
    @State private var inputMode: ExpenseInputMode = .recommended
    @State private var customAmount: String = ""
    
    enum ExpenseInputMode {
        case recommended
        case custom
    }
    
    private var recommendedAmount: Double {
        monthlyIncome * category.allocationPercentage
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Title Section
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(category.emoji)
                        .font(.title)
                    Text(category.name)
                        .font(.title)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Options Section
            VStack(spacing: 16) {
                // Recommended Amount Option
                Button(action: { selectMode(.recommended) }) {
                    HStack(spacing: 12) {
                        Circle()
                            .stroke(Theme.secondaryLabel, lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .overlay {
                                if inputMode == .recommended {
                                    Circle()
                                        .fill(Theme.tint)
                                        .frame(width: 16, height: 16)
                                }
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(formatCurrency(recommendedAmount))/month")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            
                            Text("(\(Int(category.allocationPercentage * 100))% of income)")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                }
                
                // Custom Amount Section
                VStack(spacing: 0) {
                    Button(action: { selectMode(.custom) }) {
                        HStack(spacing: 12) {
                            Circle()
                                .stroke(Theme.secondaryLabel, lineWidth: 2)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    if inputMode == .custom {
                                        Circle()
                                            .fill(Theme.tint)
                                            .frame(width: 16, height: 16)
                                    }
                                }
                            
                            Text("Custom amount")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    
                    if inputMode == .custom {
                        VStack(spacing: 12) {
                            HStack {
                                Text("$")
                                    .foregroundColor(.white)
                                TextField("", text: $customAmount)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                                    .placeholder(when: customAmount.isEmpty) {
                                        Text("e.g. 2000")
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
                            
                            if let customValue = Double(customAmount) {
                                let difference = customValue - recommendedAmount
                                let percentDifference = (difference / recommendedAmount) * 100
                                
                                HStack {
                                    Image(systemName: difference >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    Text("\(String(format: "%.1f", abs(percentDifference)))% \(difference >= 0 ? "above" : "below") recommended")
                                        .font(.system(size: 13))
                                        .foregroundColor(difference >= 0 ? .red : Theme.tint)
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
            
            // Navigation Hint
            if currentIndex < totalCategories - 1 {
                Text("Continue to set up your next expense")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.secondaryLabel)
            } else {
                Text("Almost done! One final review after this.")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.secondaryLabel)
            }
        }
    }
    
    private func selectMode(_ mode: ExpenseInputMode) {
        withAnimation {
            inputMode = mode
            if mode == .recommended {
                customAmount = ""
                amount = recommendedAmount
            } else {
                customAmount = ""
                amount = nil
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
    @State private var inputMode: SavingsInputMode = .recommended
    @State private var targetAmount: String = ""
    @State private var targetDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
    
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
                // Recommended Amount Option
                Button(action: { selectMode(.recommended) }) {
                    HStack(spacing: 12) {
                        Circle()
                            .stroke(Theme.secondaryLabel, lineWidth: 2)
                            .frame(width: 24, height: 24)
                            .overlay {
                                if inputMode == .recommended {
                                    Circle()
                                        .fill(Theme.tint)
                                        .frame(width: 16, height: 16)
                                }
                            }
                        
                        Text("\(formatCurrency(recommendedAmount))/month")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        
                        Text("(\(Int(category.allocationPercentage * 100))% of income)")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                }
                
                // Custom Goal Section
                VStack(spacing: 0) {
                    Button(action: { selectMode(.custom) }) {
                        HStack(spacing: 12) {
                            Circle()
                                .stroke(Theme.secondaryLabel, lineWidth: 2)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    if inputMode == .custom {
                                        Circle()
                                            .fill(Theme.tint)
                                            .frame(width: 16, height: 16)
                                    }
                                }
                            
                            Text("Set savings goal")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding()
                    }
                    
                    if inputMode == .custom {
                        VStack(spacing: 16) {
                            // Target Amount
                            HStack {
                                Text("$")
                                    .foregroundColor(.white)
                                TextField("", text: $targetAmount)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                                    .placeholder(when: targetAmount.isEmpty) {
                                        Text("e.g. 10000")
                                            .foregroundColor(Theme.secondaryLabel)
                                    }
                                    .onChange(of: targetAmount) { _ in
                                        updateCalculation()
                                    }
                                Text("total goal")
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                            .padding()
                            
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
            
            // Helper Text
            Text("We'll help you reach your savings goal by recommending the right monthly contribution")
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
    }
    
    private func selectMode(_ mode: SavingsInputMode) {
        withAnimation {
            inputMode = mode
            if mode == .recommended {
                targetAmount = ""
                targetDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
                amount = recommendedAmount
            } else {
                amount = nil
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
