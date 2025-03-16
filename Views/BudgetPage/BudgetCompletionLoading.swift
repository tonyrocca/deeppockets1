

import SwiftUI
import Combine // Import for Cancellable

struct BudgetCompletionFlow: View {
    @Binding var isPresented: Bool
    let monthlyIncome: Double
    let completedStep: BudgetCompletionStep
    @AppStorage("hasSeenBudgetTutorial") private var hasSeenTutorial = false
    
    // Loading state with fixed timer
    @State private var loadingProgress: CGFloat = 0.0
    @State private var currentPage = 0
    @State private var isLoadingComplete = false
    @State private var currentLoadingStage = 0
    
    // Timer reference for reliable loading
    @State private var loadingTimer: Timer.TimerPublisher = Timer.publish(every: 0.1, on: .main, in: .common)
    @State private var loadingTimerCancellable: AnyCancellable? = nil
    
    // Set the loading duration and stages
    private let loadingDuration: Double = 3.0
    private let loadingStages = [
        "Building your budget framework...",
        "Calculating optimal allocations...",
        "Finalizing your financial plan..."
    ]
    
    // Just 3 concise tutorial pages
    private let tutorialPages = [
        TutorialPage(
            title: "Budget Created",
            description: "Your budget has been customized based on your monthly income. Categories are balanced for your financial health.",
            image: "checkmark.circle.fill",
            mockupName: nil
        ),
        TutorialPage(
            title: "Edit Your Budget",
            description: "Tap any category to adjust its amount or delete it from your budget.",
            image: "slider.horizontal.3",
            mockupName: nil
        ),
        TutorialPage(
            title: "Add Categories",
            description: "Tap the + button in any section to add new budget categories.",
            image: "plus.circle.fill",
            mockupName: nil
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            Theme.background.ignoresSafeArea()
            
            // Content
            VStack(spacing: 0) {
                // Header with skip button
                HStack {
                    Spacer()
                    if currentPage > 0 || isLoadingComplete {
                        Button("Skip") {
                            withAnimation {
                                isPresented = false
                                hasSeenTutorial = true
                            }
                        }
                        .font(.system(size: 17))
                        .foregroundColor(Theme.tint)
                        .padding()
                    }
                }
                
                // Main content (loading or tutorial)
                if currentPage == 0 && !isLoadingComplete {
                    loadingView
                } else {
                    // Tutorial pages
                    TabView(selection: $currentPage) {
                        ForEach(1...tutorialPages.count, id: \.self) { index in
                            tutorialView(for: tutorialPages[index - 1])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    
                    // Continue button
                    Button(action: {
                        if currentPage < tutorialPages.count {
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
                        Text(currentPage < tutorialPages.count ? "Continue" : "Get Started")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Theme.tint)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            // Start the loading animation
            startLoadingAnimation()
        }
        .onDisappear {
            // Clean up timer when view disappears
            loadingTimerCancellable?.cancel()
        }
    }
    
    // Minimalist loading view
    private var loadingView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Simple budget icon with pulse animation
            Image(systemName: getBudgetIcon())
                .font(.system(size: 70))
                .foregroundColor(Theme.tint)
                .modifier(PulsateEffect())
            
            // Loading text with changing stages
            VStack(spacing: 16) {
                Text(getCompletionTitle())
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                if currentLoadingStage < loadingStages.count {
                    Text(loadingStages[currentLoadingStage])
                        .font(.system(size: 17))
                        .foregroundColor(Theme.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .id("stage-\(currentLoadingStage)") // Force view update when stage changes
                }
            }
            .padding(.horizontal, 40)
            
            // Simple progress bar
            VStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.surfaceBackground)
                            .frame(height: 8)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.tint)
                            .frame(width: geometry.size.width * loadingProgress, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: loadingProgress)
                    }
                }
                .frame(height: 8)
                
                // Progress percentage
                Text("\(Int(loadingProgress * 100))%")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
            }
            .frame(width: 240)
            
            Spacer()
            
            // Continue button appears when loading is complete
            if isLoadingComplete {
                Button(action: {
                    withAnimation {
                        currentPage = 1
                    }
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.tint)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .transition(.opacity)
            }
        }
    }
    
    // Tutorial page view
    private func tutorialView(for page: TutorialPage) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            Image(systemName: page.image)
                .font(.system(size: 70))
                .foregroundColor(Theme.tint)
                .padding(.bottom, 20)
            
            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Description
            Text(page.description)
                .font(.system(size: 17))
                .foregroundColor(Theme.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            // Mockup based on the tutorial page
            tutorialMockup(for: page)
                .padding(.top, 20)
            
            Spacer()
            Spacer()
        }
        .padding(.top, 20)
    }
    
    // Different mockups for each tutorial page
    @ViewBuilder
    private func tutorialMockup(for page: TutorialPage) -> some View {
        switch page.title {
        case "Budget Created":
            budgetCreatedMockup()
        case "Edit Your Budget":
            editBudgetMockup()
        case "Add Categories":
            addCategoryMockup()
        default:
            EmptyView()
        }
    }
    
