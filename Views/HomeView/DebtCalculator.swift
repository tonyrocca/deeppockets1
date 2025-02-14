import SwiftUI

struct DebtCalculatorModal: View {
    @Binding var isPresented: Bool
    let monthlyIncome: Double
    @State private var selectedCategory: BudgetCategory?
    @State private var debtAmount: String = ""
    @State private var interestRate: String = ""
    @State private var targetDate = Date().addingTimeInterval(365 * 24 * 60 * 60) // Default to 1 year
    @State private var showResults = false
    @State private var searchText = ""
    @State private var isSearching = true  // Start in search mode

    // Modified filteredCategories logic
    private var filteredCategories: [BudgetCategory] {
        if searchText.isEmpty {
            return []  // Return empty array when search is empty
        }
        return BudgetCategoryStore.shared.categories.filter { category in
            isDebtCategory(category.id) &&
            (category.name.lowercased().contains(searchText.lowercased()) ||
             category.description.lowercased().contains(searchText.lowercased()))
        }
    }
    
    private func isDebtCategory(_ id: String) -> Bool {
        ["credit_cards", "student_loans", "personal_loans", "car_loan"].contains(id)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Title
                        VStack(spacing: 8) {
                            Text("Debt Payoff Calculator")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Let's plan your debt payoff strategy")
                                .font(.system(size: 17))
                                .foregroundColor(Theme.secondaryLabel)
                                .multilineTextAlignment(.center)
                        }
                        
                        if !showResults {
                            // Input Section
                            VStack(spacing: 24) {
                                // Category Selection / Search Area
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("What type of debt is this?")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    if selectedCategory == nil || isSearching {
                                        // Search Field
                                        HStack {
                                            Image(systemName: "magnifyingglass")
                                                .foregroundColor(Theme.secondaryLabel)
                                            TextField("", text: $searchText)
                                                .textFieldStyle(PlainTextFieldStyle())
                                                .foregroundColor(.white)
                                                .placeholder(when: searchText.isEmpty) {
                                                    Text("Enter category")
                                                        .foregroundColor(Theme.secondaryLabel)
                                                }
                                        }
                                        .padding()
                                        .background(Theme.surfaceBackground)
                                        .cornerRadius(12)
                                        
                                        // Search Results with modified condition
                                        if !searchText.isEmpty {
                                            ScrollView {
                                                LazyVStack(spacing: 0) {
                                                    ForEach(filteredCategories) { category in
                                                        Button(action: {
                                                            withAnimation {
                                                                selectedCategory = category
                                                                searchText = ""
                                                                isSearching = false
                                                            }
                                                        }) {
                                                            HStack {
                                                                Text(category.emoji)
                                                                    .font(.title2)
                                                                Text(category.name)
                                                                    .foregroundColor(.white)
                                                                Spacer()
                                                            }
                                                            .padding()
                                                            .background(
                                                                selectedCategory?.id == category.id ?
                                                                Theme.tint.opacity(0.2) :
                                                                Color.clear
                                                            )
                                                        }
                                                        
                                                        Divider()
                                                            .background(Theme.separator)
                                                    }
                                                }
                                            }
                                            .frame(maxHeight: 200)
                                            .background(Theme.surfaceBackground)
                                            .cornerRadius(12)
                                        }
                                    } else {
                                        // Selected Category Display
                                        HStack {
                                            Text(selectedCategory?.emoji ?? "")
                                                .font(.title2)
                                            Text(selectedCategory?.name ?? "")
                                                .foregroundColor(.white)
                                            Spacer()
                                            Button(action: {
                                                withAnimation {
                                                    selectedCategory = nil
                                                    searchText = ""
                                                    isSearching = true
                                                    debtAmount = ""
                                                    interestRate = ""
                                                }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(Theme.secondaryLabel)
                                                    .font(.system(size: 22))
                                            }
                                        }
                                        .padding()
                                        .background(Theme.surfaceBackground)
                                        .cornerRadius(12)
                                    }
                                }
                                
                                // Rest of your input fields...
                                if let selected = selectedCategory {
                                    // Debt Amount Input
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("How much is the total debt?")
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
                                        }
                                        .padding()
                                        .background(Theme.surfaceBackground)
                                        .cornerRadius(12)
                                    }
                                    
                                    // Interest Rate Input
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("What's the interest rate?")
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
                                            Text("%")
                                                .foregroundColor(.white)
                                        }
                                        .padding()
                                        .background(Theme.surfaceBackground)
                                        .cornerRadius(12)
                                    }
                                    
