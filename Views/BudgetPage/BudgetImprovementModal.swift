import SwiftUI  

struct BudgetImprovementModal: View {
    @Binding var isPresented: Bool
    @State private var optimizations: [BudgetOptimization]
    @EnvironmentObject private var budgetModel: BudgetModel
    
    init(isPresented: Binding<Bool>, initialOptimizations: [BudgetOptimization]) {
        self._isPresented = isPresented
        self._optimizations = State(initialValue: initialOptimizations)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Description
                        Text("Select the improvements you'd like to make to your budget.")
                            .font(.system(size: 17))
                            .foregroundColor(Theme.secondaryLabel)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                        
                        // Optimizations List
                        VStack(spacing: 1) {
                            ForEach($optimizations) { $optimization in
                                VStack(alignment: .leading, spacing: 8) {
                                    Toggle(isOn: $optimization.isSelected) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(optimization.title)
                                                .font(.system(size: 17))
                                                .foregroundColor(.white)
                                            
                                            Text(optimization.reason)
                                                .font(.system(size: 15))
                                                .foregroundColor(Theme.secondaryLabel)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    .tint(Theme.tint)
                                }
                                .padding()
                                .background(Theme.surfaceBackground)
                                
                                if optimization.id != optimizations.last?.id {
                                    Divider()
                                        .background(Theme.separator)
                                }
                            }
                        }
                        .background(Theme.surfaceBackground)
                        .cornerRadius(12)
                        
                        // Apply Button
                        Button(action: applyImprovements) {
                            Text("Improve Budget")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Theme.tint)
                                .cornerRadius(12)
                        }
                        .disabled(!optimizations.contains { $0.isSelected })
                        .opacity(optimizations.contains { $0.isSelected } ? 1 : 0.6)
                    }
                    .padding()
                }
            }
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
    
    private func applyImprovements() {
        budgetModel.applyOptimizations(optimizations)
        isPresented = false
    }
    
}
