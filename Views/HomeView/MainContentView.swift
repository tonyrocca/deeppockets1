import SwiftUI

// MARK: - MainContentView
struct MainContentView: View {
    @AppStorage("monthlyIncome") var monthlyIncomeStored: Double = 0
    @AppStorage("selectedPayPeriod") var selectedPayPeriodRaw: String = "Monthly"
    
    // Tutorial state - placed in main view
    @AppStorage("hasSeenAffordabilityTutorial") private var hasSeenTutorial = false
    
    // Computed property to get a PayPeriod from the stored raw value.
    private var payPeriodStored: PayPeriod {
        PayPeriod(rawValue: selectedPayPeriodRaw) ?? .monthly
    }
    
    // Computed binding for the pay period that avoids mutable self issues.
    private var payPeriodBinding: Binding<PayPeriod> {
        Binding<PayPeriod>(
            get: { PayPeriod(rawValue: selectedPayPeriodRaw) ?? .monthly },
            set: { newValue in selectedPayPeriodRaw = newValue.rawValue }
        )
    }
    
    // Computed binding for monthly income that also updates AppStorage and models
    private var monthlyIncomeBinding: Binding<Double> {
        Binding<Double>(
            get: { model.monthlyIncome },
            set: { newValue in
                model.monthlyIncome = newValue
                budgetModel.monthlyIncome = newValue
                monthlyIncomeStored = newValue
            }
        )
    }
    
    @StateObject private var model: AffordabilityModel = AffordabilityModel()
    @StateObject private var budgetModel: BudgetModel = BudgetModel(monthlyIncome: 0)
    @StateObject private var userModel = UserModel()
    @State private var selectedTab = 0
    @State private var showActionMenu = false
    @State private var showAffordabilityCalculator = false
    @State private var showSavingsCalculator = false
    @State private var showDebtCalculator = false
    @State private var showProfile = false
    @Environment(\.dismiss) private var dismiss
    @State private var currentDragOffset: CGFloat = 0
    
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
                                AffordabilityView(model: model)
                                    .environmentObject(budgetModel)
                            }
                        }
                        .frame(width: geometry.size.width)
                        
                        // Page 2: Budget
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                BudgetView(monthlyIncome: model.monthlyIncome, payPeriod: payPeriodStored)
                                    .environmentObject(budgetModel)
                            }
                        }
                        .frame(width: geometry.size.width)
                    }
                    .offset(x: -CGFloat(selectedTab) * geometry.size.width + currentDragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if abs(value.translation.width) > abs(value.translation.height) {
                                    currentDragOffset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                if abs(value.translation.width) > abs(value.translation.height) {
                                    let combinedTranslation = value.translation.width + value.predictedEndTranslation.width * 0.1
                                    let threshold: CGFloat = geometry.size.width * 0.3
                                    withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.3)) {
                                        if combinedTranslation < -threshold {
                                            selectedTab = min(selectedTab + 1, 1)
                                        } else if combinedTranslation > threshold {
                                            selectedTab = max(selectedTab - 1, 0)
                                        }
                                        currentDragOffset = 0
                                    }
                                } else {
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
            ProfileView(
                monthlyIncome: monthlyIncomeBinding,
                payPeriod: payPeriodBinding
            )
            .environmentObject(userModel)
        }
        .onAppear {
            // Initialize your models with the persisted monthly income.
            model.monthlyIncome = monthlyIncomeStored
            budgetModel.monthlyIncome = monthlyIncomeStored
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
                payPeriod: payPeriodStored
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
                    monthlyIncome: monthlyIncomeBinding,
                    payPeriod: payPeriodBinding,
                    showProfile: $showProfile,
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
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MainContentView()
    }
    .preferredColorScheme(.dark)
}
