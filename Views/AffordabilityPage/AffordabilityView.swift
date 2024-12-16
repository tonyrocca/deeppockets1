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
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section(header: StickyIncomeHeader(monthlyIncome: model.monthlyIncome)) {
                        headerContent
                        searchBar
                        categoriesList
                    }
                }
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar) // Add this
            .toolbarBackground(.visible, for: .navigationBar)        // Add this
        }
    
    private var headerContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("What You Can Afford")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.label)
            Text("This is what you can afford based on your income")
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    private var searchBar: some View {
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
        .padding(.top, 16)
    }
    
    private var categoriesList: some View {
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
        .padding(.top, 16)
    }
}

struct CategoryRowView: View {
   let category: BudgetCategory
   let amount: Double
   let displayType: AmountDisplayType
   @State private var showDetails = false
   @State private var localAssumptions: [CategoryAssumption]
   let onAssumptionsChanged: (String, [CategoryAssumption]) -> Void
   
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
       
       let value = displayType == .monthly ? amount : amount
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
                   VStack(alignment: .leading, spacing: 12) {
                       Text("ASSUMPTIONS")
                           .font(.system(size: 13, weight: .bold))
                           .foregroundColor(Theme.tint)
                           .padding(.horizontal, 8)
                           .padding(.vertical, 4)
                           .background(Theme.mutedGreen.opacity(0.2))
                           .cornerRadius(4)
                       
                       VStack(spacing: 16) {
                           ForEach(0..<localAssumptions.count, id: \.self) { index in
                               HStack {
                                   Text(localAssumptions[index].title)
                                       .font(.system(size: 15, weight: .medium))
                                       .foregroundColor(Theme.label)
                                   Spacer()
                                   TextField(localAssumptions[index].title, text: Binding(
                                       get: { localAssumptions[index].value },
                                       set: { newValue in
                                           localAssumptions[index].value = newValue
                                           onAssumptionsChanged(category.id, localAssumptions)
                                       }
                                   ))
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
                                   
                                   Text(getUnitLabel(for: localAssumptions[index].title))
                                       .font(.system(size: 15))
                                       .foregroundColor(Theme.secondaryLabel)
                                       .frame(width: 30, alignment: .leading)
                               }
                           }
                       }
                       .padding(.top, 8)
                   }

                   Button(action: {
                       // Add to budget action here
                   }) {
                       Text("Add to Budget")
                           .font(.system(size: 15, weight: .medium))
                           .foregroundColor(.white)
                           .frame(maxWidth: .infinity)
                           .padding()
                           .background(Theme.tint)
                           .cornerRadius(8)
                   }
                   .padding(.top, 24)
               }
               .padding(.horizontal, 20)
               .padding(.vertical, 16)
               .background(Theme.elevatedBackground)
           }
       }
   }
    private func getUnitLabel(for title: String) -> String {
        // Special cases first
        if title == "Loan Term" || title == "Years to Save" {
            return "yr"
        }
        if title == "Months Coverage" {
            return "mo"
        }
        if title.contains("Rate") || title == "Monthly Save" {
            return "%"
        }
        
        // Distribution percentages
        let percentageFields = [
            "Down Payment",
            "Fresh Foods", "Pantry Items", "Household",
            "Car Payment", "Insurance", "Fuel & Maintenance",
            "Takeout", "Coffee & Snacks", "Delivery Fees",
            "Public Transit", "Ride Share", "Other",
            "Food & Supplies", "Vet & Health", "Other Care",
            "Dining Out", "Special Events", "Tips",
            "Basics", "Seasonal", "Accessories",
            "Streaming", "Software", "Other Services",
            "Gym Access", "Classes", "Equipment",
            "Stocks", "Bonds", "Other Assets",
            "Cleaning", "Paper Goods", "Other Items",
            "Electricity", "Water & Gas", "Internet/Phone",
            "Travel", "Lodging", "Activities",
            "Shows", "Sports", "Other Events"
        ]
        
        if percentageFields.contains(title) {
            return "%"
        }
        
        return ""
    }
}
