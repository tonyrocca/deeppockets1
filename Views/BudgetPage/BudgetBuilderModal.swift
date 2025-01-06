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
                            Group {
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
                                        amount: binding(for: category)
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
        case .debtConfiguration(let category),
             .expenseConfiguration(let category),
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
                phase = .debtConfiguration(nextCategory)
            } else {
                phase = .expenseSelection
            }
            
        case .debtConfiguration(let category):
            if let amount = temporaryAmounts[category.id] {
                budgetStore.setCategory(category, amount: amount)
                selectedCategories.remove(category.id)
                
                if let nextCategory = selectedCategories.compactMap({ id in
                    debtCategories.first(where: { $0.id == id })
                }).first {
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
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.name)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            
                            let recommendedAmount = monthlyIncome * category.allocationPercentage
                            Text("\(formatCurrency(recommendedAmount))/mo • \(Int(category.allocationPercentage * 100))% of income")
                                .font(.system(size: 13))
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        
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
    @Binding var amount: Double?
    
    @State private var debtAmount = ""
    @State private var interestRate = ""
    @State private var minimumPayment = ""
    @State private var payoffPlan: DebtPayoffPlan?
    
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
                    TextField("", text: $debtAmount)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .placeholder(when: debtAmount.isEmpty) {
                            Text("0")
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        .onChange(of: debtAmount) { _ in
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
                    TextField("", text: $interestRate)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .placeholder(when: interestRate.isEmpty) {
                            Text("0.0")
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        .onChange(of: interestRate) { _ in
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
                    TextField("", text: $minimumPayment)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                        .placeholder(when: minimumPayment.isEmpty) {
                            Text("0")
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        .onChange(of: minimumPayment) { _ in
                            calculatePayoffPlan()
                        }
                }
                .padding()
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
            }
            
            // Payoff Plan Summary
            if let plan = payoffPlan {
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
            let debt = Double(debtAmount),
            let rate = Double(interestRate),
            let minPayment = Double(minimumPayment)
        else {
            payoffPlan = nil
            amount = nil
            return
        }
        
        let plan = DebtPayoffPlan(
            debtAmount: debt,
            interestRate: rate,
            minimumPayment: minPayment,
            monthlyIncome: monthlyIncome
        )
        
        payoffPlan = plan
        amount = plan.monthlyPayment
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
        let numerator = log(monthlyPayment / (monthlyPayment - monthlyRate * debtAmount))
        let denominator = log(1 + monthlyRate)
        return Int(ceil(numerator / denominator))
    }
}

struct ExpenseConfigurationView: View {
    let category: BudgetCategory
    let monthlyIncome: Double
    @Binding var amount: Double?
    
    var body: some View {
        VStack(spacing: 24) {
            // TODO: Add expense configuration UI
            Text("Expense Configuration Placeholder")
        }
    }
}

struct SavingsConfigurationView: View {
    let category: BudgetCategory
    let monthlyIncome: Double
    @Binding var amount: Double?
    
    var body: some View {
        VStack(spacing: 24) {
            // TODO: Add savings configuration UI similar to SavingsCalculatorModal
            Text("Savings Configuration Placeholder")
        }
    }
}
