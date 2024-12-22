import SwiftUI

struct SavingsCalculatorModal: View {
    @Binding var isPresented: Bool
    let monthlyIncome: Double
    @State private var selectedCategory: BudgetCategory?
    @State private var targetAmount: String = ""
    @State private var targetDate = Date().addingTimeInterval(365 * 24 * 60 * 60) // Default to 1 year
    @State private var showResults = false
    @State private var searchText = ""
    
    private var filteredCategories: [BudgetCategory] {
        guard !searchText.isEmpty else {
            return BudgetCategoryStore.shared.categories.filter { $0.displayType == .total }
        }
        return BudgetCategoryStore.shared.categories
            .filter { $0.displayType == .total }
            .filter { $0.name.lowercased().contains(searchText.lowercased()) }
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
                            Text("Can I save for this?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Let's see if you can reach your savings goal")
                                .font(.system(size: 17))
                                .foregroundColor(Theme.secondaryLabel)
                                .multilineTextAlignment(.center)
                        }
                        
                        if !showResults {
                            // Input Section
                            VStack(spacing: 24) {
                                // Category Selection
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("What are you saving for?")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white)
                                    
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
                                }
                                
                                // Categories appear here when searching
                                if !filteredCategories.isEmpty && !searchText.isEmpty {
                                    ScrollView {
                                        LazyVStack(spacing: 0) {
                                            ForEach(filteredCategories) { category in
                                                Button(action: {
                                                    selectedCategory = category
                                                    searchText = ""
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
                                
                                if let selected = selectedCategory {
                                    HStack {
                                        Text(selected.emoji)
                                            .font(.title2)
                                        Text(selected.name)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Theme.surfaceBackground)
                                    .cornerRadius(12)
                                
                                    // Target Amount Input
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("How much do you need to save?")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        HStack {
                                            Text("$")
                                                .foregroundColor(.white)
                                            TextField("", text: $targetAmount)
                                                .keyboardType(.decimalPad)
                                                .foregroundColor(.white)
                                                .placeholder(when: targetAmount.isEmpty) {
                                                    Text("0")
                                                        .foregroundColor(Theme.secondaryLabel)
                                                }
                                        }
                                        .padding()
                                        .background(Theme.surfaceBackground)
                                        .cornerRadius(12)
                                    }
                                    
                                    // Target Date Selection
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("When do you need this by?")
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        DatePicker("Target Date",
                                                  selection: $targetDate,
                                                  in: Date()...,
                                                  displayedComponents: .date)
                                            .datePickerStyle(.compact)
                                            .foregroundColor(.white)
                                            .tint(.white)
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
                                    .disabled(targetAmount.isEmpty)
                                    .opacity(targetAmount.isEmpty ? 0.6 : 1)
                                }
                            }
                        } else if let category = selectedCategory,
                                  let savingsGoal = Double(targetAmount) {
                            SavingsResultView(
                                category: category,
                                targetAmount: savingsGoal,
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
            }
            .background(Theme.background)
            .cornerRadius(20)
            .padding()
        }
    }
}

struct SavingsResultView: View {
    let category: BudgetCategory
    let targetAmount: Double
    let targetDate: Date
    let monthlyIncome: Double
    let onRecalculate: () -> Void
    
    private var analysis: SavingsAnalysis {
        calculateSavings()
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with goal info
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
                Text(formatCurrency(targetAmount))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Primary Result Card
            VStack(spacing: 12) {
                Text(analysis.canSave ? "Yes, you can save this! 🎯" : "This goal might be challenging 😅")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(analysis.canSave ? Theme.tint : .red)
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
            
            // Savings Breakdown
            VStack(alignment: .leading, spacing: 16) {
                Label {
                    Text("SAVINGS BREAKDOWN")
                        .font(.system(size: 13, weight: .bold))
                } icon: {
                    Image(systemName: "chart.bar.fill")
                }
                .foregroundColor(Theme.tint)
                
                VStack(spacing: 16) {
                    // Required Monthly Savings
                    ComparisonRow(
                        label: "Monthly Savings Required",
                        wanted: analysis.requiredMonthlySavings,
                        recommended: analysis.recommendedMonthlySavings,
                        showDifference: true
                    )
                    
                    // Time to Goal
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time to Goal")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                        
                        Text("\(analysis.monthsToGoal) months")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Recommendations
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("SAVINGS TIPS")
                        .font(.system(size: 13, weight: .bold))
                } icon: {
                    Image(systemName: "lightbulb.fill")
                }
                .foregroundColor(Theme.tint)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(analysis.recommendations, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(tip)
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                    }
                }
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
    
    private func calculateSavings() -> SavingsAnalysis {
        let months = Calendar.current.dateComponents([.month], from: Date(), to: targetDate).month ?? 0
        let requiredMonthlySavings = targetAmount / Double(max(1, months))
        let maxMonthlySavings = monthlyIncome * category.allocationPercentage
        let canSave = requiredMonthlySavings <= maxMonthlySavings
        
        var recommendations: [String] = []
        if canSave {
            recommendations = [
                "Set up automatic monthly transfers of \(formatCurrency(requiredMonthlySavings))",
                "Consider a high-yield savings account for better returns",
                "Track your progress monthly and adjust if needed"
            ]
        } else {
            recommendations = [
                "Consider extending your timeline to reduce monthly requirements",
                "Look for areas in your budget to increase savings",
                "Break down your goal into smaller milestones",
                "Explore ways to increase your income"
            ]
        }
        
        return SavingsAnalysis(
            canSave: canSave,
            summary: canSave ?
                "You can reach your goal by saving \(formatCurrency(requiredMonthlySavings)) monthly" :
                "You'd need to save \(formatCurrency(requiredMonthlySavings)) monthly, which exceeds your recommended limit",
            requiredMonthlySavings: requiredMonthlySavings,
            recommendedMonthlySavings: maxMonthlySavings,
            monthsToGoal: months,
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

struct ComparisonRow: View {
    let label: String
    let wanted: Double
    let recommended: Double
    let showDifference: Bool
    
    private var difference: Double {
        recommended - wanted
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
            
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Required")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryLabel)
                    Text(formatCurrency(wanted))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryLabel)
                    Text(formatCurrency(recommended))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                }
                
                if showDifference {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Difference")
                            .font(.system(size: 13))
                            .foregroundColor(Theme.secondaryLabel)
                        Text(formatCurrency(abs(difference)))
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(difference >= 0 ? Theme.tint : .red)
                    }
                }
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

struct SavingsAnalysis {
    let canSave: Bool
    let summary: String
    let requiredMonthlySavings: Double
    let recommendedMonthlySavings: Double
    let monthsToGoal: Int
    let recommendations: [String]
}
