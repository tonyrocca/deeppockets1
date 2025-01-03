import SwiftUI

struct MainContentView: View {
    @StateObject private var model: AffordabilityModel
    @State private var selectedTab = 0
    @State private var showActionMenu = false
    @State private var showAffordabilityCalculator = false
    @State private var showSavingsCalculator = false
    let payPeriod: PayPeriod
    
    init(monthlyIncome: Double, payPeriod: PayPeriod) {
        let model = AffordabilityModel()
        model.monthlyIncome = monthlyIncome
        _model = StateObject(wrappedValue: model)
        self.payPeriod = payPeriod
    }
    
    var body: some View {
        ZStack {
            // Base content
            VStack(spacing: 0) {
                TabHeaderView(selectedTab: $selectedTab)
                    .ignoresSafeArea(edges: .top)
                
                ZStack {
                    Theme.background
                        .ignoresSafeArea()
                    
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            if selectedTab == 0 {
                                // Affordability Tab
                                Section(header:
                                    StickyIncomeHeader(monthlyIncome: model.monthlyIncome)
                                        .background(Theme.background)
                                ) {
                                    AffordabilityView(model: model)
                                }
                            } else {
                                // Budget Tab
                                Section(header:
                                    BudgetHeader(monthlyIncome: model.monthlyIncome, payPeriod: payPeriod)
                                        .background(Theme.background)
                                ) {
                                    BudgetView(monthlyIncome: model.monthlyIncome)
                                }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .blur(radius: showActionMenu ? 3 : 0)
            
            // Action Button and Modals remain the same
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
