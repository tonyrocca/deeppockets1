import SwiftUI

struct MainContentView: View {
    @StateObject private var model: AffordabilityModel
    @State private var selectedTab = 0
    @State private var showActionMenu = false
    
    init(monthlyIncome: Double) {
        let model = AffordabilityModel()
        model.monthlyIncome = monthlyIncome
        _model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        ZStack {
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
            
            ActionButtonMenu(
                onClose: { },
                onAffordabilityTap: {
                    // Handle affordability calculator tap
                },
                onSavingsTap: {
                    // Handle savings calculator tap
                },
                isShowing: $showActionMenu
            )
        }
        .background(Theme.background)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}
