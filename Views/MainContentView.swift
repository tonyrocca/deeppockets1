import SwiftUI

struct MainContentView: View {
    @StateObject private var model: AffordabilityModel
    @State private var selectedTab = 0
    
    // Add initializer to receive initial monthly income
    init(monthlyIncome: Double) {
        let model = AffordabilityModel()
        model.monthlyIncome = monthlyIncome
        _model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabHeaderView(selectedTab: $selectedTab)
                .padding(.top, 1)
                
            ScrollView {
                if selectedTab == 0 {
                    AffordabilityView(model: model)
                } else {
                    BudgetView()
                }
            }
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
    }
}
