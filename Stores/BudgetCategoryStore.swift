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
                    CategoryAssumption(title: "Loan Term", value: "30")
                ]
            ),
            
            BudgetCategory(
                id: "car",
                name: "Car",
                emoji: "🚗",
                description: "Monthly car expenses including loan payment, insurance, fuel, and maintenance.",
                allocationPercentage: 0.10,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Car Payment", value: "60"),
                    CategoryAssumption(title: "Insurance", value: "20"),
                    CategoryAssumption(title: "Fuel & Maintenance", value: "20")
                ]
            ),
            
            BudgetCategory(
                id: "groceries",
                name: "Groceries",
                emoji: "🛒",
                description: "Monthly food and household kitchen staples budget.",
                allocationPercentage: 0.10,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Fresh Foods", value: "40"),
                    CategoryAssumption(title: "Pantry Items", value: "40"),
                    CategoryAssumption(title: "Household", value: "20")
                ]
            ),
            
            BudgetCategory(
                id: "eating_out",
                name: "Quick Bites",
                emoji: "🍔",
                description: "Monthly budget for casual dining, takeout, and quick meals.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Takeout", value: "50"),
                    CategoryAssumption(title: "Coffee & Snacks", value: "30"),
                    CategoryAssumption(title: "Delivery Fees", value: "20")
                ]
            ),
            
            BudgetCategory(
                id: "public_transportation",
                name: "Transit",
                emoji: "🚆",
                description: "Monthly transportation costs including public transit and ride services.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Public Transit", value: "70"),
                    CategoryAssumption(title: "Ride Share", value: "20"),
                    CategoryAssumption(title: "Other", value: "10")
                ]
            ),
            
            BudgetCategory(
                id: "emergency_savings",
                name: "Emergency Fund",
                emoji: "🆘",
                description: "Total emergency fund target based on essential monthly expenses.",
                allocationPercentage: 0.05,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(title: "Months Coverage", value: "6"),
                    CategoryAssumption(title: "Monthly Save", value: "20"),
                    CategoryAssumption(title: "Interest Rate", value: "4.5")
                ]
            ),
            
            BudgetCategory(
                id: "pet",
                name: "Pet Care",
                emoji: "🐾",
                description: "Monthly pet expenses including food, supplies, and healthcare.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Food & Supplies", value: "50"),
                    CategoryAssumption(title: "Vet & Health", value: "30"),
                    CategoryAssumption(title: "Other Care", value: "20")
                ]
            ),
            
            BudgetCategory(
                id: "restaurants",
                name: "Fine Dining",
                emoji: "🍽️",
                description: "Monthly budget for restaurant dining and special occasions.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Dining Out", value: "70"),
                    CategoryAssumption(title: "Special Events", value: "20"),
                    CategoryAssumption(title: "Tips", value: "10")
                ]
            ),
            
            BudgetCategory(
                id: "clothes",
                name: "Clothing",
                emoji: "👕",
                description: "Monthly clothing and accessories budget.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Basics", value: "50"),
                    CategoryAssumption(title: "Seasonal", value: "30"),
                    CategoryAssumption(title: "Accessories", value: "20")
                ]
            ),
            
            BudgetCategory(
                id: "subscriptions",
                name: "Subscriptions",
                emoji: "📱",
                description: "Monthly digital subscriptions and services.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Streaming", value: "40"),
                    CategoryAssumption(title: "Software", value: "35"),
                    CategoryAssumption(title: "Other Services", value: "25")
                ]
            ),
            
            BudgetCategory(
                id: "gym",
                name: "Fitness",
                emoji: "💪",
                description: "Monthly fitness and wellness expenses.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Gym Access", value: "60"),
                    CategoryAssumption(title: "Classes", value: "25"),
                    CategoryAssumption(title: "Equipment", value: "15")
                ]
            ),
            
            BudgetCategory(
                id: "investments",
                name: "Investments",
                emoji: "📈",
                description: "Monthly investment contributions outside of retirement accounts.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Stocks", value: "60"),
                    CategoryAssumption(title: "Bonds", value: "30"),
                    CategoryAssumption(title: "Other Assets", value: "10")
                ]
            ),
            
            BudgetCategory(
                id: "home_supplies",
                name: "Home Supplies",
                emoji: "🧻",
                description: "Monthly household supplies and essentials.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Cleaning", value: "40"),
                    CategoryAssumption(title: "Paper Goods", value: "35"),
                    CategoryAssumption(title: "Other Items", value: "25")
                ]
            ),
            
            BudgetCategory(
                id: "home_utilities",
                name: "Utilities",
                emoji: "💡",
                description: "Monthly home utilities including electricity, water, gas, internet, and phone.",
                allocationPercentage: 0.08,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Electricity", value: "30"),
                    CategoryAssumption(title: "Water & Gas", value: "35"),
                    CategoryAssumption(title: "Internet/Phone", value: "35")
                ]
            ),
            
            BudgetCategory(
                id: "college_savings",
                name: "Education",
                emoji: "🎓",
                description: "Monthly education savings contribution.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Monthly Save", value: "100"),
                    CategoryAssumption(title: "Return Rate", value: "5"),
                    CategoryAssumption(title: "Years to Save", value: "18")
                ]
            ),
            
            BudgetCategory(
                id: "vacation",
                name: "Vacation",
                emoji: "✈️",
                description: "Annual vacation budget including travel, accommodations, and activities.",
                allocationPercentage: 0.03,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(title: "Travel", value: "40"),
                    CategoryAssumption(title: "Lodging", value: "40"),
                    CategoryAssumption(title: "Activities", value: "20")
                ]
            ),
            
            BudgetCategory(
                id: "tickets",
                name: "Entertainment",
                emoji: "🎟️",
                description: "Monthly entertainment and event budget.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(title: "Shows", value: "40"),
                    CategoryAssumption(title: "Sports", value: "35"),
                    CategoryAssumption(title: "Other Events", value: "25")
                ]
            )
        ]
    }
}
