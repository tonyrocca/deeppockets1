import SwiftUI

struct TutorialPage {
    let title: String
    let description: String
    let image: String // System icon name
    let mockupName: String? // Optional: Name of image asset to use as mockup
}

struct EnhancedTutorialView: View {
    @Binding var isPresented: Bool
    let monthlyIncome: Double
    @State private var currentPage = 0
    @State private var isLoading = true
    @State private var progress: CGFloat = 0.0
    @State private var currentStep = 0
    @AppStorage("hasSeenAffordabilityTutorial") private var hasSeenTutorial = false
    
    // Duration for the loading animation
    private let loadingDuration: Double = 5.0
    
    // Income information
    private var annualIncome: Double { monthlyIncome * 12 }
    private var incomePercentile: Int {
        // Simplified income percentile calculation
        if annualIncome >= 650000 { return 1 }
        else if annualIncome >= 250000 { return 5 }
        else if annualIncome >= 180000 { return 10 }
        else if annualIncome >= 120000 { return 20 }
        else if annualIncome >= 90000 { return 30 }
        else if annualIncome >= 70000 { return 40 }
        else if annualIncome >= 50000 { return 50 }
        else if annualIncome >= 35000 { return 60 }
        else if annualIncome >= 25000 { return 70 }
        else { return 80 }
    }
    
    // Tutorial pages with explanations and mockup images
    private var pages: [TutorialPage] {
        [
            TutorialPage(
                title: "Welcome to Deep Pockets",
                description: "Your personal finance companion that helps you make smarter spending decisions based on your income and financial goals.",
                image: "dollarsign.circle",
                mockupName: "tutorial-welcome"
            ),
            TutorialPage(
                title: "Discover What You Can Afford",
                description: "Explore how much you can spend on housing, transportation, and other categories with personalized recommendations based on your income.",
                image: "house.fill",
                mockupName: "tutorial-affordability"
            ),
            TutorialPage(
                title: "Interactive Budget Tools",
                description: "Use our specialized calculators to determine if specific purchases fit your budget before you commit to them.",
                image: "chart.pie.fill",
                mockupName: "tutorial-calculator"
            ),
            TutorialPage(
                title: "Customize Your Assumptions",
                description: "Adjust details like down payment percentages, interest rates, and loan terms to see how they affect what you can afford.",
                image: "slider.horizontal.3",
                mockupName: "tutorial-assumptions"
            ),
            TutorialPage(
                title: "Manage Your Budget",
                description: "Create a balanced budget with our smart recommendations that help you track spending and savings goals.",
                image: "creditcard.fill",
                mockupName: "tutorial-budget"
            ),
            TutorialPage(
                title: "Quick Access Tools",
                description: "Use the Ask Me button for instant access to affordability calculators, savings planners, and debt payoff tools.",
                image: "lightbulb.fill",
                mockupName: "tutorial-quicktools"
            )
        ]
    }
    
    // Loading steps with dynamic text
    private let loadingSteps = [
        "Analyzing your income...",
        "Calculating housing affordability...",
        "Estimating transportation budget...",
        "Determining investment potential...",
        "Building your financial profile..."
    ]
    
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
                
