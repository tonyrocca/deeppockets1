import SwiftUI

struct ActionButtonMenu: View {
    let onClose: () -> Void
    let onAffordabilityTap: () -> Void
    let onSavingsTap: () -> Void
    let onDebtTap: () -> Void
    @Binding var monthlyIncome: Double
    @Binding var payPeriod: PayPeriod
    @Binding var showProfile: Bool  // <-- Added binding here
    @EnvironmentObject private var userModel: UserModel
    @Binding var isShowing: Bool
        
    private let buttonSize: CGFloat = 66
    private let menuItemSize: CGFloat = 55
    private let menuSpacing: CGFloat = 16.5
    private let menuItemOffset: CGFloat = 82.5
    
    var body: some View {
        ZStack {
            // Dimmed background
            if isShowing {
                Color.black
                    .opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isShowing = false
                            onClose()
                        }
                    }
            }
            
            // Menu Buttons
            VStack {
                Spacer()
                
                if isShowing {
                    // Menu Container
                    VStack(spacing: 12) {
                        // Edit Profile Button
                        menuButton(
                            title: "Edit Profile",
                            icon: "person.fill",
                            description: "Update your personal details",
                            action: {
                                withAnimation {
                                    isShowing = false
                                    showProfile = true  // <-- Set showProfile to true
                                }
                            },
                            customColor: Color.blue.opacity(0.2)
                        )
                        
                        menuButton(
                            title: "What can I afford?",
                            icon: "cart.fill",
                            description: "Can I afford that?",
                            action: onAffordabilityTap
                        )
                        
                        menuButton(
                            title: "Can I pay this debt?",
                            icon: "creditcard.fill",
                            description: "Calculate your debt payments",
                            action: onDebtTap
                        )
                        
                        menuButton(
                            title: "How can I save for this?",
                            icon: "banknote.fill",
                            description: "Plan your savings strategy",
                            action: onSavingsTap
                        )
                    }
                }
                
                // Pill-shaped FAB Button
                // Pill-shaped FAB Button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isShowing.toggle()
                        if !isShowing {
                            onClose()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Ask me")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Theme.tint)
                    .clipShape(Capsule())
                    .shadow(color: Theme.tint.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    private func menuButton(title: String, icon: String, description: String, action: @escaping () -> Void, customColor: Color? = nil) -> some View {
        Button(action: {
            withAnimation {
                isShowing = false
                action()
            }
        }) {
            HStack(spacing: 16) {
                Circle()
                    .fill(customColor ?? Theme.tint.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(customColor != nil ? .blue : Theme.tint)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.secondaryLabel)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.secondaryLabel)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.surfaceBackground.opacity(0.95))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
