import SwiftUI

struct AffordabilityView: View {
    @ObservedObject var model: AffordabilityModel
    @StateObject private var store = BudgetCategoryStore.shared
    @State private var searchText = ""
    
    var filteredCategories: [BudgetCategory] {
        if searchText.isEmpty {
            return store.categories
        }
        return store.categories.filter { category in
            category.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section(header: StickyIncomeHeader(monthlyIncome: model.monthlyIncome)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What You Can Afford")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.label)
                        Text("This is what you can afford based on your income")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                        
                        // Search Bar
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Theme.secondaryLabel)
                                TextField("Search categories", text: $searchText)
                                    .font(.system(size: 17))
                                    .foregroundColor(Theme.label)
                                    .tint(Theme.tint)
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Theme.secondaryLabel)
                                    }
                                }
                            }
                            .padding(12)
                            .background(Theme.elevatedBackground)
                            .cornerRadius(12)
                        }
                        .padding(.top, 16)
                            
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
                                        displayType: category.displayType
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
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CategoryRowView: View {
    let category: BudgetCategory
    let amount: Double
    let displayType: AmountDisplayType
    @State private var showDetails = false
    
    var displayAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        
        let value = displayType == .monthly ? amount : amount * 12
        let formattedAmount = formatter.string(from: NSNumber(value: value)) ?? "$0"
        return formattedAmount + (displayType == .monthly ? "/mo" : " total")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.mutedGreen.opacity(0.2))
                            .cornerRadius(4)
                        
                        Text(category.formattedAllocation)
                            .font(.system(size: 17))
                            .foregroundColor(Theme.label)
                    }
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("DESCRIPTION")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.tint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.mutedGreen.opacity(0.2))
                            .cornerRadius(4)
                        
                        Text(category.description)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Assumptions Section
                    if !category.assumptions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ASSUMPTIONS")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Theme.tint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Theme.mutedGreen.opacity(0.2))
                                .cornerRadius(4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(category.assumptions, id: \.title) { assumption in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .foregroundColor(Theme.tint)
                                        Text("\(assumption.title):")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Theme.label)
                                        Text(assumption.value)
                                            .font(.system(size: 15))
                                            .foregroundColor(Theme.secondaryLabel)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Theme.elevatedBackground)
            }
        }
    }
}
