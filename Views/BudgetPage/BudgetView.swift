import SwiftUI

struct BudgetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Your Budget")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Theme.label)
            Text("Track your monthly spending")
                .font(.system(size: 15))
                .foregroundColor(Theme.secondaryLabel)
            
            // Add your budget content here
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
}
