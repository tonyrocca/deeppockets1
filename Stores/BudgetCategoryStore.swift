import SwiftUI
import Foundation

class BudgetCategoryStore: ObservableObject {
    static let shared = BudgetCategoryStore()
    
    @Published var categories: [BudgetCategory] = []
    
    private init() {
        self.categories = createCategories()
    }
    
    func category(for id: String) -> BudgetCategory? {
        return categories.first { $0.id == id }
    }
    
    func updateRecommendedAmount(for id: String, amount: Double) {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index].recommendedAmount = amount
        }
    }
}

extension BudgetCategoryStore {
    func createCategories() -> [BudgetCategory] {
        return [
            BudgetCategory(
                            id: "house",
                            name: "House Price",
                            emoji: "🏠",
                            description: "Maximum home price you can afford based on your income and current mortgage rates.",
                            allocationPercentage: 0.20,
                            displayType: .total,
                            assumptions: [
                                CategoryAssumption(title: "Down Payment", value: "20"),
                                CategoryAssumption(title: "Interest Rate", value: "6.5"),
                                CategoryAssumption(title: "Loan Term (Years)", value: "30")
                            ]
                        ),
            
            BudgetCategory(
                id: "rent",
                name: "Rent",
                emoji: "🏢",
                description: "Monthly rental cost for housing if not paying a mortgage.",
                allocationPercentage: 0.20,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Lease Term", value: "12 months typical"),
                    CategoryAssumption(title: "Utilities Included?", value: "Varies by landlord"),
                    CategoryAssumption(title: "Rental Insurance", value: "Recommended, ~0.5% of monthly rent")
                ]
            ),
            
            BudgetCategory(
                id: "car",
                name: "Car",
                emoji: "🚗",
                description: "Monthly car-related expenses: loan/lease payment, insurance, fuel, maintenance.",
                allocationPercentage: 0.10,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Car Payment/Lease", value: "Majority of budget"),
                    CategoryAssumption(title: "Insurance", value: "15-20% of budget"),
                    CategoryAssumption(title: "Fuel & Maintenance", value: "Adjust based on driving habits")
                ]
            ),
            
