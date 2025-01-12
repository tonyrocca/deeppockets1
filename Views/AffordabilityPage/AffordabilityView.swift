import SwiftUI

struct AffordabilityView: View {
    @ObservedObject var model: AffordabilityModel
    @StateObject private var store = BudgetCategoryStore.shared
    @State private var searchText = ""
    
    private var filteredCategories: [BudgetCategory] {
        guard !searchText.isEmpty else { return store.categories }
        return store.categories.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.secondaryLabel)
                TextField("Search categories", text: $searchText)
                    .font(.system(size: 17))
                    .foregroundColor(Theme.label)
                    .placeholder(when: searchText.isEmpty) {
                        Text("Search categories")
                            .foregroundColor(Theme.label.opacity(0.6))
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.secondaryLabel)
                    }
                }
            }
            .padding(12)
            .background(Theme.elevatedBackground)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 4)
            
            // Categories List
            VStack(spacing: 0) {
                if filteredCategories.isEmpty {
                    Text("No matching categories found")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.secondaryLabel)
                        .padding(.vertical, 20)
                } else {
                    ForEach(filteredCategories) { category in
                        CategoryRowView(
                            category: category,
                            amount: model.calculateAffordableAmount(for: category),
                            displayType: category.displayType,
                            onAssumptionsChanged: model.updateAssumptions
                        )
                        
                        if category.id != filteredCategories.last?.id {
                            Divider()
                                .background(Theme.separator)
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.surfaceBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Theme.separator, lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }
}

struct AssumptionSliderView: View {
    let title: String
    let range: ClosedRange<Double>
    let step: Double
    let suffix: String
    @Binding var value: String
    let onChanged: (String) -> Void
    
    private var displayValue: String {
        if title == "Months Coverage" {
            // For months coverage, show just the number without decimal places
            if let doubleValue = Double(value) {
                return String(format: "%.0f", doubleValue)
            }
        }
        return value + suffix
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.label)
                Spacer()
                if title == "Months Coverage" {
                    Text("\(displayValue) months")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.label)
                } else {
                    Text(displayValue)
                        .font(.system(size: 15))
                        .foregroundColor(Theme.label)
                }
            }
            
            Slider(
                value: Binding(
                    get: { Double(value) ?? range.lowerBound },
                    set: { newValue in
                        let rounded = (newValue / step).rounded() * step
                        value = String(format: "%.2f", rounded)
                        onChanged(value)
                    }
                ),
                in: range,
                step: step
            )
            .tint(Theme.tint)
        }
    }
}

struct CategoryRowView: View {
    let category: BudgetCategory
    let amount: Double
    let displayType: AmountDisplayType
    @State private var showDetails = false
    @State private var localAssumptions: [CategoryAssumption]
    @State private var showingAddedToBudget = false
    @State private var showAddToBudgetConfirmation = false
    let onAssumptionsChanged: (String, [CategoryAssumption]) -> Void
    @EnvironmentObject private var budgetModel: BudgetModel
    
    init(category: BudgetCategory, amount: Double, displayType: AmountDisplayType, onAssumptionsChanged: @escaping (String, [CategoryAssumption]) -> Void) {
        self.category = category
        self.amount = amount
        self.displayType = displayType
        self._localAssumptions = State(initialValue: category.assumptions)
        self.onAssumptionsChanged = onAssumptionsChanged
    }
    
