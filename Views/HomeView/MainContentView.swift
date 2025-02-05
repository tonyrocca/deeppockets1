import SwiftUI

struct MainContentView: View {
    @StateObject private var model: AffordabilityModel
    @StateObject private var budgetModel: BudgetModel
    @StateObject private var userModel = UserModel() // Add this line
    @State private var selectedTab = 0
    @State private var showActionMenu = false
    @State private var showAffordabilityCalculator = false
    @State private var showSavingsCalculator = false
    @State private var showDebtCalculator = false
    @State private var showProfile = false
    @Environment(\.dismiss) private var dismiss
    @State private var payPeriod: PayPeriod
    
    // This gesture state will track the ongoing drag offset for interactive swiping
    @GestureState private var dragOffset: CGFloat = 0
    
    init(monthlyIncome: Double, payPeriod: PayPeriod) {
        let model = AffordabilityModel()
        model.monthlyIncome = monthlyIncome
        _model = StateObject(wrappedValue: model)
        
        let budgetModel = BudgetModel(monthlyIncome: monthlyIncome)
        _budgetModel = StateObject(wrappedValue: budgetModel)
        _payPeriod = State(initialValue: payPeriod)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Custom Navigation Bar
                customNavigationBar
                    .padding(.top, 8)
                
                // Tab Header
                TabHeaderView(selectedTab: $selectedTab)
                
                // Main Content with Gesture Support
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Page 1: Affordability
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                Section(header: affordabilityHeader) {
                                    AffordabilityView(model: model, payPeriod: payPeriod)
                                        .environmentObject(budgetModel)
                                }
                            }
                        }
                        .frame(width: geometry.size.width)
                        
                        // Page 2: Budget
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                BudgetView(monthlyIncome: model.monthlyIncome, payPeriod: payPeriod)
                                    .environmentObject(budgetModel)
                            }
                        }
                        .frame(width: geometry.size.width)
                    }
                    // Calculate the offset from the selected tab plus the interactive drag offset.
                    .offset(x: -CGFloat(selectedTab) * geometry.size.width + dragOffset)
                    // Animate any change to selectedTab smoothly.
                    .animation(.easeOut, value: selectedTab)
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation.width
                            }
                            .onEnded { value in
                                let threshold: CGFloat = geometry.size.width * 0.3
                                if value.translation.width < -threshold {
                                    // Swipe left: move to the next tab if possible.
                                    selectedTab = min(1, selectedTab + 1)
                                } else if value.translation.width > threshold {
                                    // Swipe right: move to the previous tab if possible.
                                    selectedTab = max(0, selectedTab - 1)
                                }
                            }
                    )
                }
                .scrollIndicators(.hidden)
            }
            .blur(radius: showActionMenu ? 3 : 0)
            
            // Overlay Content (modals, action buttons, etc.)
            overlayContent
        }
        .background(Theme.background)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showProfile) {
            ProfileView(
                monthlyIncome: $model.monthlyIncome,
                payPeriod: $payPeriod
            )
            .environmentObject(userModel) // Make sure userModel is passed here
        }
    }
    
    // MARK: - Navigation Bar
    private var customNavigationBar: some View {
        HStack {
            Spacer()
            // Profile Button
            Button(action: { showProfile = true }) {
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
    
    // MARK: - Affordability Header
    private var affordabilityHeader: some View {
        StickyIncomeHeader(monthlyIncome: model.monthlyIncome, payPeriod: payPeriod)
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
