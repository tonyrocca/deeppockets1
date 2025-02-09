import SwiftUI

// MARK: - AffordabilityView
import SwiftUI

import SwiftUI

struct AffordabilityView: View {
    @ObservedObject var model: AffordabilityModel
    @StateObject private var store = BudgetCategoryStore.shared
    @State private var searchText = ""
    @State private var pinnedCategories: Set<String> = [] // Existing state for pinned categories
    @State private var selectedPeriod: IncomePeriod = .annual // Existing state for selected income period
    @FocusState private var isSearchFocused: Bool
    let payPeriod: PayPeriod
    
    private var filteredCategories: [BudgetCategory] {
        guard !searchText.isEmpty else { return store.categories }
        return store.categories.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    private var pinnedCategoryList: [BudgetCategory] {
        store.categories.filter { pinnedCategories.contains($0.id) }
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
            // Title Section
            Text("Affordability")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .padding(.top, 4)
                .background(Theme.background)
            Text("Below is what you can afford bassed on your income")
                .font(.system(size: 16))
                .foregroundColor(Theme.secondaryLabel)
            
            // Fixed Search Bar
            searchBar
                .background(Theme.background)
            
            // Scrollable Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Categories List Section
                    VStack(spacing: 16) {
                        // Pinned Categories Section
                        if !pinnedCategories.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("PINNED")
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
                                            amount: model.calculateAffordableAmount(for: category),
                                            displayType: category.displayType,
                                            isPinned: true,
                                            onAssumptionsChanged: model.updateAssumptions,
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
                                        amount: model.calculateAffordableAmount(for: category),
                                        displayType: category.displayType,
                                        isPinned: false,
                                        onAssumptionsChanged: model.updateAssumptions,
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
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
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
            TextField("Find out what you can afford...", text: $searchText)
                .focused($isSearchFocused)
                .font(.system(size: 17))
                .foregroundColor(Theme.label)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .placeholder(when: searchText.isEmpty) {
                    Text("Find out what you can afford...")
                        .foregroundColor(Theme.label.opacity(0.6))
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
        .padding(12)
        .background(Theme.elevatedBackground.shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
import SwiftUI

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

// Preview
#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        VStack(spacing: 24) {
            Text("ASSUMPTIONS")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.tint)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            AssumptionSliderView(
                title: "Down Payment",
                range: 0...100,
                step: 0.01,
                suffix: "%",
                value: .constant("20.00")
            ) { newValue in
                print("Value changed to: \(newValue)")
            }
            
            AssumptionSliderView(
                title: "Interest Rate",
                range: 0...20,
                step: 0.01,
                suffix: "%",
                value: .constant("7.00")
            ) { newValue in
                print("Value changed to: \(newValue)")
            }
            
            AssumptionSliderView(
                title: "Property Tax Rate",
                range: 0...5,
                step: 0.01,
                suffix: "%",
                value: .constant("1.10")
            ) { newValue in
                print("Value changed to: \(newValue)")
            }
        }
        .padding()
    }
}


// MARK: - CategoryRowView (Updated with fullScreenCover for details)
struct CategoryRowView: View {
    let category: BudgetCategory
    let amount: Double
    let displayType: AmountDisplayType
    let isPinned: Bool
    @State private var showInlineDetails = false
    @State private var showFullScreenDetails = false
    @State private var localAssumptions: [CategoryAssumption]
    let onAssumptionsChanged: (String, [CategoryAssumption]) -> Void
    let onPinChanged: (String, Bool) -> Void
    @EnvironmentObject private var budgetModel: BudgetModel
    @State private var showAddToBudgetConfirmation = false
    @State private var showingAddedToBudget = false
    
    init(category: BudgetCategory,
         amount: Double,
         displayType: AmountDisplayType,
         isPinned: Bool,
         onAssumptionsChanged: @escaping (String, [CategoryAssumption]) -> Void,
         onPinChanged: @escaping (String, Bool) -> Void) {
        self.category = category
        self.amount = amount
        self.displayType = displayType
        self.isPinned = isPinned
        self._localAssumptions = State(initialValue: category.assumptions)
        self.onAssumptionsChanged = onAssumptionsChanged
        self.onPinChanged = onPinChanged
    }
    
    private var isInBudget: Bool {
        budgetModel.budgetItems.contains { $0.id == category.id && $0.isActive }
    }
    
    var displayAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "$0"
        return formattedAmount + (displayType == .monthly ? "/mo" : " total")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
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
                    // Create a layered background effect
                    ZStack {
                        // Base layer with slightly stronger opacity
                        Theme.mutedGreen.opacity(0.2)
                        
                        // Left border indicator
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
                amount: amount,
                displayType: displayType,
                isPinned: isPinned,
                isPresented: $showFullScreenDetails,
                onAssumptionsChanged: onAssumptionsChanged,
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
    }
    
    private var addToBudgetConfirmation: some View {
        // Same confirmation overlay as before...
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