    var displayAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "$0"
        return formattedAmount + (displayType == .monthly ? "/mo" : " total")
    }
    
    private var isInBudget: Bool {
        budgetModel.budgetItems.contains { $0.id == category.id && $0.isActive }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation {
                    showDetails.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Text(category.emoji)
                        .font(.title2)
                    Text(category.name)
                        .font(.system(size: 17))
                        .foregroundColor(Theme.label)
                    Spacer()
                    Text(displayAmount)
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            if showDetails {
                VStack(alignment: .leading, spacing: 24) {
                    // Allocation Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ALLOCATION OF SALARY")
                            .sectionHeader()
                        Text(category.formattedAllocation)
                            .font(.system(size: 17))
                            .foregroundColor(Theme.label)
                    }
                    
                    // Monthly Allocation (for total amounts)
                    if displayType == .total {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ESTIMATED MONTHLY ALLOCATION")
                                .sectionHeader()
                            let monthlyAmount = amount / 12
                            Text(formatCurrency(monthlyAmount))
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
                    
                    // Add to Budget Button
                    if !isInBudget {
                        Button(action: { showAddToBudgetConfirmation = true }) {
                            HStack {
                                Text("Add to Budget")
                                    .font(.system(size: 15, weight: .medium))
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 15))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(Theme.surfaceBackground)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                    } else {
                        HStack {
                            Text("Added to Budget")
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .font(.system(size: 15))
                        .foregroundColor(Theme.tint)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(Theme.surfaceBackground)
                        .cornerRadius(8)
                    }
                    
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Theme.elevatedBackground)
            }
        }
        .overlay(
            Group {
                if showingAddedToBudget {
                    VStack {
                        Text("Added to Budget")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Theme.tint)
                            .cornerRadius(8)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut, value: showingAddedToBudget)
                }
            }
        )
        .overlay {
            if showAddToBudgetConfirmation {
                addToBudgetConfirmation
            }
        }
    }
    
    private func addToBudget() {
            // Calculate the recommended monthly amount
            let monthlyAllocation = displayType == .monthly ? amount : amount / 12
            
            // First activate the category
            budgetModel.toggleCategory(id: category.id)
            
            // Then set its allocation
            budgetModel.updateAllocation(for: category.id, amount: monthlyAllocation)
            
            // Show feedback
            withAnimation {
                showingAddedToBudget = true
                showAddToBudgetConfirmation = false
            }
            
            // Hide feedback after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showingAddedToBudget = false
                }
            }
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
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

extension CategoryRowView {
    var addToBudgetConfirmation: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Add to Budget")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Would you like to add \(category.name) to your budget with the recommended amount?")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                
                // Amount Display
                VStack(spacing: 4) {
                    Text("Recommended Monthly Amount")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.secondaryLabel)
                    Text(formatCurrency(displayType == .monthly ? amount : amount / 12))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Buttons
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
}

struct AssumptionView: View {
    @Binding var assumption: CategoryAssumption
    let onChanged: (CategoryAssumption) -> Void
    
    var body: some View {
        Group {
            switch assumption.inputType {
            case .percentageSlider(let step):
                AssumptionSliderView(
                    title: assumption.title,
                    range: 0...100,
                    step: step,
                    suffix: "%",
                    value: $assumption.value
                ) { newValue in
                    assumption.value = newValue
                    onChanged(assumption)
                }
                
            case .yearSlider(let min, let max):
                AssumptionSliderView(
                    title: assumption.title,
                    range: Double(min)...Double(max),
                    step: 1,
                    suffix: " years",
                    value: $assumption.value
                ) { newValue in
                    assumption.value = newValue
                    onChanged(assumption)
                }
                
            case .textField, .percentageDistribution:
                HStack {
                    Text(assumption.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Theme.label)
                    Spacer()
                    TextField(assumption.title, text: $assumption.value)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .padding(8)
                        .background(Theme.elevatedBackground)
                        .cornerRadius(8)
                        .foregroundColor(Theme.label)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    Text(getUnitLabel(for: assumption.title))
                        .font(.system(size: 15))
                        .foregroundColor(Theme.secondaryLabel)
                        .frame(width: 30, alignment: .leading)
                }
            }
        }
    }
    
    private func getUnitLabel(for title: String) -> String {
        if title == "Loan Term" || title == "Years to Save" {
            return "yr"
        }
        if title == "Months Coverage" {
            return "mo"  // Ensure months is displayed for Months Coverage
        }
        if title.contains("Rate") || title == "Monthly Save" {
            return "%"
        }
        
        let percentageFields = [
            "Down Payment",
            "Stocks", "Bonds", "Other Assets",
            "Travel", "Lodging", "Activities"
        ]
        
        if percentageFields.contains(title) {
            return "%"
        }
        
        return ""
    }
}

extension Text {
    func sectionHeader() -> some View {
        self
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Theme.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.mutedGreen.opacity(0.2))
            .cornerRadius(4)
    }
}
