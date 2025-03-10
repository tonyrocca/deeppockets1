import SwiftUI

struct BudgetCompletionTutorialPage {
    let title: String
    let description: String
    let image: String // System icon name
    let backgroundColor: Color
}

struct BudgetCompletionLoading: View {
    @Binding var isPresented: Bool
    let monthlyIncome: Double
    let completedStep: BudgetCompletionStep
    @State private var currentPage = 0
    @State private var isLoading = true
    @State private var progress: CGFloat = 0.0
    @State private var currentStep = 0
    @AppStorage("hasSeenBudgetTutorial") private var hasSeenTutorial = false
    
    // Duration for the loading animation
    private let loadingDuration: Double = 4.0
    
    enum BudgetCompletionStep {
        case smartBudget
        case customBudget
        case debtCategory
        case expenseCategory
        case savingsCategory
    }
    
    // Loading steps with dynamic text based on which step was completed
    private var loadingSteps: [String] {
        switch completedStep {
        case .smartBudget:
            return [
                "Creating your smart budget...",
                "Analyzing income allocation...",
                "Optimizing category distribution...",
                "Finalizing your budget plan..."
            ]
        case .customBudget:
            return [
                "Building your custom budget...",
                "Mapping financial priorities...",
                "Balancing allocations...",
                "Finalizing your budget plan..."
            ]
        case .debtCategory:
            return [
                "Analyzing debt structure...",
                "Calculating payment strategy...",
                "Optimizing interest costs...",
                "Updating your budget plan..."
            ]
        case .expenseCategory:
            return [
                "Adding expense category...",
                "Balancing monthly allocations...",
                "Checking spending ratios...",
                "Updating your budget plan..."
            ]
        case .savingsCategory:
            return [
                "Setting up savings goal...",
                "Calculating target projections...",
                "Optimizing growth potential...",
                "Updating your budget plan..."
            ]
        }
    }
    
