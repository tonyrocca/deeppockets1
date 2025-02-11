import SwiftUI

struct AffordabilityCalculatorModal: View {
   @Binding var isPresented: Bool
   let monthlyIncome: Double
   @State private var selectedCategory: BudgetCategory?
   @State private var amount: String = ""
   @State private var showResults = false
   @State private var selectedTimeframe: TimeFrame = .monthly
   @State private var searchText = ""
   
   enum TimeFrame {
       case monthly, yearly, overall
       
       var text: String {
           switch self {
           case .monthly: return "per month"
           case .yearly: return "per year"
           case .overall: return "overall"
           }
       }
       
       var multiplier: Double {
           switch self {
           case .monthly: return 1
           case .yearly: return 12
           case .overall: return 1
           }
       }
   }
   
   private var filteredCategories: [BudgetCategory] {
       guard !searchText.isEmpty else { return BudgetCategoryStore.shared.categories }
       return BudgetCategoryStore.shared.categories.filter {
           $0.name.lowercased().contains(searchText.lowercased())
       }
   }
   
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
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
                        // Title Section
                        VStack(spacing: 8) {
                            Text("Can I afford this?")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("Let's find out if your income can handle it")
                                .font(.system(size: 17))
                                .foregroundColor(Theme.secondaryLabel)
                                .multilineTextAlignment(.center)
                        }
                        
                        if !showResults {
                            // Input Section
                            VStack(spacing: 24) {
                                // Category Selection
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("What would you like to buy?")
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
                                        Button(action: {
                                            selectedCategory = nil
                                            amount = ""
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(Theme.secondaryLabel)
                                                .font(.system(size: 22))
                                        }
                                    }
                                    .padding()
                                    .background(Theme.surfaceBackground)
                                    .cornerRadius(12)
                                
                                    // Amount Input Section
                                    VStack(alignment: .leading, spacing: 8) {
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
                                            
                                            // Timeframe Picker
                                            HStack {
                                                ForEach([TimeFrame.monthly, TimeFrame.yearly, TimeFrame.overall], id: \.self) { timeframe in
                                                    Button(action: {
                                                        selectedTimeframe = timeframe
                                                    }) {
                                                        Text(timeframe.text)
                                                            .font(.system(size: 15, weight: .medium))
                                                            .foregroundColor(selectedTimeframe == timeframe ? .black : .white)
                                                            .padding(.vertical, 8)
                                                            .padding(.horizontal, 16)
                                                            .frame(maxWidth: .infinity)
                                                            .background(
                                                                selectedTimeframe == timeframe ?
                                                                Color.white :
                                                                Theme.surfaceBackground
                                                            )
                                                            .cornerRadius(8)
                                                    }
                                                }
                                            }
                                        }
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
                                    .disabled(amount.isEmpty)
                                    .opacity(amount.isEmpty ? 0.6 : 1)
                                }
                            }
                        } else if let category = selectedCategory,
                                  let amountValue = Double(amount) {
                            AffordabilityResultView(
                                category: category,
                                amount: amountValue,
                                monthlyIncome: monthlyIncome,
                                timeframe: selectedTimeframe,
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
   
   private func formatCurrency(_ value: Double) -> String {
       let formatter = NumberFormatter()
       formatter.numberStyle = .currency
       formatter.maximumFractionDigits = 0
       return formatter.string(from: NSNumber(value: value)) ?? "$0"
   }
}

struct InfoCard: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            } icon: {
                Image(systemName: icon)
            }
            .foregroundColor(Theme.tint)
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(Theme.label)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfaceBackground)
        .cornerRadius(12)
    }
}

struct AffordabilityResultView: View {
    let category: BudgetCategory
    let amount: Double
    let monthlyIncome: Double
    let timeframe: AffordabilityCalculatorModal.TimeFrame
    let onRecalculate: () -> Void
    
    private var analysis: AffordabilityAnalysis {
        calculateAffordability()
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header - Category and Amount
            HStack {
                HStack {
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
            
            // Primary Result Card
            VStack(spacing: 12) {
                Text(analysis.canAfford ? "Yes, you can afford this! 🎉" : "No, this might be a stretch 😅")
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
            
            // Affordability Breakdown
            VStack(alignment: .leading, spacing: 16) {
                Label {
                    Text("AFFORDABILITY BREAKDOWN")
                        .font(.system(size: 13, weight: .bold))
                } icon: {
                    Image(systemName: "chart.bar.fill")
                }
                .foregroundColor(Theme.tint)
                
                // Monthly Breakdown
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Payment")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Wanted")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.secondaryLabel)
                                Text(formatCurrency(analysis.monthlyAmount))
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Recommended")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.secondaryLabel)
                                Text(formatCurrency(analysis.recommendedMonthly))
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Difference")
                                    .font(.system(size: 13))
                                    .foregroundColor(Theme.secondaryLabel)
                                Text(formatCurrency(abs(analysis.recommendedMonthly - analysis.monthlyAmount)))
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(analysis.canAfford ? Theme.tint : .red)
                            }
                        }
                    }
                    
                    // Overall/Yearly Total (if not monthly)
                    if timeframe != .monthly {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(timeframe == .yearly ? "Yearly Total" : "Overall Total")
                                .font(.system(size: 15))
                                .foregroundColor(Theme.secondaryLabel)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Wanted")
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.secondaryLabel)
                                    Text(formatCurrency(amount))
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading) {
                                    Text("Recommended")
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.secondaryLabel)
                                    Text(formatCurrency(analysis.recommendedAmount))
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Difference")
                                        .font(.system(size: 13))
                                        .foregroundColor(Theme.secondaryLabel)
                                    Text(formatCurrency(abs(analysis.recommendedAmount - amount)))
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(analysis.canAfford ? Theme.tint : .red)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Income Context
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    Text("RECOMMENDATION")
                        .font(.system(size: 13, weight: .bold))
                } icon: {
                    Image(systemName: "chart.pie.fill")
                }
                .foregroundColor(Theme.tint)
                
                Text("Based on your income of \(formatCurrency(monthlyIncome))/month, you should spend no more than \(formatCurrency(analysis.recommendedMonthly)) per month on \(category.name.lowercased())")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private func calculateAffordability() -> AffordabilityAnalysis {
        let monthlyAmount = timeframe == .monthly ? amount : amount / 12
        let maxMonthlyAmount = monthlyIncome * category.allocationPercentage
        let recommendedAmount = timeframe == .monthly ? maxMonthlyAmount : maxMonthlyAmount * 12
        let canAfford = amount <= recommendedAmount
        let difference = abs(recommendedAmount - amount)
        
        return AffordabilityAnalysis(
            canAfford: canAfford,
            summary: canAfford ?
                "You're under budget by \(formatCurrency(difference))" :
                "You're over budget by \(formatCurrency(difference))",
            recommendedAmount: recommendedAmount,
            recommendedMonthly: maxMonthlyAmount,
            monthlyAmount: monthlyAmount
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

struct AffordabilityAnalysis {
    let canAfford: Bool
    let summary: String
    let recommendedAmount: Double
    let recommendedMonthly: Double
    let monthlyAmount: Double
}


