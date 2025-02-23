import SwiftUI

// MARK: - Status Button Components
struct StatusButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    let variant: ButtonVariant
    
    @State private var isPressed = false
    
    enum ButtonVariant {
        case `default`
        case success
        case pinned
        
        var background: Color {
            switch self {
            case .default:
                return Theme.surfaceBackground
            case .success, .pinned:
                return Theme.tint.opacity(0.15)
            }
        }
        
        var foreground: Color {
            switch self {
            case .default:
                return .white
            case .success, .pinned:
                return Theme.tint
            }
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
            action()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                Text(label)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(variant.foreground)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(variant.background)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatusButtonGroup: View {
    let onExpand: () -> Void
    let onPin: () -> Void
    let onAddToBudget: () -> Void
    let isPinned: Bool
    let isInBudget: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            StatusButton(
                icon: "arrow.up.left.and.arrow.down.right",
                label: "Expand",
                action: onExpand,
                variant: .default
            )
            
            StatusButton(
                icon: isPinned ? "pin.fill" : "pin",
                label: isPinned ? "Pinned" : "Pin",
                action: onPin,
                variant: isPinned ? .pinned : .default
            )
            
            Group {
                if isInBudget {
                    StatusButton(
                        icon: "checkmark",
                        label: "Added",
                        action: {},
                        variant: .success
                    )
                } else {
                    StatusButton(
                        icon: "plus",
                        label: "Budget",
                        action: onAddToBudget,
                        variant: .default
                    )
                }
            }
            .transition(
                .opacity
                .combined(with: .scale)
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPinned)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isInBudget)
    }
}

// MARK: - Integration Helper
extension View {
    func withButtonAnimation<V: Equatable>(value: V) -> some View {
        self.animation(.spring(response: 0.3, dampingFraction: 0.8), value: value)
    }
}

// MARK: - Improved Income Header
struct ImprovedIncomeHeader: View {
    @Binding var monthlyIncome: Double
    @Binding var payPeriod: PayPeriod
    @State private var showEditIncome = false
    @State private var isExpanded = false
    
    private var annualIncome: Double {
        monthlyIncome * 12
    }
    
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
    