    // Tutorial pages with explanations and mockup images
    private var pages: [BudgetCompletionTutorialPage] {
        let basePages = [
            BudgetCompletionTutorialPage(
                title: "Budget Created",
                description: "Your budget is now set up! We've allocated your income across categories based on financial best practices.",
                image: "checkmark.circle.fill",
                backgroundColor: Theme.tint
            ),
            BudgetCompletionTutorialPage(
                title: "Balancing Priorities",
                description: "Your budget balances essential expenses, debt payments, and savings goals to keep your finances healthy.",
                image: "scale.3d",
                backgroundColor: Color.blue
            ),
            BudgetCompletionTutorialPage(
                title: "Track Your Progress",
                description: "Monitor your budget to see how much you have left to spend in each category throughout the month.",
                image: "chart.bar.fill",
                backgroundColor: Color.purple
            ),
            BudgetCompletionTutorialPage(
                title: "Adjust As Needed",
                description: "Your budget is flexible. Use the edit options to adjust allocations as your financial situation changes.",
                image: "slider.horizontal.3",
                backgroundColor: Color.orange
            )
        ]
        
        // Add specific pages based on what was completed
        switch completedStep {
        case .smartBudget:
            let smartBudgetPage = BudgetCompletionTutorialPage(
                title: "Smart Budget Benefits",
                description: "Your smart budget is designed to maximize financial health with minimal effort, giving you time back for what matters.",
                image: "brain.head.profile",
                backgroundColor: Color.green
            )
            return [basePages[0], smartBudgetPage] + Array(basePages[1...])
            
        case .customBudget:
            let customBudgetPage = BudgetCompletionTutorialPage(
                title: "Customized Allocation",
                description: "Your personalized budget reflects your unique priorities and goals, putting you in control of every dollar.",
                image: "person.fill.checkmark",
                backgroundColor: Color.pink
            )
            return [basePages[0], customBudgetPage] + Array(basePages[1...])
            
        case .debtCategory:
            let debtPage = BudgetCompletionTutorialPage(
                title: "Debt Management",
                description: "Your debt payment plan helps you minimize interest costs and work toward financial freedom.",
                image: "creditcard.fill",
                backgroundColor: Color.red
            )
            return [basePages[0], debtPage] + Array(basePages[1...])
            
        case .expenseCategory:
            let expensePage = BudgetCompletionTutorialPage(
                title: "Expense Tracking",
                description: "Categorizing your expenses helps you see where your money goes and identify opportunities to save.",
                image: "cart.fill",
                backgroundColor: Color.yellow
            )
            return [basePages[0], expensePage] + Array(basePages[1...])
            
        case .savingsCategory:
            let savingsPage = BudgetCompletionTutorialPage(
                title: "Building Wealth",
                description: "Your savings categories are the foundation of wealth-building and future financial security.",
                image: "banknote.fill",
                backgroundColor: Color.green
            )
            return [basePages[0], savingsPage] + Array(basePages[1...])
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Theme.background.ignoresSafeArea()
            
            // Tutorial content
            TabView(selection: $currentPage) {
                // First page is always the loading screen
                loadingView
                    .tag(0)
                
                // Remaining pages are tutorial
                ForEach(1..<pages.count + 1, id: \.self) { index in
                    tutorialPage(for: pages[index - 1])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            // Skip button at top right
            VStack {
                HStack {
                    Spacer()
                    if !isLoading || currentPage > 0 {
                        Button("Skip") {
                            withAnimation {
                                isPresented = false
                                hasSeenTutorial = true
                            }
                        }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Theme.tint)
                        .padding()
                    }
                }
                Spacer()
            }
            
            // Continue button at bottom
            VStack {
                Spacer()
                if currentPage > 0 || !isLoading {
                    Button(action: {
                        if currentPage < pages.count {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            withAnimation {
                                isPresented = false
                                hasSeenTutorial = true
                            }
                        }
                    }) {
                        Text(currentPage < pages.count ? "Continue" : "Get Started")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.tint)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
            }
        }
        .onAppear {
            // Start loading animation
            startLoadingSequence()
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated logo with pulsating effect
            ZStack {
                // Outer pulsating circle
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Theme.tint.opacity(0.7), Theme.tint.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 120, height: 120)
                    .modifier(PulsateEffect())
                
                // Inner circle with budget icon
                Circle()
                    .fill(Theme.surfaceBackground)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: getBudgetIcon())
                            .font(.system(size: 48))
                            .foregroundColor(Theme.tint)
                    )
            }
            
            // Loading text content
            VStack(spacing: 16) {
                Text(getCompletionTitle())
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                if currentStep < loadingSteps.count {
                    Text(loadingSteps[currentStep])
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                        .id("step-\(currentStep)") // Force view update when step changes
                }
                
                // Budget completion message
                VStack(spacing: 8) {
                    Text(getCompletionMessage())
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 8)
            }
            
            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.surfaceBackground)
                            .frame(height: 10)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.tint)
                            .frame(width: geometry.size.width * progress, height: 10)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 10)
                .padding(.horizontal, 20)
                
                // Progress text
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
            }
            .frame(width: 250)
            
            Text("Swipe right at any time to view budget tips →")
                .font(.system(size: 14))
                .foregroundColor(Theme.secondaryLabel)
                .padding(.top, 20)
            
            Spacer()
        }
    }
    
    // MARK: - Tutorial Page View
    @ViewBuilder
    private func tutorialPage(for page: BudgetCompletionTutorialPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: page.image)
                .font(.system(size: 60))
                .foregroundColor(.white)
                .padding(28)
                .background(
                    Circle()
                        .fill(page.backgroundColor)
                        .shadow(color: page.backgroundColor.opacity(0.5), radius: 10, x: 0, y: 5)
                )
                .padding(.bottom, 8)
            
            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Text(page.description)
                    .font(.system(size: 17))
                    .foregroundColor(Theme.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Budget visualization mockup
            ZStack {
                // Mockup background with device frame
                RoundedRectangle(cornerRadius: 28)
                    .fill(Theme.surfaceBackground)
                    .frame(height: 240)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                
                // Budget visualization based on the page
                getBudgetMockupForPage(page)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    private func startLoadingSequence() {
        // Start with first step
        progress = 0.0
        currentStep = 0
        isLoading = true
        
        // Step interval
        let stepInterval = loadingDuration / Double(loadingSteps.count)
        
        // Advance through loading steps
        for i in 0..<loadingSteps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * stepInterval)) {
                withAnimation {
                    currentStep = i
                    progress = CGFloat(i + 1) / CGFloat(loadingSteps.count)
                }
            }
        }
        
        // Complete the loading sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + loadingDuration) {
            withAnimation {
                isLoading = false
                progress = 1.0
                
                // Auto-advance to the first tutorial page
                if currentPage == 0 {
                    currentPage = 1
                }
            }
        }
    }
    
    private func getBudgetIcon() -> String {
        switch completedStep {
        case .smartBudget:
            return "chart.pie.fill"
        case .customBudget:
            return "slider.horizontal.3"
        case .debtCategory:
            return "creditcard.fill"
        case .expenseCategory:
            return "cart.fill"
        case .savingsCategory:
            return "banknote.fill"
        }
    }
    
    private func getCompletionTitle() -> String {
        switch completedStep {
        case .smartBudget:
            return "Smart Budget Created"
        case .customBudget:
            return "Custom Budget Created"
        case .debtCategory:
            return "Debt Category Added"
        case .expenseCategory:
            return "Expense Category Added"
        case .savingsCategory:
            return "Savings Goal Added"
        }
    }
    
    private func getCompletionMessage() -> String {
        switch completedStep {
        case .smartBudget:
            return "Your smart budget is optimized for your income level of \(formatCurrency(monthlyIncome))/month."
        case .customBudget:
            return "Your custom budget gives you complete control over your \(formatCurrency(monthlyIncome))/month income."
        case .debtCategory:
            return "Adding debt categories helps you get out of debt faster and save on interest costs."
        case .expenseCategory:
            return "Tracking expenses helps you stay on budget and avoid overspending."
        case .savingsCategory:
            return "Dedicated savings categories help you reach your financial goals."
        }
    }
    
    @ViewBuilder
    private func getBudgetMockupForPage(_ page: BudgetCompletionTutorialPage) -> some View {
        switch page.title {
        case "Budget Created", "Smart Budget Benefits", "Customized Allocation":
            budgetOverviewMockup()
        case "Balancing Priorities":
            budgetAllocationMockup()
        case "Track Your Progress":
            budgetProgressMockup()
        case "Adjust As Needed":
            budgetAdjustmentMockup()
        case "Debt Management":
            debtManagementMockup()
        case "Expense Tracking":
            expenseTrackingMockup()
        case "Building Wealth":
            savingsMockup()
        default:
            placeholderMockup(title: page.title)
        }
    }
    
    // MARK: - Mockup Views
    
    private func budgetOverviewMockup() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Monthly Budget Overview")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Budget summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Income")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondaryLabel)
                    Text(formatCurrency(monthlyIncome))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Remaining")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondaryLabel)
                    Text(formatCurrency(monthlyIncome * 0.1))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.tint)
                }
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Budget categories
            VStack(spacing: 0) {
                budgetCategory(emoji: "🏠", name: "Housing", amount: formatCurrency(monthlyIncome * 0.3))
                
                Divider()
                    .background(Theme.separator)
                
                budgetCategory(emoji: "🚗", name: "Transportation", amount: formatCurrency(monthlyIncome * 0.15))
                
                Divider()
                    .background(Theme.separator)
                
                budgetCategory(emoji: "🛒", name: "Groceries", amount: formatCurrency(monthlyIncome * 0.12))
            }
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 50)
    }
    
    private func budgetAllocationMockup() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Budget Allocation")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Budget allocation chart (simplified)
            VStack(spacing: 12) {
                allocationBar(label: "Housing", percent: 30, color: Color.blue)
                allocationBar(label: "Transportation", percent: 15, color: Color.green)
                allocationBar(label: "Food", percent: 12, color: Color.orange)
                allocationBar(label: "Savings", percent: 20, color: Theme.tint)
                allocationBar(label: "Debt", percent: 15, color: Color.red)
                allocationBar(label: "Other", percent: 8, color: Color.purple)
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 50)
    }
    
    private func budgetProgressMockup() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Monthly Progress")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Calendar progress indicator
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { week in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(week <= 2 ? Theme.tint.opacity(0.8) : Theme.surfaceBackground)
                        .frame(height: 8)
                }
            }
            .padding(.horizontal, 16)
            
            // Spending progress bars
            VStack(spacing: 12) {
                categoryProgress(
                    category: "Housing",
                    spent: monthlyIncome * 0.15,
                    total: monthlyIncome * 0.3,
                    color: Color.blue
                )
                
                categoryProgress(
                    category: "Food",
                    spent: monthlyIncome * 0.08,
                    total: monthlyIncome * 0.12,
                    color: Color.orange
                )
                
                categoryProgress(
                    category: "Transportation",
                    spent: monthlyIncome * 0.1,
                    total: monthlyIncome * 0.15,
                    color: Color.green
                )
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 50)
    }
    
    private func budgetAdjustmentMockup() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Adjust Your Budget")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Adjustment sliders
            VStack(spacing: 16) {
                // Housing slider
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("🏠 Housing")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryLabel)
                        
                        Spacer()
                        
                        Text("30%")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.surfaceBackground)
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: 130, height: 6)
                        
                        // Thumb
                        Circle()
                            .fill(.white)
                            .frame(width: 18, height: 18)
                            .shadow(radius: 2)
                            .offset(x: 130 - 9)
                    }
                }
                
                // Savings slider
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("💰 Savings")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryLabel)
                        
                        Spacer()
                        
                        Text("20%")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.surfaceBackground)
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Theme.tint)
                            .frame(width: 90, height: 6)
                        
                        // Thumb
                        Circle()
                            .fill(.white)
                            .frame(width: 18, height: 18)
                            .shadow(radius: 2)
                            .offset(x: 90 - 9)
                    }
                }
                
                // Entertainment slider
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("🎬 Entertainment")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.secondaryLabel)
                        
                        Spacer()
                        
                        Text("5%")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.surfaceBackground)
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Color.purple)
                            .frame(width: 40, height: 6)
                        
                        // Thumb
                        Circle()
                            .fill(.white)
                            .frame(width: 18, height: 18)
                            .shadow(radius: 2)
                            .offset(x: 40 - 9)
                    }
                }
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 50)
    }
    
    private func debtManagementMockup() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Debt Payoff Plan")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Debt breakdown
            VStack(spacing: 12) {
                // Student Loan
                debtCard(
                    title: "Student Loan",
                    amount: 24000,
                    monthly: 500,
                    progress: 0.35
                )
                
                // Credit Card
                debtCard(
                    title: "Credit Card",
                    amount: 5800,
                    monthly: 350,
                    progress: 0.65
                )
                
                // Car Loan
                debtCard(
                    title: "Car Loan",
                    amount: 18500,
                    monthly: 375,
                    progress: 0.2
                )
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 50)
    }
    
    private func expenseTrackingMockup() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Expense Tracking")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Expense donut chart
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.blue, lineWidth: 18)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0.3, to: 0.45)
                    .stroke(Color.green, lineWidth: 18)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0.45, to: 0.65)
                    .stroke(Color.orange, lineWidth: 18)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0.65, to: 0.8)
                    .stroke(Color.purple, lineWidth: 18)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0.8, to: 0.9)
                    .stroke(Color.red, lineWidth: 18)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .trim(from: 0.9, to: 1.0)
                    .stroke(Theme.tint, lineWidth: 18)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                // Center text
                VStack(spacing: 4) {
                    Text(formatCurrency(monthlyIncome * 0.9))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Spent")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondaryLabel)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            
            // Category legend
            VStack(spacing: 8) {
                legendItem(color: Color.blue, name: "Housing", percent: "30%")
                legendItem(color: Color.green, name: "Transportation", percent: "15%")
                legendItem(color: Color.orange, name: "Food", percent: "20%")
                legendItem(color: Color.purple, name: "Entertainment", percent: "15%")
                legendItem(color: Color.red, name: "Debt", percent: "10%")
                legendItem(color: Theme.tint, name: "Savings", percent: "10%")
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 50)
    }
    
    private func savingsMockup() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Savings Growth")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Savings goals
            VStack(spacing: 12) {
                // Emergency Fund
                savingsGoal(
                    title: "Emergency Fund",
                    current: 4500,
                    target: 15000,
                    progress: 0.3,
                    monthly: 500
                )
                
                // Vacation
                savingsGoal(
                    title: "Vacation",
                    current: 2800,
                    target: 5000,
                    progress: 0.56,
                    monthly: 350
                )
                
                // Retirement
                savingsGoal(
                    title: "Retirement",
                    current: 35000,
                    target: 1000000,
                    progress: 0.035,
                    monthly: 800
                )
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 50)
    }
    
    private func placeholderMockup(title: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.gen3")
                .font(.system(size: 40))
                .foregroundColor(Theme.tint.opacity(0.7))
            
            Text("Example UI for \(title)")
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helper Components
    
    private func budgetCategory(emoji: String, name: String, amount: String) -> some View {
        HStack {
            Text(emoji)
                .font(.title3)
            Text(name)
                .font(.system(size: 16))
                .foregroundColor(.white)
            Spacer()
            Text(amount)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.secondaryLabel)
        }
        .padding()
    }
    
    private func allocationBar(label: String, percent: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
                Spacer()
                Text("\(percent)%")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    Capsule()
                        .fill(Theme.elevatedBackground)
                        .frame(height: 12)
                    
                    // Filled bar
                    Capsule()
                        .fill(color)
                        .frame(width: (geometry.size.width * CGFloat(percent) / 100), height: 12)
                }
            }
            .frame(height: 12)
        }
    }
    
    private func categoryProgress(category: String, spent: Double, total: Double, color: Color) -> some View {
        let percent = Int(min(100, (spent / total) * 100))
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(category)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
                Spacer()
                Text("\(formatCurrency(spent)) of \(formatCurrency(total))")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    Capsule()
                        .fill(Theme.elevatedBackground)
                        .frame(height: 10)
                    
                    // Filled bar
                    Capsule()
                        .fill(color)
                        .frame(width: (geometry.size.width * CGFloat(percent) / 100), height: 10)
                }
            }
            .frame(height: 10)
        }
    }
    
    private func debtCard(title: String, amount: Double, monthly: Double, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Spacer()
                Text(formatCurrency(amount))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            HStack {
                Text("Monthly payment:")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
                Spacer()
                Text(formatCurrency(monthly))
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    Capsule()
                        .fill(Theme.elevatedBackground)
                        .frame(height: 8)
                    
                    // Filled bar
                    Capsule()
                        .fill(Color.red)
                        .frame(width: (geometry.size.width * progress), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
    
    private func savingsGoal(title: String, current: Double, target: Double, progress: Double, monthly: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Spacer()
                Text("\(formatCurrency(current)) / \(formatCurrency(target))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            HStack {
                Text("Monthly contribution:")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
                Spacer()
                Text(formatCurrency(monthly))
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background bar
                    Capsule()
                        .fill(Theme.elevatedBackground)
                        .frame(height: 8)
                    
                    // Filled bar
                    Capsule()
                        .fill(Theme.tint)
                        .frame(width: (geometry.size.width * progress), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
    
    private func legendItem(color: Color, name: String, percent: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(percent)
                .font(.system(size: 14))
                .foregroundColor(Theme.secondaryLabel)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
