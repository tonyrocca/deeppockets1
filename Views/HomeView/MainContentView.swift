import SwiftUI

// MARK: - MainContentView
struct MainContentView: View {
    @StateObject private var model: AffordabilityModel
    @StateObject private var budgetModel: BudgetModel
    @StateObject private var userModel = UserModel() // Added this line
    @State private var selectedTab = 0
    @State private var showActionMenu = false
    @State private var showAffordabilityCalculator = false
    @State private var showSavingsCalculator = false
    @State private var showDebtCalculator = false
    @State private var showProfile = false
    @Environment(\.dismiss) private var dismiss
    @State private var payPeriod: PayPeriod

    // Instead of a transient GestureState, we use a persistent state for the drag offset.
    @State private var currentDragOffset: CGFloat = 0

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
            // A transparent background that dismisses the keyboard when tapped.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(spacing: 0) {
                // Tab Header
                TabHeaderView(selectedTab: $selectedTab)
                
                // Main Content with Gesture Support
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Page 1: Affordability
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                AffordabilityView(
                                    model: model,
                                    payPeriod: payPeriod
                                )
                                .environmentObject(budgetModel)
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
                    .offset(x: -CGFloat(selectedTab) * geometry.size.width + currentDragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Only update horizontal offset if horizontal drag is dominant.
                                if abs(value.translation.width) > abs(value.translation.height) {
                                    currentDragOffset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                if abs(value.translation.width) > abs(value.translation.height) {
                                    // Calculate a combined translation with a fraction of the predicted end.
                                    let combinedTranslation = value.translation.width + value.predictedEndTranslation.width * 0.1
                                    let threshold: CGFloat = geometry.size.width * 0.3
                                    withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.3)) {
                                        if combinedTranslation < -threshold {
                                            selectedTab = min(selectedTab + 1, 1) // Cap at 1 since we have 2 tabs.
                                        } else if combinedTranslation > threshold {
                                            selectedTab = max(selectedTab - 1, 0)
                                        }
                                        // Animate the drag offset back to zero.
                                        currentDragOffset = 0
                                    }
                                } else {
                                    // If not a dominant horizontal drag, just reset.
                                    withAnimation {
                                        currentDragOffset = 0
                                    }
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
            ProfileView(monthlyIncome: $model.monthlyIncome, payPeriod: $payPeriod)
                .environmentObject(userModel)
        }
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
                monthlyIncome: model.monthlyIncome,
                payPeriod: payPeriod
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
                    monthlyIncome: $model.monthlyIncome,
                    payPeriod: $payPeriod,
                    showProfile: $showProfile, // <-- Pass the binding here
                    isShowing: $showActionMenu
                )
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
    }
}

// MARK: - Extension for Keyboard Dismissal
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MainContentView(monthlyIncome: 5000, payPeriod: .monthly)
    }
    .preferredColorScheme(.dark)
}