    private var incomePercentile: Int {
        for (threshold, percentile) in incomePercentiles {
            if annualIncome >= threshold {
                return percentile
            }
        }
        return 80
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.surfaceBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 0) {
                Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Annual After-Tax Income")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Theme.secondaryLabel)
                            
                            Text(formatCurrency(annualIncome))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Theme.label)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Theme.tint)
                            .contentShape(Rectangle())
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                }
                
                if isExpanded {
                    Divider()
                        .background(Theme.separator)
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 16) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Income Percentile")
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.secondaryLabel)
                                
                                Text("Top \(incomePercentile)% of earners in USA")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Theme.label)
                            }
                            
                            Spacer()
                            
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
                        
                        Button(action: { showEditIncome = true }) {
                            HStack {
                                Text("Edit Income")
                                    .font(.system(size: 16, weight: .medium))
                                Image(systemName: "pencil")
                            }
                            .foregroundColor(Theme.tint)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Theme.tint.opacity(0.12))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .sheet(isPresented: $showEditIncome) {
            SalaryInputSheet(monthlyIncome: $monthlyIncome, payPeriod: $payPeriod)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Affordability View
struct AffordabilityView: View {
    @ObservedObject var model: AffordabilityModel
    @StateObject private var store = BudgetCategoryStore.shared
    @State private var searchText = ""
    @State private var pinnedCategories: Set<String> = []
    @State private var selectedPeriod: IncomePeriod = .annual
    @FocusState private var isSearchFocused: Bool
    @State private var payPeriod: PayPeriod = .monthly
    
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
    
    private var pinnedCategoryList: [BudgetCategory] {
        return store.categories.filter { pinnedCategories.contains($0.id) }
            .sorted { $0.priority < $1.priority }
    }
    
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
            ImprovedIncomeHeader(
                monthlyIncome: $model.monthlyIncome,
                payPeriod: $payPeriod
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            searchBar
                .padding(.vertical, 16)
                .background(Theme.background)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    VStack(spacing: 16) {
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
                .onEnded { _ in isSearchFocused = false }
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

// MARK: - Category Row View
struct CategoryRowView: View {
    let category: BudgetCategory
    @ObservedObject var model: AffordabilityModel
    let displayType: AmountDisplayType
    let isPinned: Bool
    @State private var showInlineDetails = false
    @State private var showFullScreenDetails = false
    @State private var localAssumptions: [CategoryAssumption]
    let onPinChanged: (String, Bool) -> Void
    @EnvironmentObject private var budgetModel: BudgetModel
    @State private var showAddToBudgetConfirmation = false
    @State private var showingAddedToBudget = false

    private var totalAmount: Double {
        model.affordabilityAmounts[category.id] ?? model.calculateAffordableAmount(for: category)
    }
    
    private var estimatedMonthlyCost: Double {
        switch category.id {
        case "home":
            return calculateHomeMonthlyCost()
        case "car":
            return calculateCarMonthlyCost()
        default:
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
            let amount = totalAmount
            return (formatter.string(from: NSNumber(value: amount)) ?? "$0") + "/mo"
        } else {
            let amount = totalAmount
            let formatted = formatter.string(from: NSNumber(value: amount)) ?? "$0"
            return formatted + " total"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { showInlineDetails.toggle() }
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ALLOCATION OF SALARY")
                            .sectionHeader()
                        Text(category.formattedAllocation)
                            .font(.system(size: 17))
                            .foregroundColor(Theme.label)
                    }
                    
                    if displayType == .total {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ESTIMATED MONTHLY ALLOCATION")
                                .sectionHeader()
                            Text(formatCurrency(estimatedMonthlyCost))
                                .font(.system(size: 17))
                                .foregroundColor(Theme.label)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DESCRIPTION")
                            .sectionHeader()
                        Text(category.description)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    if !localAssumptions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ASSUMPTIONS")
                                .sectionHeader()
                            
                            ForEach(localAssumptions.indices, id: \.self) { index in
                                AssumptionView(
                                    assumption: $localAssumptions[index],
                                    onChanged: { _ in
                                        model.updateAssumptions(for: category.id, assumptions: localAssumptions)
                                    }
                                )
                            }
                        }
                    }
                    
                    // New status buttons using StatusButtonGroup
                    StatusButtonGroup(
                        onExpand: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showFullScreenDetails = true
                            }
                        },
                        onPin: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                onPinChanged(category.id, !isPinned)
                            }
                        },
                        onAddToBudget: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showAddToBudgetConfirmation = true
                            }
                        },
                        isPinned: isPinned,
                        isInBudget: isInBudget
                    )
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
            withAnimation { showingAddedToBudget = false }
        }
    }
    
    private func calculateHomeMonthlyCost() -> Double {
        let dp = getAssumptionValue("Down Payment") ?? 20.0
        let ir = (getAssumptionValue("Interest Rate") ?? 7.0) / 100.0
        let taxRate = (getAssumptionValue("Property Tax Rate") ?? 1.1) / 100.0
        let termYears = Int(getAssumptionValue("Loan Term") ?? 30)
        
        let homePrice = totalAmount
        let principal = homePrice * (1 - dp/100.0)
        let monthlyInterest = ir / 12.0
        let n = Double(termYears * 12)
        guard n > 0, monthlyInterest >= 0 else { return 0 }
        
        let numerator = monthlyInterest * pow(1 + monthlyInterest, n)
        let denominator = pow(1 + monthlyInterest, n) - 1
        if denominator <= 0 { return 0 }
        let factor = numerator / denominator
        
        let monthlyMortgage = principal * factor
        let monthlyTax = homePrice * taxRate / 12.0
        
        return monthlyMortgage + monthlyTax
    }
    
    private func calculateCarMonthlyCost() -> Double {
        let dp = getAssumptionValue("Down Payment") ?? 10.0
        let ir = (getAssumptionValue("Interest Rate") ?? 5.0) / 100.0
        let termYears = Int(getAssumptionValue("Loan Term") ?? 5)
        
        let carPrice = totalAmount
        let principal = carPrice * (1 - dp/100.0)
        
        let monthlyInterest = ir / 12.0
        let n = Double(termYears * 12)
        guard n > 0, monthlyInterest >= 0 else { return 0 }
        
        let numerator = monthlyInterest * pow(1 + monthlyInterest, n)
        let denominator = pow(1 + monthlyInterest, n) - 1
        if denominator <= 0 { return 0 }
        let factor = numerator / denominator
        
        return principal * factor
    }
    
    private func getAssumptionValue(_ title: String) -> Double? {
        if let assumption = localAssumptions.first(where: { $0.title == title }),
           let val = Double(assumption.value) {
            return val
        }
        return nil
    }
    
    private var isInBudget: Bool {
        budgetModel.budgetItems.contains { $0.id == category.id && $0.isActive }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Assumption View
struct AssumptionView: View {
    @Binding var assumption: CategoryAssumption
    @FocusState private var isFocused: Bool
    let onChanged: (CategoryAssumption) -> Void
    
    @State private var localValue: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(assumption.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.label)
            
            if let description = assumption.description {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.secondaryLabel)
                    .padding(.bottom, 2)
            }
            
            HStack {
                if case .textField = assumption.inputType {
                    Text("$")
                        .foregroundColor(.white)
                }
                
                TextField("", text: $localValue)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .onChange(of: localValue) { newValue in
                        let filtered = newValue.filter { "0123456789.".contains($0) }
                        if filtered != newValue {
                            localValue = filtered
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isFocused = true
                    }
                
                switch assumption.inputType {
                case .percentageSlider:
                    Text("%")
                        .foregroundColor(Theme.secondaryLabel)
                case .yearSlider:
                    Text("yrs")
                        .foregroundColor(Theme.secondaryLabel)
                default:
                    EmptyView()
                }
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(8)
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
        }
        .onAppear {
            localValue = assumption.value
        }
        .onChange(of: isFocused) { newFocus in
            if !newFocus {
                updateAssumption()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    updateAssumption()
                    isFocused = false
                }
            }
        }
    }
    
    private func updateAssumption() {
        let finalValue = localValue.isEmpty ? assumption.value : localValue
        assumption.value = finalValue
        localValue = finalValue
        onChanged(assumption)
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

// MARK: - Content Example
struct ContentExample: View {
    @State private var monthlyIncome: Double = 9750 // $117,000 annually
    @State private var payPeriod: PayPeriod = .monthly
    
    var body: some View {
        VStack {
            ImprovedIncomeHeader(
                monthlyIncome: $monthlyIncome,
                payPeriod: $payPeriod
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
}
