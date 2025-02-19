import SwiftUI

// MARK: - AffordabilityView
import SwiftUI

// MARK: - AffordabilityView
struct AffordabilityView: View {
    @ObservedObject var model: AffordabilityModel
    @StateObject private var store = BudgetCategoryStore.shared
    @State private var searchText = ""
    @State private var pinnedCategories: Set<String> = [] // Existing state for pinned categories
    @State private var selectedPeriod: IncomePeriod = .annual // Existing state for selected income period
    @FocusState private var isSearchFocused: Bool
    let payPeriod: PayPeriod

    // Filtered categories sorted by priority (most important at the top)
    private var filteredCategories: [BudgetCategory] {
        let categories: [BudgetCategory]
        if searchText.isEmpty {
            categories = store.categories.filter { !isDebtCategory($0) }
        } else {
            categories = store.categories.filter {
                !isDebtCategory($0) && $0.name.lowercased().contains(searchText.lowercased())
            }
        }
        return categories.sorted { $0.priority < $1.priority }
    }
    
    // Pinned categories sorted by priority
    private var pinnedCategoryList: [BudgetCategory] {
        return store.categories.filter { pinnedCategories.contains($0.id) }
            .sorted { $0.priority < $1.priority }
    }
    
    // Unpinned categories (already sorted because filteredCategories is sorted)
    private var unpinnedCategories: [BudgetCategory] {
        filteredCategories.filter { !pinnedCategories.contains($0.id) }
    }
    
    private var displayedAmount: Double {
        switch selectedPeriod {
        case .annual:
            return model.monthlyIncome * 12
        case .monthly:
            return model.monthlyIncome
        case .perPaycheck:
            return model.monthlyIncome / payPeriod.multiplier
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Income Header
            StickyIncomeHeader(monthlyIncome: model.monthlyIncome)
                .padding(.top, 16)
            
            // Fixed Search Bar
            searchBar
                .padding(.vertical, 16)
                .background(Theme.background)
            
            // Scrollable Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Categories List Section
                    VStack(spacing: 16) {
                        // Pinned Categories Section
                        if !pinnedCategories.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("PINNED CATEGORIES")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Theme.tint)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.mutedGreen.opacity(0.2))
                                    .cornerRadius(4)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                                
                                VStack(spacing: 0) {
                                    ForEach(pinnedCategoryList) { category in
                                        CategoryRowView(
                                            category: category,
                                            model: model,
                                            displayType: category.displayType,
                                            isPinned: true,
                                            onPinChanged: { id, shouldPin in
                                                withAnimation(.easeInOut) {
                                                    if shouldPin {
                                                        pinnedCategories.insert(id)
                                                    } else {
                                                        pinnedCategories.remove(id)
                                                    }
                                                }
                                            }
                                        )
                                        
                                        if category.id != pinnedCategoryList.last?.id {
                                            Divider()
                                                .background(Theme.separator)
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                                
                                Divider()
                                    .background(Theme.separator)
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("WHAT YOU CAN AFFORD...")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.tint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.mutedGreen.opacity(0.2))
                                .cornerRadius(4)
                                .padding(.horizontal, 10)
                                .padding(.top, 0)
                            
                            // Main Categories List
                            VStack(spacing: 0) {
                                if unpinnedCategories.isEmpty {
                                    Text("No matching categories found")
                                        .font(.system(size: 15))
                                        .foregroundColor(Theme.secondaryLabel)
                                        .padding(.vertical, 20)
                                } else {
                                    ForEach(unpinnedCategories) { category in
                                        CategoryRowView(
                                            category: category,
                                            model: model,
                                            displayType: category.displayType,
                                            isPinned: false,
                                            onPinChanged: { id, shouldPin in
                                                withAnimation(.easeInOut) {
                                                    if shouldPin {
                                                        pinnedCategories.insert(id)
                                                    } else {
                                                        pinnedCategories.remove(id)
                                                    }
                                                }
                                            }
                                        )
                                        
                                        if category.id != unpinnedCategories.last?.id {
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
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                              to: nil, from: nil, for: nil)
            }
        }
        .background(Theme.background)
        .gesture(
            TapGesture()
                .onEnded { _ in
                    isSearchFocused = false
                }
        )
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.secondaryLabel)
            TextField("Search categories...", text: $searchText)
                .focused($isSearchFocused)
                .font(.system(size: 17))
                .foregroundColor(Theme.label)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .placeholder(when: searchText.isEmpty) {
                    Text("Search categories...")
                        .foregroundColor(Theme.secondaryLabel)
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    isSearchFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.secondaryLabel)
                }
            }
        }
        .padding(14)
        .background(
            Theme.surfaceBackground
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
    
    private func isDebtCategory(_ category: BudgetCategory) -> Bool {
        let debtCategories = ["credit_cards", "student_loans", "personal_loans", "car_loan", "medical_debt", "mortgage"]
        return debtCategories.contains(category.id)
    }
}

// MARK: - StickyIncomeHeader
struct StickyIncomeHeader: View {
   let monthlyIncome: Double
   private let incomePercentiles: [(threshold: Double, percentile: Int)] = [
       (650000, 1),
       (250000, 5),
       (180000, 10),
       (120000, 20),
       (90000, 30),
       (70000, 40),
       (50000, 50),
       (35000, 60),
       (25000, 70)
   ]
   
