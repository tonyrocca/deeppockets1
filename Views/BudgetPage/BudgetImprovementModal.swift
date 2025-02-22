import SwiftUI  

struct BudgetImprovementModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var budgetModel: BudgetModel
    
    // Track current impact
    @State private var optimizations: [BudgetOptimization] = []
    @State private var projectedSurplus: Double = 0
    @State private var currentSurplus: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Header with Budget Status
                    VStack(spacing: 8) {
                        Text("Current Budget Status")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.secondaryLabel)
                        
                        Text(projectedSurplus >= 0 ? "Budget Surplus" : "Budget Deficit")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(formatCurrency(abs(projectedSurplus)))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(projectedSurplus >= 0 ? Theme.tint : .red)
                        
                        if projectedSurplus != currentSurplus {
                            let impact = projectedSurplus - currentSurplus
                            Text(impact > 0 ? "▲ \(formatCurrency(abs(impact)))" : "▼ \(formatCurrency(abs(impact)))")
                                .font(.system(size: 15))
                                .foregroundColor(impact > 0 ? Theme.tint : .red)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Theme.surfaceBackground)
                    
                    // Description
                    Text("Select the improvements you'd like to make to your budget.")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 16)
                    
                    // Scrollable Optimizations List
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(0..<optimizations.count, id: \.self) { index in
                                VStack(alignment: .leading, spacing: 8) {
                                    Toggle(isOn: Binding(
                                        get: { optimizations[index].isSelected },
                                        set: { newValue in
                                            optimizations[index].isSelected = newValue
                                            updateProjectedSurplus()
                                        }
                                    )) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(optimizations[index].title)
                                                .font(.system(size: 17))
                                                .foregroundColor(.white)
                                            
                                            Text(optimizations[index].reason)
                                                .font(.system(size: 15))
                                                .foregroundColor(Theme.secondaryLabel)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    .tint(Theme.tint)
                                }
                                .padding()
                                .background(Theme.surfaceBackground)
                                
                                if index < optimizations.count - 1 {
                                    Divider()
                                        .background(Theme.separator)
                                }
                            }
                        }
                        .background(Theme.surfaceBackground)
                        .cornerRadius(12)
                    }
                    
                    Spacer()
                        .frame(height: 80) // Space for the button
                }
            }
            .onAppear {
                // Initialize optimizations and surplus when the view appears
                let generatedOptimizations = budgetModel.generateOptimizations()
                
                // Calculate initial surplus
                let totalAllocated = budgetModel.budgetItems
                    .filter { $0.isActive }
                    .reduce(0) { $0 + $1.allocatedAmount }
                let surplus = budgetModel.monthlyIncome - totalAllocated
                
                // Update state
                optimizations = generatedOptimizations
                currentSurplus = surplus
                projectedSurplus = surplus
            }
            .overlay(
                // Fixed Improve Button at Bottom
                VStack {
                    Spacer()
                    Button(action: applyImprovements) {
                        Text("Improve Budget")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                optimizations.contains { $0.isSelected } ? Theme.tint : Theme.surfaceBackground
                            )
                            .cornerRadius(12)
                    }
                    .disabled(!optimizations.contains { $0.isSelected })
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    .background(
                        Theme.background
                            .edgesIgnoringSafeArea(.bottom)
                    )
                }
            )
            .navigationTitle("Improve Your Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.secondaryLabel)
                    }
                }
            }
        }
    }
    
    private func updateProjectedSurplus() {
        var newSurplus = currentSurplus
        
        for optimization in optimizations where optimization.isSelected {
            switch optimization.type {
            case .increase(let categoryId, let amount):
                if let currentItem = budgetModel.budgetItems.first(where: { $0.id == categoryId }) {
                    newSurplus -= (amount - currentItem.allocatedAmount)
                }
                
            case .decrease(let categoryId, let amount):
                if let currentItem = budgetModel.budgetItems.first(where: { $0.id == categoryId }) {
                    newSurplus += (currentItem.allocatedAmount - amount)
                }
                
            case .add(_, let amount):
                newSurplus -= amount
                
            case .remove(let categoryId):
                if let currentItem = budgetModel.budgetItems.first(where: { $0.id == categoryId }) {
                    newSurplus += currentItem.allocatedAmount
                }
            }
        }
        
        projectedSurplus = newSurplus
    }
    
    private func applyImprovements() {
        budgetModel.applyOptimizations(optimizations)
        isPresented = false
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
