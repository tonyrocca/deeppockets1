import SwiftUI

struct BudgetView: View {
    @StateObject private var budgetModel: BudgetModel
    @State private var showingBuildBudget = false
    @State private var showingAddCategory = false
    
    init(monthlyIncome: Double) {
        _budgetModel = StateObject(wrappedValue: BudgetModel(monthlyIncome: monthlyIncome))
    }
    
    var body: some View {
        Group {
            if budgetModel.budgetItems.contains(where: { $0.isActive }) {
                budgetContent
            } else {
                buildBudgetPrompt
            }
        }
        .sheet(isPresented: $showingBuildBudget) {
            BudgetBuilderModal(isPresented: $showingBuildBudget, budgetModel: budgetModel)
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(budgetModel: budgetModel)
        }
    }
    
    private var budgetContent: some View {
        VStack(spacing: 16) {
            // Unallocated Amount Card
            HStack {
                Text("Unallocated")
                    .font(.system(size: 15))
                    .foregroundColor(Theme.secondaryLabel)
                Spacer()
                Text(formatCurrency(budgetModel.unusedAmount))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(budgetModel.unusedAmount >= 0 ? Theme.tint : .red)
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Categories List
            ScrollView {
                VStack(spacing: 16) {
                    prioritizedCategories
                }
                .padding()
            }
            
            // Add Category Button
            Button(action: { showingAddCategory = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Category")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .background(Theme.tint)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private var prioritizedCategories: some View {
        VStack(spacing: 24) {
            // Debt Categories
            categorySection(
                title: "Debt",
                color: .red,
                items: budgetModel.budgetItems.filter { isDebtCategory($0.category.id) && $0.isActive }
            )
            
            // Essential Expenses
            categorySection(
                title: "Essential Expenses",
                color: Theme.tint,
                items: budgetModel.budgetItems.filter {
                    !isDebtCategory($0.category.id) &&
                    $0.type == .expense &&
                    $0.priority == .essential &&
                    $0.isActive
                }
            )
            
            // Savings
            categorySection(
                title: "Savings",
                color: .blue,
                items: budgetModel.budgetItems.filter {
                    $0.type == .savings && $0.isActive
                }
            )
            
            // Important Expenses
            categorySection(
                title: "Important Expenses",
                color: .orange,
                items: budgetModel.budgetItems.filter {
                    !isDebtCategory($0.category.id) &&
                    $0.type == .expense &&
                    $0.priority == .important &&
                    $0.isActive
                }
            )
            
            // Discretionary Expenses
            categorySection(
                title: "Discretionary",
                color: .purple,
                items: budgetModel.budgetItems.filter {
                    !isDebtCategory($0.category.id) &&
                    $0.type == .expense &&
                    $0.priority == .discretionary &&
                    $0.isActive
                }
            )
        }
    }
    
    private func categorySection(title: String, color: Color, items: [BudgetItem]) -> some View {
        Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.1))
                        .cornerRadius(4)
                    
                    ForEach(items) { item in
                        SimplifiedCategoryRow(item: item, budgetModel: budgetModel)
                    }
                }
            }
        }
    }
    
    private func isDebtCategory(_ id: String) -> Bool {
        ["credit_cards", "student_loans", "personal_loans", "car_loan"].contains(id)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private var buildBudgetPrompt: some View {
        VStack(spacing: 20) {
            Text("Deep Pockets will help you build a budget personalized to you")
                .font(.system(size: 17))
                .foregroundColor(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingBuildBudget = true
            }) {
                Text("Build Budget")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(Theme.tint)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    BudgetView(monthlyIncome: 10000)
        .preferredColorScheme(.dark)
}