   private var annualIncome: Double {
       monthlyIncome * 12
   }
   
   private var incomePercentile: Int {
       for (threshold, percentile) in incomePercentiles {
           if annualIncome >= threshold {
               return percentile
           }
       }
       return 80 // Default if below all thresholds
   }
   
   var body: some View {
       VStack(spacing: 0) {
           // Main Income Section
           VStack(spacing: 12) {
               // Income Row
               HStack(alignment: .center) {
                   Text("Your Annual Income")
                       .font(.system(size: 17))
                       .foregroundColor(Theme.label)
                   
                   Spacer()
                   
                   Text(formatCurrency(annualIncome))
                       .font(.system(size: 28, weight: .bold))
                       .foregroundColor(Theme.label)
               }
               
               // Percentile Row
               HStack(alignment: .center, spacing: 8) {
                   Text("You are a top \(incomePercentile)% earner in the USA based on your salary")
                       .font(.system(size: 15))
                       .foregroundColor(Theme.secondaryLabel)
                       .lineLimit(2)
                       .multilineTextAlignment(.leading)
                   
                   HStack(spacing: 4) {
                       Image(systemName: "chart.bar.fill")
                       Text("Top \(incomePercentile)%")
                   }
                   .font(.system(size: 13))
                   .foregroundColor(Theme.tint)
                   .padding(.horizontal, 10)
                   .padding(.vertical, 6)
                   .background(Theme.tint.opacity(0.15))
                   .cornerRadius(8)
               }
           }
           .padding(16)
           .background(Theme.surfaceBackground)
           .cornerRadius(16)
           .padding(.horizontal, 16)
       }
       .background(Theme.background)
   }
   
   private func formatCurrency(_ value: Double) -> String {
       let formatter = NumberFormatter()
       formatter.numberStyle = .currency
       formatter.maximumFractionDigits = 0
       return formatter.string(from: NSNumber(value: value)) ?? "$0"
   }
}

// MARK: - AssumptionSliderView
struct AssumptionSliderView: View {
    let title: String
    let range: ClosedRange<Double>
    let step: Double
    let suffix: String
    @Binding var value: String
    let onChanged: (String) -> Void
    
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    private var numericValue: Double {
        Double(value) ?? range.lowerBound
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Value Row
            HStack(alignment: .center) {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Value Box
                Button(action: { startEditing() }) {
                    HStack(spacing: 2) {
                        if isEditing {
                            TextField("", text: $value)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($isFocused)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 60)
                        } else {
                            Text(String(format: "%.2f", numericValue))
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 60, alignment: .trailing)
                        }
                        
                        Text(suffix)
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                            .frame(width: 30, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.surfaceBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isEditing ? Theme.tint : Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            
            // Slider Section
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { numericValue },
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
                
                // Range Labels
                HStack {
                    Text("\(String(format: "%.2f", range.lowerBound))\(suffix)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryLabel)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.2f", range.upperBound))\(suffix)")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryLabel)
                }
            }
        }
        .contentShape(Rectangle())
        .highPriorityGesture(DragGesture(minimumDistance: 0))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    commitEdit()
                }
            }
        }
    }
    
    private func startEditing() {
        value = String(format: "%.2f", numericValue)
        isEditing = true
        isFocused = true
    }
    
    private func commitEdit() {
        guard let newValue = Double(value) else {
            isEditing = false
            return
        }
        
        let clampedValue = min(max(newValue, range.lowerBound), range.upperBound)
        value = String(format: "%.2f", (clampedValue / step).rounded() * step)
        onChanged(value)
        
        isEditing = false
        isFocused = false
    }
}

// MARK: - CategoryRowView (Updated with realistic monthly cost for .total)
struct CategoryRowView: View {
    let category: BudgetCategory
    @ObservedObject var model: AffordabilityModel
    let displayType: AmountDisplayType
    let isPinned: Bool
    @State private var showInlineDetails = false
    @State private var showFullScreenDetails = false
    // Initialize local assumptions from the category
    @State private var localAssumptions: [CategoryAssumption]
    let onPinChanged: (String, Bool) -> Void
    @EnvironmentObject private var budgetModel: BudgetModel
    @State private var showAddToBudgetConfirmation = false
    @State private var showingAddedToBudget = false