                                    // Target Date Selection
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("When do you want this paid off?")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        HStack {
                                            Text("Target Date")
                                                .foregroundColor(.white)
                                            Spacer()
                                            DatePicker("",
                                                       selection: $targetDate,
                                                       in: Date()...,
                                                       displayedComponents: .date)
                                                .datePickerStyle(.compact)
                                                .colorScheme(.dark)
                                                .labelsHidden()
                                        }
                                        .padding()
                                        .background(Theme.surfaceBackground)
                                        .cornerRadius(12)
                                    }
                                    
                                    // Calculate Button
                                    Button(action: {
                                        withAnimation {
                                            showResults = true
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
                                    .disabled(debtAmount.isEmpty || interestRate.isEmpty)
                                    .opacity(debtAmount.isEmpty || interestRate.isEmpty ? 0.6 : 1)
                                }
                            }
                        } else if let category = selectedCategory,
                                  let debtValue = Double(debtAmount),
                                  let interestValue = Double(interestRate) {
                            DebtResultView(
                                category: category,
                                debtAmount: debtValue,
                                interestRate: interestValue,
                                targetDate: targetDate,
                                monthlyIncome: monthlyIncome,
                                onRecalculate: {
                                    withAnimation {
                                        showResults = false
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)
                .ignoresSafeArea(.keyboard)
            }
            .background(Theme.background)
            .cornerRadius(20)
            .padding()
        }
    }
}

struct DebtResultView: View {
    let category: BudgetCategory
    let debtAmount: Double
    let interestRate: Double
    let targetDate: Date
    let monthlyIncome: Double
    let onRecalculate: () -> Void
    
    private var analysis: DebtAnalysis {
        calculateDebtPayoff()
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with debt info
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(category.emoji)
                            .font(.title2)
                        Text(category.name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                Text(formatCurrency(debtAmount))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Primary Result Card
            VStack(spacing: 12) {
                Text(analysis.canAfford ? "Yes, this plan works! 💪" : "This timeline might be tight 😅")
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
                Label {
                    Text("PAYMENT BREAKDOWN")
                        .font(.system(size: 13, weight: .bold))
                } icon: {
                    Image(systemName: "chart.bar.fill")
                }
                .foregroundColor(Theme.tint)
                
                VStack(spacing: 24) {
                    // Required Monthly Payment
                    ComparisonRow(
                        label: "Monthly Payment Required",
                        wanted: analysis.requiredMonthlyPayment,
                        recommended: analysis.recommendedMonthlyPayment,
                        showDifference: true
                    )
                    
                    // Total Interest - Now as a full-width section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Interest")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                        
                        Text(formatCurrency(analysis.totalInterest))
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Recommendations
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("PAYOFF TIPS")
                        .font(.system(size: 13, weight: .bold))
                } icon: {
                    Image(systemName: "lightbulb.fill")
                }
                .foregroundColor(Theme.tint)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(analysis.recommendations, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                            Text(tip)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Recalculate Button
            Button(action: onRecalculate) {
                Text("Calculate Something Else")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.tint)
                    .cornerRadius(12)
            }
        }
    }
    
    private func calculateDebtPayoff() -> DebtAnalysis {
        let months = Calendar.current.dateComponents([.month], from: Date(), to: targetDate).month ?? 0
        let monthlyRate = interestRate / 100 / 12
        let numberOfPayments = Double(months)
        
        // Calculate monthly payment using amortization formula
        let monthlyPayment = debtAmount * (monthlyRate * pow(1 + monthlyRate, numberOfPayments)) /
            (pow(1 + monthlyRate, numberOfPayments) - 1)
        
        let totalPayments = monthlyPayment * numberOfPayments
        let totalInterest = totalPayments - debtAmount
        let maxMonthlyPayment = monthlyIncome * category.allocationPercentage
        let canAfford = monthlyPayment <= maxMonthlyPayment
        
        var recommendations: [String] = []
        if canAfford {
            recommendations = [
                "Set up automatic monthly payments of \(formatCurrency(monthlyPayment))",
                "Consider making extra payments to reduce total interest",
                "Look for opportunities to refinance at a lower rate",
                "Put any windfalls toward the principal balance"
            ]
        } else {
            recommendations = [
                "Consider extending your timeline to lower monthly payments",
                "Look into debt consolidation options",
                "Try negotiating a lower interest rate",
                "Consider a balance transfer to a lower-rate card"
            ]
        }
        
        return DebtAnalysis(
            canAfford: canAfford,
            summary: canAfford ?
                "Your monthly payment of \(formatCurrency(monthlyPayment)) fits your budget" :
                "The monthly payment of \(formatCurrency(monthlyPayment)) exceeds your recommended limit",
            requiredMonthlyPayment: monthlyPayment,
            recommendedMonthlyPayment: maxMonthlyPayment,
            totalInterest: totalInterest,
            recommendations: recommendations
        )
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct DebtAnalysis {
    let canAfford: Bool
    let summary: String
    let requiredMonthlyPayment: Double
    let recommendedMonthlyPayment: Double
    let totalInterest: Double
    let recommendations: [String]
}
