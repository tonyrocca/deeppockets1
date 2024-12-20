import SwiftUI

struct MainContentView: View {
    @StateObject private var model: AffordabilityModel
    @State private var selectedTab = 0
    
    init(monthlyIncome: Double) {
        let model = AffordabilityModel()
        model.monthlyIncome = monthlyIncome
        _model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabHeaderView(selectedTab: $selectedTab)
                .ignoresSafeArea(edges: .top) // Add this
            
            ScrollView {
                if selectedTab == 0 {
                    AffordabilityView(model: model)
                } else {
                    BudgetView()
                }
            }
        }
        .background(Theme.background)
        .navigationBarHidden(true) // Add this
        .navigationBarBackButtonHidden(true)
    }
}