    // Compute the total “affordable” amount from the model (e.g. total home price).
    private var totalAmount: Double {
        model.affordabilityAmounts[category.id] ?? model.calculateAffordableAmount(for: category)
    }
    
    /// For categories with `.total` display type (like "home" or "car"),
    /// we show a realistic monthly cost rather than totalAmount / 12.
    private var estimatedMonthlyCost: Double {
        switch category.id {
        case "home":
            return calculateHomeMonthlyCost()
        case "car":
            return calculateCarMonthlyCost()
        default:
            // If it's some other “total” category, fallback to dividing by 12.
            return totalAmount / 12
        }
    }
    
    init(category: BudgetCategory,
         model: AffordabilityModel,
         displayType: AmountDisplayType,
         isPinned: Bool,
         onPinChanged: @escaping (String, Bool) -> Void) {
        self.category = category
        self.model = model
        self.displayType = displayType
        self.isPinned = isPinned
        self._localAssumptions = State(initialValue: category.assumptions)
        self.onPinChanged = onPinChanged
    }
    
    private var displayAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        
        if displayType == .monthly {
            // For monthly categories, just show the monthly cost
            let amount = totalAmount
            return (formatter.string(from: NSNumber(value: amount)) ?? "$0") + "/mo"
        } else {
            // For total categories, show the total purchase price
            let amount = totalAmount
            let formatted = formatter.string(from: NSNumber(value: amount)) ?? "$0"
            return formatted + " total"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header button to toggle inline details
            Button {
                withAnimation {
                    showInlineDetails.toggle()
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
            
            if showInlineDetails {
                VStack(alignment: .leading, spacing: 24) {
                    // Allocation Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ALLOCATION OF SALARY")
                            .sectionHeader()
                        Text(category.formattedAllocation)
                            .font(.system(size: 17))
                            .foregroundColor(Theme.label)
                    }
                    
                    // Monthly Allocation (for total display types)
                    if displayType == .total {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ESTIMATED MONTHLY ALLOCATION")
                                .sectionHeader()
                            Text(formatCurrency(estimatedMonthlyCost))
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
                                        // Update the shared model when an assumption changes.
                                        model.updateAssumptions(for: category.id, assumptions: localAssumptions)
                                    }
                                )
                            }
                        }
                    }
                    
                    // Action Buttons Row
                    HStack(spacing: 12) {
                        // Expand Button
                        Button(action: {
                            showFullScreenDetails = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                Text("Expand")
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
                        
                        // Pin/Unpin Button
                        Button(action: {
                            onPinChanged(category.id, !isPinned)
                        }) {
                            HStack {
                                Image(systemName: isPinned ? "pin.slash.fill" : "pin.fill")
                                Text(isPinned ? "Unpin" : "Pin")
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
                        
                        // Add to Budget Button
                        if !isInBudget {
                            Button(action: { showAddToBudgetConfirmation = true }) {
                                HStack {
                                    Text("Budget")
                                        .font(.system(size: 15, weight: .medium))
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 15))
                                }
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
                        } else {
                            HStack {
                                Text("Added to Budget")
                                Image(systemName: "checkmark.circle.fill")
                            }
                            .font(.system(size: 15))
                            .foregroundColor(Theme.tint)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(Theme.surfaceBackground)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Theme.elevatedBackground)
            }
        }
        .background(
            Group {
                if isPinned {
                    ZStack {
                        Theme.mutedGreen.opacity(0.2)
                        HStack {
                            Rectangle()
                                .fill(Theme.tint)
                                .frame(width: 4)
                            Spacer()
                        }
                    }
                } else {
                    Color.clear
                }
            }
        )
        .animation(.easeInOut, value: isPinned)
        .fullScreenCover(isPresented: $showFullScreenDetails) {
            CategoryDetailModal(
                category: category,
                amount: totalAmount,
                displayType: displayType,
                isPinned: isPinned,
                isPresented: $showFullScreenDetails,
                onAssumptionsChanged: { id, assumptions in
                    model.updateAssumptions(for: id, assumptions: assumptions)
                },
                onPinChanged: onPinChanged
            )
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
        .onReceive(model.$assumptions) { updated in
            if let newAssumptions = updated[category.id] {
                localAssumptions = newAssumptions
            }
        }
    }
    
    // MARK: - Add to Budget Confirmation
    private var addToBudgetConfirmation: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Add to Budget")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    Text("Would you like to add \(category.name) to your budget with the recommended amount?")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 4) {
                    Text("Recommended Monthly Amount")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.secondaryLabel)
                    Text(formatCurrency(displayType == .monthly ? totalAmount : estimatedMonthlyCost))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
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
    
    private func addToBudget() {
        // If monthly, use totalAmount as the monthly cost
        // If total, use the “estimatedMonthlyCost”
        let monthlyAllocation = (displayType == .monthly)
            ? totalAmount
            : estimatedMonthlyCost
        
        budgetModel.toggleCategory(id: category.id)
        budgetModel.updateAllocation(for: category.id, amount: monthlyAllocation)
        
        withAnimation {
            showingAddedToBudget = true
            showAddToBudgetConfirmation = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingAddedToBudget = false
            }
        }
    }
    
