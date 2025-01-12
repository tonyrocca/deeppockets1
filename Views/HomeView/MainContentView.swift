import SwiftUI

struct MainContentView: View {
    @StateObject private var model: AffordabilityModel
    @State private var selectedTab = 0
    @State private var showActionMenu = false
    @State private var showAffordabilityCalculator = false
    @State private var showSavingsCalculator = false
    @State private var showDebtCalculator = false
    let payPeriod: PayPeriod
    
    init(monthlyIncome: Double, payPeriod: PayPeriod) {
        let model = AffordabilityModel()
        model.monthlyIncome = monthlyIncome
        _model = StateObject(wrappedValue: model)
        self.payPeriod = payPeriod
    }
    
    var body: some View {
        ZStack {
            // Main Content
            VStack(spacing: 0) {
                TabHeaderView(selectedTab: $selectedTab)
                
                ScrollView {
                                    LazyVStack(spacing: 0) {  // Removed pinnedViews parameter
                                        mainSection
                                    }
                                }
                                .scrollIndicators(.hidden)
            }
            .blur(radius: showActionMenu ? 3 : 0)
            
            // Overlay Content
            overlayContent
        }
        .background(Theme.background)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
    
    // MARK: - Content Views
    @ViewBuilder
    private var mainSection: some View {
        if selectedTab == 0 {
            Section(header: affordabilityHeader) {
                AffordabilityView(model: model)
            }
        } else {
            BudgetView(monthlyIncome: model.monthlyIncome, payPeriod: payPeriod)
        }
    }
    
    private var affordabilityHeader: some View {
        StickyIncomeHeader(monthlyIncome: model.monthlyIncome)
            .background(Theme.background)
    }
    
    // MARK: - Overlay Content
    @ViewBuilder
    private var overlayContent: some View {
        if !showAffordabilityCalculator && !showSavingsCalculator && !showDebtCalculator {
            actionButton
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
        
        if showDebtCalculator {
            DebtCalculatorModal(
                isPresented: $showDebtCalculator,
                monthlyIncome: model.monthlyIncome
            )
            .zIndex(2)
        }
    }
    
    private var actionButton: some View {
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
                    onDebtTap: {
                        withAnimation {
                            showActionMenu = false
                            showDebtCalculator = true
                        }
                    },
                    isShowing: $showActionMenu
                )
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
    }
}