            BudgetCategory(
                id: "groceries",
                name: "Groceries",
                emoji: "🛒",
                description: "Monthly cost for food and household kitchen staples prepared at home.",
                allocationPercentage: 0.10,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Fresh Produce", value: "40% of budget"),
                    CategoryAssumption(title: "Proteins & Pantry Items", value: "40% of budget"),
                    CategoryAssumption(title: "Snacks & Miscellaneous", value: "20% of budget")
                ]
            ),
            
            BudgetCategory(
                id: "eating_out",
                name: "Eating Out",
                emoji: "🍔",
                description: "Costs for takeout, fast food, cafés, and quick-service meals.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Fast Food/Café", value: "50% of budget"),
                    CategoryAssumption(title: "Takeout/Delivery Fees", value: "30% of budget"),
                    CategoryAssumption(title: "Snacks & Treats", value: "20% of budget")
                ]
            ),
            
            BudgetCategory(
                id: "public_transportation",
                name: "Public Transportation",
                emoji: "🚆",
                description: "Monthly expenses for subway, bus passes, trains, and ride-sharing alternatives.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Monthly Transit Pass", value: "If available, main expense"),
                    CategoryAssumption(title: "Occasional Ride-Share", value: "Backup option"),
                    CategoryAssumption(title: "Bike/Walk Expenses", value: "Minimal or negligible")
                ]
            ),
            
            BudgetCategory(
                id: "emergency_savings",
                name: "Emergency Savings",
                emoji: "🆘",
                description: "Set aside funds to cover unexpected financial emergencies.",
                allocationPercentage: 0.05,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(title: "3-6 Months Coverage", value: "Essential living costs"),
                    CategoryAssumption(title: "High-Yield Account", value: "Keep funds easily accessible"),
                    CategoryAssumption(title: "Liquidity", value: "Immediate withdrawal if needed")
                ]
            ),
            
            BudgetCategory(
                id: "pet",
                name: "Pet",
                emoji: "🐾",
                description: "Monthly costs for pet food, supplies, vet visits, and grooming.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Food & Treats", value: "50% of budget"),
                    CategoryAssumption(title: "Vet Visits & Shots", value: "30% of budget"),
                    CategoryAssumption(title: "Grooming & Accessories", value: "20% of budget")
                ]
            ),
            
            BudgetCategory(
                id: "restaurants",
                name: "Restaurants",
                emoji: "🍽️",
                description: "Dining at full-service restaurants and more formal dining experiences.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Dine-In Meals", value: "70% of budget"),
                    CategoryAssumption(title: "Beverages & Desserts", value: "20% of budget"),
                    CategoryAssumption(title: "Special Occasions", value: "10% of budget")
                ]
            ),
            
            BudgetCategory(
                id: "clothes",
                name: "Clothes",
                emoji: "👕",
                description: "Apparel, shoes, and personal accessories purchased throughout the year.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Basic Wardrobe Updates", value: "60% of budget"),
                    CategoryAssumption(title: "Seasonal Items", value: "30% of budget"),
                    CategoryAssumption(title: "Accessories", value: "10% of budget")
                ]
            ),
            
            BudgetCategory(
                id: "subscriptions",
                name: "Subscriptions",
                emoji: "📱",
                description: "Recurring costs for streaming services, apps, online memberships, and cloud storage.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Streaming Services", value: "40% of budget"),
                    CategoryAssumption(title: "Software/Apps", value: "30% of budget"),
                    CategoryAssumption(title: "Cloud/Storage", value: "30% of budget")
                ]
            ),
            
            BudgetCategory(
                id: "gym",
                name: "Gym",
                emoji: "💪",
                description: "Monthly fitness-related expenses such as gym memberships, classes, and online workouts.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Gym Membership", value: "70% of budget"),
                    CategoryAssumption(title: "Fitness Classes", value: "20% of budget"),
                    CategoryAssumption(title: "Online Programs/Apps", value: "10% of budget")
                ]
            ),
            
            BudgetCategory(
                id: "investments",
                name: "Investments",
                emoji: "📈",
                description: "Non-retirement investments in brokerage accounts, ETFs, stocks, and bonds.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Brokerage Account", value: "Main vehicle for investments"),
                    CategoryAssumption(title: "Diversification", value: "Mix of equities & fixed income"),
                    CategoryAssumption(title: "Long-Term Growth", value: "Focus on long-term horizons")
                ]
            ),
            
            BudgetCategory(
                id: "home_supplies",
                name: "Home Supplies",
                emoji: "🧻",
                description: "Cleaning products, toiletries, paper goods, and other basic household necessities.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Cleaning Products", value: "40% of budget"),
                    CategoryAssumption(title: "Paper Goods", value: "30% of budget"),
                    CategoryAssumption(title: "Toiletries & Misc.", value: "30% of budget")
                ]
            ),
            
            BudgetCategory(
                id: "home_utilities",
                name: "Home Utilities",
                emoji: "💡",
                description: "Essential monthly utilities including electricity, water, gas, internet, and phone.",
                allocationPercentage: 0.08,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Electricity", value: "30% of budget"),
                    CategoryAssumption(title: "Water & Sewage", value: "20% of budget"),
                    CategoryAssumption(title: "Gas", value: "15% of budget"),
                    CategoryAssumption(title: "Internet", value: "20% of budget"),
                    CategoryAssumption(title: "Phone", value: "15% of budget")
                ]
            ),
            
            BudgetCategory(
                id: "college_savings",
                name: "College Savings",
                emoji: "🎓",
                description: "Contributions to a 529 plan or other education savings accounts.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "529 Plan", value: "Tax-advantaged for education"),
                    CategoryAssumption(title: "Start Early", value: "More time to grow investments"),
                    CategoryAssumption(title: "Adjust as Needed", value: "Based on tuition goals")
                ]
            ),
            
            BudgetCategory(
                id: "vacation",
                name: "Vacation",
                emoji: "✈️",
                description: "Annual or periodic travel, including flights, lodging, and activities.",
                allocationPercentage: 0.03,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(title: "Annual Trips", value: "1-2 major trips/year"),
                    CategoryAssumption(title: "Accommodations", value: "Significant portion of budget"),
                    CategoryAssumption(title: "Flights/Transport", value: "Book in advance to save")
                ]
            ),
            
            BudgetCategory(
                id: "tickets",
                name: "Tickets",
                emoji: "🎟️",
                description: "Event tickets, such as concerts, sports games, theater shows, and festivals.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Concerts/Theater", value: "50% of budget"),
                    CategoryAssumption(title: "Sports Events", value: "30% of budget"),
                    CategoryAssumption(title: "Festivals/Fairs", value: "20% of budget")
                ]
            )
        ]
    }
}
