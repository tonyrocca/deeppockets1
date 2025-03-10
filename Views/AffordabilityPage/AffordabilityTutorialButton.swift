import SwiftUI

// Simple button to trigger the tutorial from anywhere
struct TutorialButton: View {
    @Binding var showTutorial: Bool
    
    var body: some View {
        Button(action: {
            withAnimation {
                showTutorial = true
            }
        }) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                Text("Show Tutorial")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(Theme.tint)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                Theme.tint.opacity(0.15)
                    .cornerRadius(8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.tint.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// ProfileView section for tutorial reset
struct TutorialHelpSection: View {
    // This action will be provided by the parent view
    let resetTutorialAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HELP & SUPPORT")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.tint)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.mutedGreen.opacity(0.2))
                .cornerRadius(4)
            
            // Show Tutorial Button
            Button(action: resetTutorialAction) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 18))
                    Text("Show Tutorial Again")
                        .font(.system(size: 17))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.secondaryLabel)
                }
                .foregroundColor(.white)
                .padding()
                .background(Theme.surfaceBackground)
                .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack {
        TutorialButton(showTutorial: .constant(false))
            .padding()
        
        TutorialHelpSection(resetTutorialAction: {})
            .padding(.top, 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Theme.background)
    .preferredColorScheme(.dark)
}