                // Inner circle with dollar icon
                Circle()
                    .fill(Theme.surfaceBackground)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.tint)
                    )
            }
            
            // Loading text content
            VStack(spacing: 16) {
                Text("Personalizing Your Experience")
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
                
                // Enhanced income display
                VStack(spacing: 8) {
                    Text(formatCurrency(monthlyIncome) + "/month")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Theme.tint)
                    
                    Text("Annual: " + formatCurrency(annualIncome))
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                    
                    // Income percentile badge
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 12))
                        Text("Top \(incomePercentile)% of US income")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Theme.tint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.tint.opacity(0.15))
                    .cornerRadius(16)
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
            
            Text("Swipe right at any time to view tutorial →")
                .font(.system(size: 14))
                .foregroundColor(Theme.secondaryLabel)
                .padding(.top, 20)
            
            Spacer()
        }
    }
    
    // MARK: - Tutorial Page View
    @ViewBuilder
    private func tutorialPage(for page: TutorialPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: page.image)
                .font(.system(size: 60))
                .foregroundColor(Theme.tint)
                .padding(28)
                .background(
                    Circle()
                        .fill(Theme.surfaceBackground)
                        .overlay(
                            Circle()
                                .stroke(Theme.tint.opacity(0.2), lineWidth: 2)
                        )
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
            
            // UI Mockup (we'll use placeholder for now, but these would be replaced with actual images)
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
                
                // For a real app, you'd use actual images like:
                // Image(page.mockupName ?? "placeholder-mockup")
                //     .resizable()
                //     .aspectRatio(contentMode: .fit)
                //     .cornerRadius(16)
                //     .padding(.horizontal, 50)
                
                // Placeholder content
                generateMockupForPage(page)
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
    
    @ViewBuilder
    private func generateMockupForPage(_ page: TutorialPage) -> some View {
        switch page.title {
            case "Welcome to Deep Pockets":
                welcomeMockup
            case "Discover What You Can Afford":
                affordabilityMockup
            case "Interactive Budget Tools":
                calculatorMockup
            case "Customize Your Assumptions":
                assumptionsMockup
            case "Manage Your Budget":
                budgetMockup
            case "Quick Access Tools":
                quickToolsMockup
            default:
                placeholderMockup(title: page.title)
        }
    }
    
    // MARK: - Mockup Views
    
    private var welcomeMockup: some View {
        VStack {
            Text("Deep Pockets")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                Circle()
                    .fill(Theme.tint)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("$")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading) {
                    Text("Annual Income:")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondaryLabel)
                    Text(formatCurrency(annualIncome))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.leading, 8)
                
                Spacer()
            }
            .padding(16)
            .background(Theme.surfaceBackground.opacity(0.7))
            .cornerRadius(16)
            .padding(.horizontal, 50)
        }
    }
    
    private var affordabilityMockup: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What You Can Afford")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Home card
            HStack {
                Text("🏠")
                    .font(.title2)
                Text("Home")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Spacer()
                Text("$467,000")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.secondaryLabel)
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Car card
            HStack {
                Text("🚗")
                    .font(.title2)
                Text("Car")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                Spacer()
                Text("$32,500")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.secondaryLabel)
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 50)
    }
    
    private var calculatorMockup: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Affordability Calculator")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // House image
            Image(systemName: "house.fill")
                .font(.system(size: 30))
                .foregroundColor(Theme.tint)
                .frame(maxWidth: .infinity)
            
            // Cost field
            HStack {
                Text("Cost:")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.secondaryLabel)
                Spacer()
                Text("$425,000")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 8)
            
            // Result box
            VStack(spacing: 8) {
                Text("You can afford this! 🎉")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Theme.tint)
                Text("$2,240/month")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Theme.tint.opacity(0.15))
            .cornerRadius(12)
        }
        .padding(.horizontal, 50)
    }
    
    private var assumptionsMockup: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Home Purchase")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Assumptions sliders
            VStack(spacing: 10) {
                // Down payment
                VStack(alignment: .leading, spacing: 4) {
                    Text("Down Payment")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondaryLabel)
                    
                    HStack {
                        Capsule()
                            .fill(Theme.tint)
                            .frame(width: 80, height: 6)
                        Capsule()
                            .fill(Theme.surfaceBackground)
                            .frame(height: 6)
                    }
                    
                    Text("20%")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // Interest rate
                VStack(alignment: .leading, spacing: 4) {
                    Text("Interest Rate")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondaryLabel)
                    
                    HStack {
                        Capsule()
                            .fill(Theme.tint)
                            .frame(width: 60, height: 6)
                        Capsule()
                            .fill(Theme.surfaceBackground)
                            .frame(height: 6)
                    }
                    
                    Text("6.5%")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                // Loan term
                VStack(alignment: .leading, spacing: 4) {
                    Text("Loan Term")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondaryLabel)
                    
                    HStack {
                        Capsule()
                            .fill(Theme.tint)
                            .frame(width: 100, height: 6)
                        Capsule()
                            .fill(Theme.surfaceBackground)
                            .frame(height: 6)
                    }
                    
                    Text("30 years")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 50)
    }
    
    private var budgetMockup: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Monthly Budget")
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
                    Text("$1,250")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Theme.tint)
                }
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Budget categories
            VStack(spacing: 0) {
                budgetCategory(emoji: "🏠", name: "Housing", amount: "$2,400")
                
                Divider()
                    .background(Theme.separator)
                
                budgetCategory(emoji: "🚗", name: "Transportation", amount: "$650")
                
                Divider()
                    .background(Theme.separator)
                
                budgetCategory(emoji: "🛒", name: "Groceries", amount: "$850")
            }
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 50)
    }
    
    private var quickToolsMockup: some View {
        VStack(spacing: 20) {
            Text("Quick Tools")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Floating button in corner
            HStack {
                Spacer()
                
                // Actual button
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Ask me")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.tint)
                .clipShape(Capsule())
                .shadow(color: Theme.tint.opacity(0.4), radius: 6, x: 0, y: 3)
            }
            
            // Menu options
            VStack(spacing: 12) {
                menuItem(icon: "cart.fill", title: "What can I afford?")
                menuItem(icon: "banknote.fill", title: "How can I save for this?")
                menuItem(icon: "creditcard.fill", title: "Can I pay this debt?")
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(16)
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
    
    private func menuItem(icon: String, title: String) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Theme.tint.opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.tint)
                )
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
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

// Animation effect for pulsating circle
struct PulsateEffect: ViewModifier {
    @State private var isPulsating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsating ? 1.1 : 1.0)
            .opacity(isPulsating ? 0.8 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true),
                value: isPulsating
            )
            .onAppear {
                isPulsating = true
            }
    }
}

#Preview {
    EnhancedTutorialView(
        isPresented: .constant(true),
        monthlyIncome: 9750
    )
    .preferredColorScheme(.dark)
}
