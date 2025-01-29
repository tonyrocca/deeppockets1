import SwiftUI

struct MainContentView: View {
    @StateObject private var model: AffordabilityModel
    @StateObject private var budgetModel: BudgetModel
    @State private var selectedTab = 0
    @State private var showActionMenu = false
    @State private var showAffordabilityCalculator = false
    @State private var showSavingsCalculator = false
    @State private var showDebtCalculator = false
    @Environment(\.dismiss) private var dismiss
    let payPeriod: PayPeriod
    
    init(monthlyIncome: Double, payPeriod: PayPeriod) {
        let model = AffordabilityModel()
        model.monthlyIncome = monthlyIncome
        _model = StateObject(wrappedValue: model)
        
        let budgetModel = BudgetModel(monthlyIncome: monthlyIncome)
        _budgetModel = StateObject(wrappedValue: budgetModel)
        self.payPeriod = payPeriod
    }
    
    var body: some View {
        ZStack {
            // Main Content
            VStack(spacing: 0) {
                // Custom Navigation Bar
                customNavigationBar
                    .padding(.top, 8)
                
                // Tab Header
                TabHeaderView(selectedTab: $selectedTab)
                
                // Main Scrollable Content
                ScrollView {
                    LazyVStack(spacing: 0) {
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
    
    // MARK: - Navigation Bar
    private var customNavigationBar: some View {
        HStack {
            // Back Button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Profile Button
            Button(action: {
                // Profile action placeholder
            }) {
                Circle()
                    .fill(Theme.surfaceBackground)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.secondaryLabel)
                    )
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Content Views
    @ViewBuilder
    private var mainSection: some View {
        if selectedTab == 0 {
            Section(header: affordabilityHeader) {
                AffordabilityView(model: model)
                    .environmentObject(budgetModel)
            }
        } else {
            BudgetView(monthlyIncome: model.monthlyIncome, payPeriod: payPeriod)
                .environmentObject(budgetModel)
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
            .environmentObject(budgetModel)
            .zIndex(2)
        }
        
        if showSavingsCalculator {
            SavingsCalculatorModal(
                isPresented: $showSavingsCalculator,
                monthlyIncome: model.monthlyIncome
            )
            .environmentObject(budgetModel)
            .zIndex(2)
        }
        
        if showDebtCalculator {
            DebtCalculatorModal(
                isPresented: $showDebtCalculator,
                monthlyIncome: model.monthlyIncome
            )
            .environmentObject(budgetModel)
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

// MARK: - Preview
#Preview {
    NavigationStack {
        MainContentView(monthlyIncome: 5000, payPeriod: .monthly)
    }
    .preferredColorScheme(.dark)
}
