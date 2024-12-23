// BudgetBuilderModal.swift
import SwiftUI

enum BudgetBuilderStep: Int, CaseIterable {
    case savings = 0
    case expenses = 1
    case debt = 2
    
    var title: String {
        switch self {
        case .savings: return "Savings"
        case .expenses: return "Expenses"
        case .debt: return "Debt"
        }
    }
}

struct BudgetBuilderModal: View {
    @Binding var isPresented: Bool
    @ObservedObject var budgetModel: BudgetModel
    @State private var currentStep = BudgetBuilderStep.savings
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Close Button
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                // Title Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Let's set up your \(currentStep.title.lowercased())")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Theme.label)
                    Text("Choose categories and allocate your monthly budget")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.secondaryLabel)
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                
                // Categories List
                ScrollView {
                    VStack(spacing: 12) {
                        CategorySelectionList(
                            budgetModel: budgetModel,
                            currentStep: currentStep
                        )
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 20)
                }
                
                // Navigation Buttons
                VStack(spacing: 12) {
                    if currentStep != .savings {
                        Button(action: {
                            withAnimation {
                                currentStep = BudgetBuilderStep(
                                    rawValue: currentStep.rawValue - 1
                                ) ?? .savings
                            }
                        }) {
                            Text("Back")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Theme.label)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Theme.surfaceBackground)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button(action: {
                        withAnimation {
                            if currentStep == .debt {
                                isPresented = false
                            } else {
                                currentStep = BudgetBuilderStep(
                                    rawValue: currentStep.rawValue + 1
                                ) ?? .debt
                            }
                        }
                    }) {
                        Text(currentStep == .debt ? "Complete" : "Next")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.tint)
                            .cornerRadius(12)
                    }
                }
                .padding(20)
            }
            .background(Theme.background)
            .cornerRadius(24)
            .padding()
        }
    }
}

struct CategorySelectionList: View {
    @ObservedObject var budgetModel: BudgetModel
    let currentStep: BudgetBuilderStep
    @State private var showingAddCategory = false
    
    private var relevantCategories: [BudgetItem] {
        switch currentStep {
        case .savings:
            return budgetModel.budgetItems.filter { $0.type == .savings }
        case .expenses:
            return budgetModel.budgetItems.filter {
                $0.type == .expense && !isDebtCategory($0.category.id)
            }
        case .debt:
            return budgetModel.budgetItems.filter {
                isDebtCategory($0.category.id)
            }
        }
    }
    
    private func isDebtCategory(_ id: String) -> Bool {
        ["credit_cards", "student_loans", "personal_loans", "car_loan"].contains(id)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(relevantCategories) { item in
                SimplifiedCategoryRow(
                    item: item,
                    budgetModel: budgetModel
                )
            }
            
            Button(action: { showingAddCategory = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Add Custom Category")
                        .font(.system(size: 17))
                }
                .foregroundColor(Theme.tint)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategoryView(budgetModel: budgetModel)
        }
    }
}

