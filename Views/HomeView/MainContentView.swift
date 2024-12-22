import SwiftUI

struct MainContentView: View {
    @StateObject private var model: AffordabilityModel
    @State private var selectedTab = 0
    @State private var showActionMenu = false
    @State private var showAffordabilityCalculator = false
    
    init(monthlyIncome: Double) {
        let model = AffordabilityModel()
        model.monthlyIncome = monthlyIncome
        _model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                TabHeaderView(selectedTab: $selectedTab)
                    .ignoresSafeArea(edges: .top)
                
                ScrollView {
                    if selectedTab == 0 {
                        AffordabilityView(model: model)
                    } else {
                        BudgetView()
                    }
                }
            }
            .blur(radius: showActionMenu ? 3 : 0)
            
            if showAffordabilityCalculator {
                AffordabilityCalculatorModal(
                    isPresented: $showAffordabilityCalculator,
                    monthlyIncome: model.monthlyIncome
                )
            }
            
            // Only show ActionButtonMenu if no calculator is showing
            if !showAffordabilityCalculator {
                ActionButtonMenu(
                    onClose: { },
                    onAffordabilityTap: {
                        withAnimation {
                            showActionMenu = false
                            showAffordabilityCalculator = true
                        }
                    },
                    onSavingsTap: {
                        // Handle savings calculator tap
                    },
                    isShowing: $showActionMenu
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 16)
            }
        }
        .background(Theme.background)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}
