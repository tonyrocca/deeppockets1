import SwiftUI

struct MainContentView: View {
    @StateObject private var model: AffordabilityModel
    @State private var selectedTab = 0
    @State private var showActionMenu = false
    @State private var showAffordabilityCalculator = false
    @State private var showSavingsCalculator = false
    
    init(monthlyIncome: Double) {
        let model = AffordabilityModel()
        model.monthlyIncome = monthlyIncome
        _model = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        ZStack {
            // Base content
            VStack(spacing: 0) {
                TabHeaderView(selectedTab: $selectedTab)
                    .ignoresSafeArea(edges: .top)
                
                ScrollView {
                    if selectedTab == 0 {
                        AffordabilityView(model: model)
                            .padding(.top, 4)  // Minimal padding
                    } else {
                        BudgetView()
                            .padding(.top, 4)  // Minimal padding
                    }
                }
            }
            .blur(radius: showActionMenu ? 3 : 0)
            
            // Action Button (middle layer)
            if !showAffordabilityCalculator && !showSavingsCalculator {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ActionButtonMenu(
                            onClose: { },
                            onAffordabilityTap: {
                                withAnimation {
                                    showActionMenu = false
                                    showAffordabilityCalculator = true
                                }
                            },
                            onSavingsTap: {
                                withAnimation {
                                    showActionMenu = false
                                    showSavingsCalculator = true
                                }
                            },
                            isShowing: $showActionMenu
                        )
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            
            // Modals (top layer)
            if showAffordabilityCalculator {
                AffordabilityCalculatorModal(
                    isPresented: $showAffordabilityCalculator,
                    monthlyIncome: model.monthlyIncome
                )
                .zIndex(2)
            }
            
            if showSavingsCalculator {
                SavingsCalculatorModal(
                    isPresented: $showSavingsCalculator,
                    monthlyIncome: model.monthlyIncome
                )
                .zIndex(2)
            }
        }
        .background(Theme.background)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}
