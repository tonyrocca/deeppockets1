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
            // Main Content
            VStack(spacing: 0) {
                TabHeaderView(selectedTab: $selectedTab)
                    .ignoresSafeArea(edges: .top)
                
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
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
            Section(header: budgetHeader) {
                BudgetView(monthlyIncome: model.monthlyIncome)
            }
        }
    }
    
    private var affordabilityHeader: some View {
        StickyIncomeHeader(monthlyIncome: model.monthlyIncome)
            .background(Theme.background)
    }
    
    private var budgetHeader: some View {
        BudgetHeader(monthlyIncome: model.monthlyIncome, payPeriod: payPeriod)
            .background(Theme.background)
    }
    
    // MARK: - Overlay Content
    @ViewBuilder
    private var overlayContent: some View {
        if !showAffordabilityCalculator && !showSavingsCalculator {
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
                    isShowing: $showActionMenu
                )
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
    }
}
