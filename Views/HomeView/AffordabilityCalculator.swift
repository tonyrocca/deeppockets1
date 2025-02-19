import SwiftUI

// MARK: - Calculation Step Enum
enum CalculationStep {
    case categorySelection
    case amountInput(BudgetCategory)
    case results(BudgetCategory, Double)
}

// MARK: - Affordability Analysis
struct AffordabilityAnalysis {
    let canAfford: Bool
    let summary: String
    let recommendedAmount: Double
    let recommendedMonthly: Double
    let monthlyAmount: Double
}

struct AffordabilityCalculatorModal: View {
    @Binding var isPresented: Bool
    let monthlyIncome: Double
    let payPeriod: PayPeriod
    
    @State private var currentStep: CalculationStep = .categorySelection
    @State private var searchText = ""
    @State private var amount = ""
    @State private var isMonthlyAmount = false
    @State private var showAssumptions = false
    @State private var localAssumptions: [CategoryAssumption] = []
    @EnvironmentObject private var budgetModel: BudgetModel
    @FocusState private var isAmountFocused: Bool
    
    private var filteredCategories: [BudgetCategory] {
        guard !searchText.isEmpty else { return [] }
        return SearchUtils.searchCategories(BudgetCategoryStore.shared.categories, searchText: searchText)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                ScrollView {
                    VStack(spacing: 32) {
                        switch currentStep {
                        case .categorySelection:
                            categorySelectionView
                        case .amountInput(let category):
                            amountInputView(category: category)
                        case .results(let category, let amount):
                            resultsView(category: category, amount: amount)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(Theme.background)
            .cornerRadius(20)
            .padding()
        }
    }
    
    // MARK: - Header View
    private var header: some View {
        HStack {
            // Back button for non-first steps
            if case .categorySelection = currentStep {
                Spacer()
            } else {
                Button(action: handleBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 17))
                    .foregroundColor(Theme.secondaryLabel)
                }
                Spacer()
            }
            
            // Close button
            Button(action: { isPresented = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.secondaryLabel)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Category Selection View
    private var categorySelectionView: some View {
        VStack(spacing: 24) {
            // Title
            VStack(spacing: 8) {
                Text("What can you afford?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("Let's find out what fits your budget")
                    .font(.system(size: 17))
                    .foregroundColor(Theme.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            
            // Search
            VStack(alignment: .leading, spacing: 8) {
                Text("What would you like to buy?")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.secondaryLabel)
                    TextField("", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .placeholder(when: searchText.isEmpty) {
                            Text("Search categories...")
                                .foregroundColor(Theme.secondaryLabel)
                        }
                }
                .padding()
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
            }
            
            // Results
            if !searchText.isEmpty {
                VStack(spacing: 1) {
                    ForEach(filteredCategories) { category in
                        Button(action: {
                            withAnimation {
                                currentStep = .amountInput(category)
                                searchText = ""
                            }
                        }) {
                            HStack(spacing: 12) {
                                Text(category.emoji)
                                    .font(.title2)
                                Text(category.name)
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(Theme.surfaceBackground)
                        }
                        
                        if category != filteredCategories.last {
                            Divider()
                                .background(Theme.separator)
                        }
                    }
                }
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Amount Input View
    private func amountInputView(category: BudgetCategory) -> some View {
        VStack(spacing: 24) {
            // Header
            HStack(spacing: 8) {
                Text(category.emoji)
                    .font(.title2)
                Text(category.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Amount Input Section
            VStack(alignment: .leading, spacing: 16) {
                Text("How much will it cost?")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    // Amount Input
                    HStack {
                        Text("$")
                            .foregroundColor(.white)
                        TextField("", text: $amount)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                            .placeholder(when: amount.isEmpty) {
                                Text("0")
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                    }
                    .padding()
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                    
                    // Toggle between monthly/total
                    if category.displayType == .total {
                        Toggle("Enter monthly amount", isOn: $isMonthlyAmount)
                            .tint(Theme.tint)
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Calculate Button
            if !amount.isEmpty {
                Button(action: {
                    if let amountValue = Double(amount) {
                        let finalAmount = isMonthlyAmount ? amountValue * 12 : amountValue
                        withAnimation {
                            currentStep = .results(category, finalAmount)
                        }
                    }
                }) {
                    Text("Calculate")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.tint)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private func calculateAffordability(category: BudgetCategory, amount: Double) -> AffordabilityAnalysis {
        let monthlyAmount = isMonthlyAmount ? amount : amount / 12
        var recommendedMonthly: Double
        var recommendedAmount: Double
        
        switch category.id {
        case "home":
            recommendedAmount = BudgetCategoryStore.shared.calculateHomeAffordability(category, monthlyIncome: monthlyIncome)
            recommendedMonthly = recommendedAmount * category.allocationPercentage
            
        case "car":
            recommendedAmount = BudgetCategoryStore.shared.calculateCarAffordability(category, monthlyIncome: monthlyIncome)
            recommendedMonthly = recommendedAmount * category.allocationPercentage
            
        case "emergency_savings":
            recommendedAmount = BudgetCategoryStore.shared.calculateEmergencySavings(category, monthlyIncome: monthlyIncome)
            recommendedMonthly = recommendedAmount / 12
            
        default:
            recommendedMonthly = monthlyIncome * category.allocationPercentage
            recommendedAmount = category.displayType == .monthly ?
                recommendedMonthly :
                recommendedMonthly * 12
        }
        
        let canAfford = amount <= recommendedAmount
        let difference = abs(recommendedAmount - amount)
        
        // Create appropriate summary based on category type
        let summary: String
        switch category.type {
        case .housing:
            summary = canAfford ?
                "Based on your income, you can afford a home up to \(formatCurrency(recommendedAmount))" :
                "This home is \(formatCurrency(difference)) above your recommended price range"
            
        case .transportation:
            summary = canAfford ?
                "You can comfortably afford a vehicle up to \(formatCurrency(recommendedAmount))" :
                "This vehicle exceeds your recommended budget by \(formatCurrency(difference))"
            
        case .savings:
            summary = canAfford ?
                "This savings goal fits within your recommended monthly savings of \(formatCurrency(recommendedMonthly))" :
                "Consider extending your timeline to make this goal more achievable"
            
        default:
            summary = canAfford ?
                "This fits within your recommended budget of \(formatCurrency(recommendedMonthly))/month" :
                "This exceeds your recommended monthly budget by \(formatCurrency(monthlyAmount - recommendedMonthly))"
        }
        
        return AffordabilityAnalysis(
            canAfford: canAfford,
            summary: summary,
            recommendedAmount: recommendedAmount,
            recommendedMonthly: recommendedMonthly,
            monthlyAmount: monthlyAmount
        )
    }
    
    // MARK: - Results View
    private func resultsView(category: BudgetCategory, amount: Double) -> some View {
        let analysis = calculateAffordability(category: category, amount: amount)
        
        return VStack(spacing: 24) {
            // Category & Amount Header
            HStack {
                HStack(spacing: 8) {
                    Text(category.emoji)
                        .font(.title2)
                    Text(category.name)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text(formatCurrency(amount))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Main Result
            VStack(spacing: 12) {
                Text(analysis.canAfford ? "Yes, you can afford this! 🎉" : "This might be out of reach 😅")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(analysis.canAfford ? Theme.tint : .red)
                    .multilineTextAlignment(.center)
                
                Text(analysis.summary)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Payment Breakdown
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Label {
                    Text("PAYMENT BREAKDOWN")
                        .font(.system(size: 13, weight: .bold))
                } icon: {
                    Image(systemName: "chart.bar.fill")
                }
                .foregroundColor(Theme.tint)
                
                // Monthly Payment
                paymentRow(
                    title: "Monthly Payment",
                    amount: analysis.monthlyAmount,
                    recommended: analysis.recommendedMonthly
                )
                
                // Per-paycheck amount
                paymentRow(
                    title: "Per \(payPeriod.rawValue)",
                    amount: analysis.monthlyAmount / payPeriod.multiplier,
                    recommended: analysis.recommendedMonthly / payPeriod.multiplier
                )
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Assumptions Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label {
                        Text("ASSUMPTIONS")
                            .font(.system(size: 13, weight: .bold))
                    } icon: {
                        Image(systemName: "gearshape.fill")
                    }
                    .foregroundColor(Theme.tint)
                    
                    Spacer()
                    
                    Button(action: { showAssumptions.toggle() }) {
                        Text(showAssumptions ? "Done" : "Adjust")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.tint)
                    }
                }
                
                if showAssumptions {
                    assumptionsView(category: category)
                } else {
                    ForEach(category.assumptions) { assumption in
                        HStack {
                            Text(assumption.title)
                                .font(.system(size: 15))
                                .foregroundColor(Theme.secondaryLabel)
                            Spacer()
                            Text(assumption.displayValue)
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Action Buttons
            HStack(spacing: 12) {
                // Add to Budget
                Button(action: {
                    addToBudget(category: category, amount: analysis.monthlyAmount)
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Budget")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Theme.tint)
                    .cornerRadius(12)
                }
                
                // Pin Category
                Button(action: {
                    // Add pin functionality
                }) {
                    HStack {
                        Image(systemName: "pin.fill")
                        Text("Pin")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Theme.surfaceBackground)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func paymentRow(title: String, amount: Double, recommended: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Actual")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryLabel)
                    Text(formatCurrency(amount))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Recommended")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryLabel)
                    Text(formatCurrency(recommended))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(amount <= recommended ? Theme.tint : .red)
                }
            }
        }
    }
    
    private func assumptionsView(category: BudgetCategory) -> some View {
        VStack(spacing: 16) {
            ForEach(category.assumptions) { assumption in
                // For simplicity while assumptions are being edited, just show their values
                HStack {
                    Text(assumption.title)
                        .font(.system(size: 15))
                        .foregroundColor(Theme.secondaryLabel)
                    Spacer()
                    Text(assumption.displayValue)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleBack() {
        withAnimation {
            switch currentStep {
            case .amountInput:
                currentStep = .categorySelection
            case .results:
                if case let .results(category, _) = currentStep {
                    currentStep = .amountInput(category)
                }
            default:
                break
            }
        }
    }
    
    private func addToBudget(category: BudgetCategory, amount: Double) {
        budgetModel.toggleCategory(id: category.id)
        budgetModel.updateAllocation(for: category.id, amount: amount)
        isPresented = false
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

extension BudgetCategory: Equatable {
    static func == (lhs: BudgetCategory, rhs: BudgetCategory) -> Bool {
        lhs.id == rhs.id
    }
}

extension AssumptionInputType: Equatable {
    static func == (lhs: AssumptionInputType, rhs: AssumptionInputType) -> Bool {
        switch (lhs, rhs) {
        case (.percentageSlider(let lStep), .percentageSlider(let rStep)):
            return lStep == rStep
        case (.yearSlider(let lMin, let lMax), .yearSlider(let rMin, let rMax)):
            return lMin == rMin && lMax == rMax
        case (.textField, .textField):
            return true
        case (.percentageDistribution, .percentageDistribution):
            return true
        default:
            return false
        }
    }
}
