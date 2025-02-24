import SwiftUI

struct BudgetImprovementModal: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var budgetModel: BudgetModel
    
    // Track current impact
    @State private var optimizations: [BudgetOptimization] = []
    @State private var projectedSurplus: Double = 0
    @State private var currentSurplus: Double = 0
    
    var body: some View {
        ZStack {
            Color.black
                .opacity(1)
                .ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header Area
                    ZStack {
                        // Close Button
                        HStack {
                            Spacer()
                            Button(action: { isPresented = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Theme.secondaryLabel)
                            }
                        }
                        
                        // Title Center-aligned
                        Text("Improve Your Budget")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Description
                    Text("Select the improvements you'd like to make to your budget.")
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    
                    ScrollView {
                        VStack(spacing: 32) {
                            // Budget Status
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
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            
                            // Optimizations List
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
                            .padding(.horizontal, 20)
                            
                            // Spacer at bottom for button
                            Color.clear.frame(height: 100)
                        }
                    }

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
                        .padding(.horizontal, 36)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 36)
                    }
                }
                .background(Theme.background)
                .cornerRadius(20)
                .padding()
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