    // Budget created mockup - simple representation of the budget overview
    private func budgetCreatedMockup() -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Monthly Budget")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatCurrency(monthlyIncome))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.tint)
            }
            .padding(.bottom, 16)
            
            // Top categories
            VStack(spacing: 0) {
                budgetCategoryRow(emoji: "🏠", name: "Housing", amount: formatCurrency(monthlyIncome * 0.3))
                
                Divider().background(Theme.separator)
                
                budgetCategoryRow(emoji: "🚗", name: "Transportation", amount: formatCurrency(monthlyIncome * 0.15))
                
                Divider().background(Theme.separator)
                
                budgetCategoryRow(emoji: "🛒", name: "Groceries", amount: formatCurrency(monthlyIncome * 0.12))
            }
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }
    
    // Edit budget mockup - showing how to edit a category
    private func editBudgetMockup() -> some View {
        VStack(spacing: 16) {
            // Normal category
            HStack {
                Text("🏠").font(.title3)
                Text("Housing").foregroundColor(.white)
                Spacer()
                Text(formatCurrency(monthlyIncome * 0.3)).foregroundColor(.white)
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            
            // Expanded category being edited
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("🚗").font(.title3)
                    Text("Transportation").foregroundColor(.white)
                    Spacer()
                    Text(formatCurrency(monthlyIncome * 0.15)).foregroundColor(.white)
                }
                
                Divider().background(Theme.separator)
                
                // Edit buttons
                HStack(spacing: 12) {
                    // Edit button
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Theme.elevatedBackground)
                    .cornerRadius(8)
                    
                    // Delete button
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Theme.elevatedBackground)
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.tint, lineWidth: 2)
            )
        }
        .padding(.horizontal, 32)
    }
    
    // Add category mockup - showing the add category button and selection
    private func addCategoryMockup() -> some View {
        VStack(spacing: 16) {
            // Section header with + button
            HStack {
                Text("SAVINGS")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Theme.tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.tint.opacity(0.1))
                    .cornerRadius(4)
                
                Spacer()
                
                Circle()
                    .fill(Theme.tint)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            
            // Category selection
            VStack(spacing: 0) {
                // Category row
                HStack {
                    Text("💰").font(.title3)
                    Text("Emergency Fund").foregroundColor(.white)
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundColor(Theme.tint)
                }
                .padding()
                .background(Theme.surfaceBackground.opacity(0.5))
                
                Divider().background(Theme.separator)
                
                // Category row
                HStack {
                    Text("💸").font(.title3)
                    Text("Retirement").foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(Theme.surfaceBackground.opacity(0.5))
                
                Divider().background(Theme.separator)
                
                // Category row
                HStack {
                    Text("✈️").font(.title3)
                    Text("Vacation").foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(Theme.surfaceBackground.opacity(0.5))
            }
            .background(Theme.surfaceBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal, 32)
    }
    
    // Standard budget row
    private func budgetCategoryRow(emoji: String, name: String, amount: String) -> some View {
        HStack {
            Text(emoji).font(.title3)
            Text(name).foregroundColor(.white)
            Spacer()
            Text(amount).foregroundColor(.white)
        }
        .padding()
    }
    
    // Get appropriate icon based on the completion step
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
    
    // Get title based on completion step
    private func getCompletionTitle() -> String {
        switch completedStep {
        case .smartBudget:
            return "Creating Your Smart Budget"
        case .customBudget:
            return "Building Your Custom Budget"
        case .debtCategory:
            return "Adding Debt Category"
        case .expenseCategory:
            return "Adding Expense Category"
        case .savingsCategory:
            return "Setting Up Savings Goal"
        }
    }
    
    // Start loading animation that progresses over the loadingDuration
    private func startLoadingAnimation() {
        // Reset progress
        loadingProgress = 0.0
        currentLoadingStage = 0
        isLoadingComplete = false
        
        // Create a new timer and start it
        loadingTimer = Timer.publish(every: 0.1, on: .main, in: .common)
        loadingTimerCancellable = loadingTimer.connect() as? AnyCancellable
        
        // Set up a fixed timer to actually guarantee progress
        let stageInterval = loadingDuration / Double(loadingStages.count)
        
        // Schedule automatic progression of loading stages
        for i in 0..<loadingStages.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * stageInterval)) {
                withAnimation {
                    currentLoadingStage = i
                    loadingProgress = CGFloat(i + 1) / CGFloat(loadingStages.count)
                }
            }
        }
        
        // Schedule completion after the loading duration
        DispatchQueue.main.asyncAfter(deadline: .now() + loadingDuration) {
            withAnimation {
                loadingProgress = 1.0
                isLoadingComplete = true
                loadingTimerCancellable?.cancel()
            }
        }
    }
    
    // Helper for formatting currency
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}


