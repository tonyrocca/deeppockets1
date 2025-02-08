
import SwiftUI
import Foundation

// MARK: - DisplayType Enum
enum DisplayType {
    case monthly
    case total
}

// MARK: - BudgetCategoryStore Class
class BudgetCategoryStore: ObservableObject {
    
    // MARK: - Singleton
    static let shared = BudgetCategoryStore()
    
    // MARK: - Published Properties
    @Published var categories: [BudgetCategory] = []
    
    // MARK: - Init
    private init() {
        self.categories = createCategories()
    }
    
    // MARK: - Public Methods
    func category(for id: String) -> BudgetCategory? {
        return categories.first { $0.id == id }
    }
    
    func updateRecommendedAmount(for id: String, amount: Double) {
        if let index = categories.firstIndex(where: { $0.id == id }) {
            categories[index].recommendedAmount = amount
        }
    }
    
    /// Calculate recommended amounts for all categories based on `monthlyIncome`.
    /// This will call each category's `calculateRecommendedAmount` method in turn.
    func calculateAllRecommendedAmounts(monthlyIncome: Double) {
        for i in 0..<categories.count {
            categories[i].calculateRecommendedAmount(monthlyIncome: monthlyIncome)
        }
    }
    
    // MARK: - Factory Method
    /// Creates the initial array of BudgetCategories.
    /// There are 50 expense/savings categories and 10 debt categories (60 total).
    func createCategories() -> [BudgetCategory] {
        return [
            // -------------------------------
            // Expense & Savings Categories (50)
            // -------------------------------
            // Housing & Shelter
            BudgetCategory(
                id: "home",
                name: "Home",
                emoji: "🏠",
                description: "Total purchase price for a home, including ownership costs like taxes and insurance.",
                allocationPercentage: 0.28,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                        title: "Down Payment",
                        value: "20",
                        inputType: .percentageSlider(step: 1),
                        description: "Percentage paid upfront."
                    ),
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "7.0",
                        inputType: .percentageSlider(step: 0.25),
                        description: "Annual mortgage interest rate."
                    ),
                    CategoryAssumption(
                        title: "Property Tax Rate",
                        value: "1.1",
                        inputType: .percentageSlider(step: 0.1),
                        description: "Annual property tax as % of value."
                    )
                ]
            ),
            BudgetCategory(
                id: "rent",
                name: "Rent",
                emoji: "🏢",
                description: "Monthly rent for your residence.",
                allocationPercentage: 0.30,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Lease Term",
                        value: "12",
                        inputType: .yearSlider(min: 6, max: 24),
                        description: "Length of lease in months."
                    )
                ]
            ),
            BudgetCategory(
                id: "home_maintenance",
                name: "Home Maintenance",
                emoji: "🔨",
                description: "Repairs and upkeep for your home.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: []
            ),
            // Utilities & Bills
            BudgetCategory(
                id: "utilities",
                name: "Utilities",
                emoji: "💡",
                description: "Monthly costs for electricity, water, and gas.",
                allocationPercentage: 0.08,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "internet",
                name: "Internet & Cable",
                emoji: "📶",
                description: "Monthly internet and cable TV expenses.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            // Food & Groceries
            BudgetCategory(
                id: "groceries",
                name: "Groceries",
                emoji: "🛒",
                description: "Monthly food and household essentials.",
                allocationPercentage: 0.12,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "dining",
                name: "Dining Out",
                emoji: "🍽️",
                description: "Expenses for eating out and coffee.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: []
            ),
            // Transportation
            BudgetCategory(
                id: "transportation",
                name: "Transportation",
                emoji: "🚗",
                description: "Costs for public transit, fuel, parking, and tolls.",
                allocationPercentage: 0.07,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "car_maintenance",
                name: "Car Maintenance",
                emoji: "🔧",
                description: "Repairs and routine maintenance for your car.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            // Insurance
            BudgetCategory(
                id: "insurance",
                name: "Insurance",
                emoji: "🛡️",
                description: "Monthly premiums for home, auto, and renters insurance.",
                allocationPercentage: 0.06,
                displayType: .monthly,
                assumptions: []
            ),
            // Personal Expenses
            BudgetCategory(
                id: "personal_care",
                name: "Personal Care",
                emoji: "✨",
                description: "Haircuts, cosmetics, and hygiene products.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "clothing",
                name: "Clothing",
                emoji: "👕",
                description: "Apparel and accessories.",
                allocationPercentage: 0.04,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "entertainment",
                name: "Entertainment",
                emoji: "🎟️",
                description: "Movies, concerts, and events.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "hobbies",
                name: "Hobbies",
                emoji: "🎨",
                description: "Supplies and expenses for hobbies and recreational activities.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "phone_plan",
                name: "Phone & Device",
                emoji: "📱",
                description: "Monthly phone plan and device payments.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "subscriptions",
                name: "Subscriptions",
                emoji: "📺",
                description: "Costs for streaming services and apps.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "fitness",
                name: "Fitness",
                emoji: "💪",
                description: "Gym memberships and fitness classes.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "pet_care",
                name: "Pet Care",
                emoji: "🐾",
                description: "Expenses for pet food, supplies, and vet care.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "ride_sharing",
                name: "Ride Sharing",
                emoji: "🚕",
                description: "Costs for taxis and ride-sharing services.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            // Education & Self-Development
            BudgetCategory(
                id: "education",
                name: "Education",
                emoji: "📚",
                description: "Tuition, books, and supplies for education.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Tuition Cost",
                        value: "5000",
                        inputType: .textField,
                        description: "Monthly tuition cost estimate."
                    )
                ]
            ),
            BudgetCategory(
                id: "personal_development",
                name: "Personal Development",
                emoji: "🎓",
                description: "Expenses for courses and self-improvement.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            // Travel
            BudgetCategory(
                id: "travel",
                name: "Travel",
                emoji: "✈️",
                description: "Budget for short weekend trips.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "vacation",
                name: "Vacation",
                emoji: "🏖️",
                description: "Annual vacation spending.",
                allocationPercentage: 0.03,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                        title: "Destination Type",
                        value: "Domestic",
                        inputType: .textField,
                        description: "Domestic or International"
                    )
                ]
            ),
            // Savings Categories
            BudgetCategory(
                id: "retirement_savings",
                name: "Retirement Savings",
                emoji: "💰",
                description: "Contributions to retirement accounts.",
                allocationPercentage: 0.10,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "shortterm_savings",
                name: "Short-term Savings",
                emoji: "🏦",
                description: "Savings for short-term goals and emergencies.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "investments",
                name: "Investments",
                emoji: "📈",
                description: "Monthly contributions to investment accounts.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Stocks",
                        value: "60",
                        inputType: .percentageSlider(step: 5),
                        description: "Percentage allocation to stocks."
                    ),
                    CategoryAssumption(
                        title: "Bonds",
                        value: "30",
                        inputType: .percentageSlider(step: 5),
                        description: "Percentage allocation to bonds."
                    ),
                    CategoryAssumption(
                        title: "Other Assets",
                        value: "10",
                        inputType: .percentageSlider(step: 5),
                        description: "Percentage allocation to other assets."
                    )
                ]
            ),
            BudgetCategory(
                id: "college_savings",
                name: "College Savings",
                emoji: "🎓",
                description: "Savings for future college expenses.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Years to College",
                        value: "18",
                        inputType: .yearSlider(min: 1, max: 18),
                        description: "Years until college starts."
                    )
                ]
            ),
            BudgetCategory(
                id: "charity",
                name: "Charity",
                emoji: "❤️",
                description: "Donations and charitable contributions.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            // Additional Expense & Savings Categories to reach 50
            BudgetCategory(
                id: "home_insurance",
                name: "Home Insurance",
                emoji: "🏠",
                description: "Insurance premiums for your home or rental.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "renters_insurance",
                name: "Renter's Insurance",
                emoji: "🏢",
                description: "Insurance for renters.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "property_maintenance",
                name: "Property Maintenance",
                emoji: "🔨",
                description: "Costs for repairs and upkeep of your property.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "electricity",
                name: "Electricity",
                emoji: "⚡",
                description: "Monthly electricity bill.",
                allocationPercentage: 0.04,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "water",
                name: "Water & Sewer",
                emoji: "🚰",
                description: "Monthly water and sewer expenses.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "gas_heating",
                name: "Gas & Heating",
                emoji: "🔥",
                description: "Monthly gas and heating costs.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "cable_tv",
                name: "Cable TV",
                emoji: "📺",
                description: "Monthly cable TV subscription.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "internet_expense",
                name: "Internet",
                emoji: "🌐",
                description: "Monthly internet bill.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "coffee",
                name: "Coffee & Snacks",
                emoji: "☕",
                description: "Daily expenses on coffee and snacks.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "alcohol",
                name: "Bars & Nightlife",
                emoji: "🍸",
                description: "Expenses for nightlife and drinks.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "auto_insurance",
                name: "Auto Insurance",
                emoji: "🚘",
                description: "Insurance premiums for your car.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "maintenance_repairs",
                name: "Car Repairs",
                emoji: "🔧",
                description: "Costs for car repairs and maintenance.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "fuel",
                name: "Fuel",
                emoji: "⛽",
                description: "Fuel expenses for your car.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "parking",
                name: "Parking & Tolls",
                emoji: "🅿️",
                description: "Parking fees and toll charges.",
                allocationPercentage: 0.01,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "health_insurance",
                name: "Health Insurance",
                emoji: "💊",
                description: "Monthly health insurance premium.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "medical_expenses",
                name: "Medical Expenses",
                emoji: "🏥",
                description: "Out-of-pocket medical costs.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "haircuts",
                name: "Haircuts & Beauty",
                emoji: "💇‍♀️",
                description: "Grooming and beauty expenses.",
                allocationPercentage: 0.01,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "electronics",
                name: "Electronics & Gadgets",
                emoji: "💻",
                description: "Expenses for tech gadgets and upgrades.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "gifts",
                name: "Gifts & Celebrations",
                emoji: "🎁",
                description: "Spending on gifts and celebrations.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "education_expenses",
                name: "Education Expenses",
                emoji: "📚",
                description: "Tuition, books, and educational supplies.",
                allocationPercentage: 0.04,
                displayType: .monthly,
                assumptions: []
            ),
            BudgetCategory(
                id: "personal_development_expenses",
                name: "Self-Development",
                emoji: "🎓",
                description: "Courses, workshops, and training for self-improvement.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: []
            ),
            // -------------------------------
            // Debt Categories (10)
            // -------------------------------
            BudgetCategory(
                id: "credit_cards",
                name: "Credit Card Debt",
                emoji: "💳",
                description: "Monthly credit card payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "APR",
                        value: "18",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Annual percentage rate"
                    ),
                    CategoryAssumption(
                        title: "Min Payment",
                        value: "2",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Min payment as % of balance"
                    )
                ]
            ),
            BudgetCategory(
                id: "student_loans",
                name: "Student Loan Debt",
                emoji: "🎓",
                description: "Monthly student loan payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "5",
                        inputType: .percentageSlider(step: 0.25),
                        description: "Annual interest rate"
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "10",
                        inputType: .yearSlider(min: 5, max: 20),
                        description: "Term in years"
                    )
                ]
            ),
            BudgetCategory(
                id: "personal_loans",
                name: "Personal Loan Debt",
                emoji: "🏦",
                description: "Monthly personal loan payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "8",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Annual interest rate"
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "5",
                        inputType: .yearSlider(min: 1, max: 10),
                        description: "Term in years"
                    )
                ]
            ),
            BudgetCategory(
                id: "auto_loans",
                name: "Auto Loan Debt",
                emoji: "🚗",
                description: "Monthly auto loan payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "7",
                        inputType: .percentageSlider(step: 0.25),
                        description: "Annual interest rate"
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "5",
                        inputType: .yearSlider(min: 3, max: 7),
                        description: "Term in years"
                    )
                ]
            ),
            BudgetCategory(
                id: "payday_loans",
                name: "Payday Loan Debt",
                emoji: "⏰",
                description: "High-interest short-term payday loans.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "APR",
                        value: "25",
                        inputType: .percentageSlider(step: 1),
                        description: "Annual percentage rate"
                    )
                ]
            ),
            BudgetCategory(
                id: "medical_debt",
                name: "Medical Debt",
                emoji: "🏥",
                description: "Monthly payments on medical bills.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "6",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Annual interest rate"
                    )
                ]
            ),
            BudgetCategory(
                id: "mortgage",
                name: "Mortgage Debt",
                emoji: "🏠",
                description: "Monthly mortgage payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "4",
                        inputType: .percentageSlider(step: 0.25),
                        description: "Annual interest rate"
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "30",
                        inputType: .yearSlider(min: 15, max: 30),
                        description: "Term in years"
                    )
                ]
            ),
            BudgetCategory(
                id: "business_loans",
                name: "Business Loan Debt",
                emoji: "💼",
                description: "Monthly business loan payments.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "9",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Annual interest rate"
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "5",
                        inputType: .yearSlider(min: 1, max: 10),
                        description: "Term in years"
                    )
                ]
            ),
            BudgetCategory(
                id: "consolidation_loans",
                name: "Consolidation Loan Debt",
                emoji: "🔗",
                description: "Monthly payments for consolidated debts.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "7",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Annual interest rate"
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "5",
                        inputType: .yearSlider(min: 1, max: 10),
                        description: "Term in years"
                    )
                ]
            )
        ]
    }
}