    // MARK: - Mortgage Formula for Home
    private func calculateHomeMonthlyCost() -> Double {
        // Parse assumptions
        let dp = getAssumptionValue("Down Payment") ?? 20.0
        let ir = (getAssumptionValue("Interest Rate") ?? 7.0) / 100.0
        let taxRate = (getAssumptionValue("Property Tax Rate") ?? 1.1) / 100.0
        let termYears = Int(getAssumptionValue("Loan Term") ?? 30)
        
        // totalAmount is the total home price we can afford
        let homePrice = totalAmount
        let principal = homePrice * (1 - dp/100.0)
        
        // monthly interest
        let monthlyInterest = ir / 12.0
        let n = Double(termYears * 12)
        guard n > 0, monthlyInterest >= 0 else { return 0 }
        
        // Mortgage factor
        let numerator = monthlyInterest * pow(1 + monthlyInterest, n)
        let denominator = pow(1 + monthlyInterest, n) - 1
        if denominator <= 0 { return 0 }
        let factor = numerator / denominator
        
        // Mortgage payment
        let monthlyMortgage = principal * factor
        
        // Monthly property tax
        let monthlyTax = homePrice * taxRate / 12.0
        
        return monthlyMortgage + monthlyTax
    }
    
    // MARK: - Loan Formula for Car
    private func calculateCarMonthlyCost() -> Double {
        // Parse assumptions
        let dp = getAssumptionValue("Down Payment") ?? 10.0
        let ir = (getAssumptionValue("Interest Rate") ?? 5.0) / 100.0
        let termYears = Int(getAssumptionValue("Loan Term") ?? 5)
        
        // totalAmount is the total car price we can afford
        let carPrice = totalAmount
        let principal = carPrice * (1 - dp/100.0)
        
        let monthlyInterest = ir / 12.0
        let n = Double(termYears * 12)
        guard n > 0, monthlyInterest >= 0 else { return 0 }
        
        let numerator = monthlyInterest * pow(1 + monthlyInterest, n)
        let denominator = pow(1 + monthlyInterest, n) - 1
        if denominator <= 0 { return 0 }
        let factor = numerator / denominator
        
        // Monthly car payment
        return principal * factor
    }
    
    private func getAssumptionValue(_ title: String) -> Double? {
        if let assumption = localAssumptions.first(where: { $0.title == title }),
           let val = Double(assumption.value) {
            return val
        }
        return nil
    }
    
    // MARK: - Budget Check
    private var isInBudget: Bool {
        budgetModel.budgetItems.contains { $0.id == category.id && $0.isActive }
    }
    
    // MARK: - Helpers
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - AssumptionView
struct AssumptionView: View {
    @Binding var assumption: CategoryAssumption
    @FocusState var focusedField: String?
    let onChanged: (CategoryAssumption) -> Void
    
    var body: some View {
        Group {
            switch assumption.inputType {
            case .percentageSlider(let step):
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(assumption.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.label)
                        Spacer()
                        HStack {
                            TextField("", text: $assumption.value)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedField, equals: assumption.id)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                                .frame(width: 60)
                                .toolbar {
                                    ToolbarItemGroup(placement: .keyboard) {
                                        Spacer()
                                        Button("Done") {
                                            focusedField = nil
                                        }
                                    }
                                }
                                .onChange(of: assumption.value) { newValue in
                                    let filtered = newValue.filter { "0123456789.".contains($0) }
                                    if filtered != newValue {
                                        assumption.value = filtered
                                    }
                                    onChanged(assumption)
                                }
                            Text("%")
                                .foregroundColor(Theme.secondaryLabel)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.surfaceBackground)
                        .cornerRadius(8)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(assumption.value) ?? 0 },
                            set: { newValue in
                                assumption.value = String(format: "%.2f", newValue)
                                onChanged(assumption)
                            }
                        ),
                        in: 0...100,
                        step: step
                    )
                    .tint(Theme.tint)
                }
                
            case .yearSlider, .textField, .percentageDistribution:
                // For brevity, handle these as needed
                EmptyView()
            }
        }
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
