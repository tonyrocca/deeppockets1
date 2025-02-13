import SwiftUI
import Foundation

// MARK: - AmountDisplayType Enum
enum AmountDisplayType {
    case monthly
    case total
}

// MARK: - AssumptionInputType Enum
enum AssumptionInputType {
    case percentageSlider(step: Double)
    case yearSlider(min: Int, max: Int)
    case textField
    case percentageDistribution
}

// MARK: - CategoryAssumption Struct
struct CategoryAssumption: Identifiable {
    let title: String
    var value: String
    let inputType: AssumptionInputType
    let description: String?
    var id: String { title }
}

extension CategoryAssumption {
    var displayValue: String {
        switch inputType {
        case .percentageSlider:
            return value + "%"
        case .yearSlider:
            return value + " years"
        default:
            return value
        }
    }
}

// MARK: - CategoryType Enum
enum CategoryType {
    case housing
    case transportation
    case savings
    case debt
    case utilities
    case food
    case entertainment
    case insurance
    case education
    case personal
    case other
}

// MARK: - BudgetCategory Struct
struct BudgetCategory: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let description: String
    let allocationPercentage: Double
    var recommendedAmount: Double = 0
    let displayType: AmountDisplayType  // Updated: Using AmountDisplayType
    var assumptions: [CategoryAssumption]
    let type: CategoryType
    let priority: Int
    
    // Optional properties
    var savingsGoal: Double?
    var savingsTimeline: Int?
    var debtAmount: Double?
    var debtInterestRate: Double?
    
    var formattedAllocation: String {
        let percentage = allocationPercentage * 100
        return String(format: "%.1f%%", percentage)
    }
}

extension BudgetCategory {
    mutating func calculateRecommendedAmount(monthlyIncome: Double) {
        if displayType == .monthly {
            recommendedAmount = monthlyIncome * allocationPercentage
        } else {
            recommendedAmount = monthlyIncome * allocationPercentage * 12
        }
    }
}

// MARK: - BudgetCategoryStore Class
class BudgetCategoryStore: ObservableObject {
    
    // Singleton instance
    static let shared = BudgetCategoryStore()
    
    // Published list of categories
    @Published var categories: [BudgetCategory] = []
    
    // Private initializer ensures only one instance is created
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
    
    /// Calculates recommended amounts for all categories based on monthlyIncome.
    func calculateAllRecommendedAmounts(monthlyIncome: Double) {
        for i in 0..<categories.count {
            categories[i].calculateRecommendedAmount(monthlyIncome: monthlyIncome)
        }
    }
    
    // MARK: - Factory Method
    /// Creates the initial array of BudgetCategories.
    func createCategories() -> [BudgetCategory] {
        var list: [BudgetCategory] = [
            // -------------------------------
            // Housing & Shelter
            // -------------------------------
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
                ],
                type: .housing,
                priority: 1
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
                ],
                type: .housing,
                priority: 1
            ),
            BudgetCategory(
                id: "home_maintenance",
                name: "Home Maintenance",
                emoji: "🔨",
                description: "Repairs and upkeep for your home.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [],
                type: .housing,
                priority: 3
            ),
            // -------------------------------
            // Transportation
            // -------------------------------
            BudgetCategory(
                id: "car",
                name: "Car",
                emoji: "🚗",
                description: "Total purchase price for a car, including financing costs and fees.",
                allocationPercentage: 0.15,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                        title: "Down Payment",
                        value: "10",
                        inputType: .percentageSlider(step: 1),
                        description: "Percentage paid upfront."
                    ),
                    CategoryAssumption(
                        title: "Interest Rate",
                        value: "5.0",
                        inputType: .percentageSlider(step: 0.25),
                        description: "Annual car loan interest rate."
                    ),
                    CategoryAssumption(
                        title: "Sales Tax Rate",
                        value: "8.0",
                        inputType: .percentageSlider(step: 0.1),
                        description: "Sales tax applied to the purchase price."
                    )
                ],
                type: .transportation,
                priority: 2
            ),
            BudgetCategory(
                id: "car_maintenance",
                name: "Car Maintenance",
                emoji: "🔧",
                description: "Repairs and routine maintenance for your car.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .transportation,
                priority: 4
            ),
            BudgetCategory(
                id: "transportation",
                name: "Transportation",
                emoji: "🚇",
                description: "Costs for public transit, fuel, parking, and tolls.",
                allocationPercentage: 0.07,
                displayType: .monthly,
                assumptions: [],
                type: .transportation,
                priority: 3
            ),
            // -------------------------------
            // Utilities & Bills
            // -------------------------------
            BudgetCategory(
                id: "utilities",
                name: "Utilities",
                emoji: "💡",
                description: "Monthly costs for electricity, water, and gas.",
                allocationPercentage: 0.08,
                displayType: .monthly,
                assumptions: [],
                type: .utilities,
                priority: 2
            ),
            BudgetCategory(
                id: "internet",
                name: "Internet & Cable",
                emoji: "📶",
                description: "Monthly internet and cable TV expenses.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .utilities,
                priority: 3
            ),
            // -------------------------------
            // Food & Groceries
            // -------------------------------
            BudgetCategory(
                id: "groceries",
                name: "Groceries",
                emoji: "🛒",
                description: "Monthly food and household essentials.",
                allocationPercentage: 0.12,
                displayType: .monthly,
                assumptions: [],
                type: .food,
                priority: 1
            ),
            BudgetCategory(
                id: "dining",
                name: "Dining Out",
                emoji: "🍽️",
                description: "Expenses for eating out and coffee.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [],
                type: .food,
                priority: 3
            ),
            // -------------------------------
            // Entertainment
            // -------------------------------
            BudgetCategory(
                id: "entertainment",
                name: "Entertainment",
                emoji: "🎟️",
                description: "Movies, concerts, and events.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .entertainment,
                priority: 4
            ),
            BudgetCategory(
                id: "hobbies",
                name: "Hobbies",
                emoji: "🎨",
                description: "Supplies and expenses for hobbies and recreational activities.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .entertainment,
                priority: 4
            ),
            BudgetCategory(
                id: "subscriptions",
                name: "Subscriptions",
                emoji: "📺",
                description: "Costs for streaming services and apps.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .entertainment,
                priority: 4
            ),
            // -------------------------------
            // Insurance
            // -------------------------------
            BudgetCategory(
                id: "insurance",
                name: "Insurance",
                emoji: "🛡️",
                description: "Monthly premiums for home, auto, and renters insurance.",
                allocationPercentage: 0.06,
                displayType: .monthly,
                assumptions: [],
                type: .insurance,
                priority: 1
            ),
            BudgetCategory(
                id: "health_insurance",
                name: "Health Insurance",
                emoji: "💊",
                description: "Monthly health insurance premium.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [],
                type: .insurance,
                priority: 1
            ),
            BudgetCategory(
                id: "auto_insurance",
                name: "Auto Insurance",
                emoji: "🚘",
                description: "Insurance premiums for your car.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .insurance,
                priority: 2
            ),
            BudgetCategory(
                id: "home_insurance",
                name: "Home Insurance",
                emoji: "🏠",
                description: "Insurance premiums for your home or rental.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .insurance,
                priority: 2
            ),
            // -------------------------------
            // Savings Categories
            // -------------------------------
            BudgetCategory(
                id: "retirement_savings",
                name: "Retirement Savings",
                emoji: "💰",
                description: "Contributions to retirement accounts.",
                allocationPercentage: 0.10,
                displayType: .monthly,
                assumptions: [],
                type: .savings,
                priority: 1
            ),
            BudgetCategory(
                id: "shortterm_savings",
                name: "Short-term Savings",
                emoji: "🏦",
                description: "Savings for short-term goals and emergencies.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [],
                type: .savings,
                priority: 1
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
                ],
                type: .savings,
                priority: 2
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
                ],
                type: .savings,
                priority: 2
            ),
            BudgetCategory(
                id: "charity",
                name: "Charity",
                emoji: "❤️",
                description: "Donations and charitable contributions.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .savings,
                priority: 3
            ),
            // -------------------------------
            // Education
            // -------------------------------
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
                ],
                type: .education,
                priority: 2
            ),
            BudgetCategory(
                id: "personal_development",
                name: "Personal Development",
                emoji: "🎓",
                description: "Expenses for courses and self-improvement.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [],
                type: .education,
                priority: 3
            ),
            // -------------------------------
            // Debt Categories
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
                        description: "Annual percentage rate."
                    ),
                    CategoryAssumption(
                        title: "Min Payment",
                        value: "2",
                        inputType: .percentageSlider(step: 0.5),
                        description: "Minimum payment as % of balance."
                    )
                ],
                type: .debt,
                priority: 1
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
                        description: "Annual interest rate."
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "10",
                        inputType: .yearSlider(min: 5, max: 20),
                        description: "Term in years."
                    )
                ],
                type: .debt,
                priority: 2
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
                        description: "Annual interest rate."
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "5",
                        inputType: .yearSlider(min: 1, max: 10),
                        description: "Term in years."
                    )
                ],
                type: .debt,
                priority: 2
            ),
            BudgetCategory(
                id: "medical_debt",
                name: "Medical Debt",
                emoji: "🏥",
                description: "Monthly payments on medical bills.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [],
                type: .debt,
                priority: 2
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
                        description: "Annual interest rate."
                    ),
                    CategoryAssumption(
                        title: "Loan Term",
                        value: "30",
                        inputType: .yearSlider(min: 15, max: 30),
                        description: "Term in years."
                    )
                ],
                type: .debt,
                priority: 1
            )
        ]
        
        // -------------------------------
        // Additional 25+ Categories (example additions)
        // -------------------------------
        list += [
            BudgetCategory(
                id: "emergency_savings",
                name: "Emergency Savings",
                emoji: "🚨",
                description: "Savings for unexpected emergencies.",
                allocationPercentage: 0.10,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Target Amount",
                        value: "10000",
                        inputType: .textField,
                        description: "Desired emergency fund total."
                    )
                ],
                type: .savings,
                priority: 1
            ),
            BudgetCategory(
                id: "vacation_savings",
                name: "Vacation Savings",
                emoji: "🏖️",
                description: "Savings for vacations and leisure travel.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Target Amount",
                        value: "2000",
                        inputType: .textField,
                        description: "Desired vacation fund total."
                    )
                ],
                type: .savings,
                priority: 4
            ),
            BudgetCategory(
                id: "childcare",
                name: "Childcare",
                emoji: "👶",
                description: "Expenses for childcare or daycare.",
                allocationPercentage: 0.08,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost per Child",
                        value: "800",
                        inputType: .textField,
                        description: "Average monthly cost per child."
                    )
                ],
                type: .other,
                priority: 2
            ),
            BudgetCategory(
                id: "child_education",
                name: "Child Education",
                emoji: "🎒",
                description: "Expenses for school and extracurriculars.",
                allocationPercentage: 0.04,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "300",
                        inputType: .textField,
                        description: "Average monthly education cost."
                    )
                ],
                type: .other,
                priority: 3
            ),
            BudgetCategory(
                id: "pet_care",
                name: "Pet Care",
                emoji: "🐾",
                description: "Expenses for pet food, vet, and supplies.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "150",
                        inputType: .textField,
                        description: "Average monthly pet expense."
                    )
                ],
                type: .other,
                priority: 3
            ),
            BudgetCategory(
                id: "clothing",
                name: "Clothing",
                emoji: "👗",
                description: "Expenses for apparel and accessories.",
                allocationPercentage: 0.04,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "200",
                        inputType: .textField,
                        description: "Average monthly clothing expense."
                    )
                ],
                type: .other,
                priority: 3
            ),
            BudgetCategory(
                id: "personal_care",
                name: "Personal Care",
                emoji: "💄",
                description: "Expenses for grooming, haircuts, and toiletries.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "100",
                        inputType: .textField,
                        description: "Average monthly personal care expense."
                    )
                ],
                type: .other,
                priority: 3
            ),
            BudgetCategory(
                id: "gym_membership",
                name: "Gym Membership",
                emoji: "🏋️‍♀️",
                description: "Cost for fitness club membership.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "50",
                        inputType: .textField,
                        description: "Monthly gym membership fee."
                    )
                ],
                type: .other,
                priority: 4
            ),
            BudgetCategory(
                id: "cell_phone",
                name: "Cell Phone",
                emoji: "📱",
                description: "Monthly cell phone bill.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "70",
                        inputType: .textField,
                        description: "Average monthly cell phone expense."
                    )
                ],
                type: .utilities,
                priority: 2
            ),
            BudgetCategory(
                id: "home_improvement",
                name: "Home Improvement",
                emoji: "🏡",
                description: "Funds for home renovations and upgrades.",
                allocationPercentage: 0.04,
                displayType: .total,
                assumptions: [
                    CategoryAssumption(
                        title: "Renovation Budget",
                        value: "15000",
                        inputType: .textField,
                        description: "Total budget for home improvements."
                    )
                ],
                type: .housing,
                priority: 3
            ),
            BudgetCategory(
                id: "home_security",
                name: "Home Security",
                emoji: "🔒",
                description: "Expenses for home security systems.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "40",
                        inputType: .textField,
                        description: "Monthly home security expense."
                    )
                ],
                type: .utilities,
                priority: 2
            ),
            BudgetCategory(
                id: "medical_expenses",
                name: "Medical Expenses",
                emoji: "🏥",
                description: "Out-of-pocket medical costs.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "200",
                        inputType: .textField,
                        description: "Average monthly medical expense."
                    )
                ],
                type: .other,
                priority: 2
            ),
            BudgetCategory(
                id: "dental",
                name: "Dental",
                emoji: "😬",
                description: "Expenses for dental care.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "50",
                        inputType: .textField,
                        description: "Average monthly dental expense."
                    )
                ],
                type: .other,
                priority: 2
            ),
            BudgetCategory(
                id: "vision_care",
                name: "Vision Care",
                emoji: "👓",
                description: "Expenses for eye exams and glasses.",
                allocationPercentage: 0.01,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "30",
                        inputType: .textField,
                        description: "Average monthly vision care expense."
                    )
                ],
                type: .other,
                priority: 3
            ),
            BudgetCategory(
                id: "professional_development",
                name: "Professional Development",
                emoji: "📖",
                description: "Investments in career development.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "100",
                        inputType: .textField,
                        description: "Average monthly cost for professional development."
                    )
                ],
                type: .other,
                priority: 3
            ),
            BudgetCategory(
                id: "work_expenses",
                name: "Work Expenses",
                emoji: "💼",
                description: "Costs related to work such as commuting and supplies.",
                allocationPercentage: 0.04,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "150",
                        inputType: .textField,
                        description: "Average monthly work expense."
                    )
                ],
                type: .other,
                priority: 2
            ),
            BudgetCategory(
                id: "tax_savings",
                name: "Tax Savings",
                emoji: "🧾",
                description: "Funds set aside for tax payments.",
                allocationPercentage: 0.05,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Savings Target",
                        value: "300",
                        inputType: .textField,
                        description: "Amount to save monthly for taxes."
                    )
                ],
                type: .savings,
                priority: 1
            ),
            BudgetCategory(
                id: "miscellaneous",
                name: "Miscellaneous",
                emoji: "📦",
                description: "Other unplanned expenses.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "100",
                        inputType: .textField,
                        description: "Budget for miscellaneous expenses."
                    )
                ],
                type: .other,
                priority: 4
            ),
            BudgetCategory(
                id: "travel",
                name: "Travel",
                emoji: "✈️",
                description: "Expenses for travel not related to vacations.",
                allocationPercentage: 0.03,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "150",
                        inputType: .textField,
                        description: "Average monthly travel expense."
                    )
                ],
                type: .other,
                priority: 4
            ),
            BudgetCategory(
                id: "gifts",
                name: "Gifts",
                emoji: "🎁",
                description: "Budget for gift giving.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "50",
                        inputType: .textField,
                        description: "Budget for gifts."
                    )
                ],
                type: .other,
                priority: 4
            ),
            BudgetCategory(
                id: "legal_expenses",
                name: "Legal Expenses",
                emoji: "⚖️",
                description: "Costs for legal fees and advice.",
                allocationPercentage: 0.01,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Budget",
                        value: "30",
                        inputType: .textField,
                        description: "Average monthly legal expense."
                    )
                ],
                type: .other,
                priority: 3
            ),
            BudgetCategory(
                id: "investment_fees",
                name: "Investment Fees",
                emoji: "💼",
                description: "Management fees for investments.",
                allocationPercentage: 0.01,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "20",
                        inputType: .textField,
                        description: "Average monthly investment fees."
                    )
                ],
                type: .savings,
                priority: 3
            ),
            BudgetCategory(
                id: "charitable_donations",
                name: "Charitable Donations",
                emoji: "🤝",
                description: "Additional donations beyond basic charity.",
                allocationPercentage: 0.01,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Donation",
                        value: "25",
                        inputType: .textField,
                        description: "Budget for extra charitable donations."
                    )
                ],
                type: .savings,
                priority: 4
            ),
            BudgetCategory(
                id: "lawn_care",
                name: "Lawn Care",
                emoji: "🌱",
                description: "Expenses for maintaining your yard.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "40",
                        inputType: .textField,
                        description: "Average monthly lawn care expense."
                    )
                ],
                type: .other,
                priority: 4
            ),
            BudgetCategory(
                id: "cleaning_services",
                name: "Cleaning Services",
                emoji: "🧹",
                description: "Costs for professional cleaning.",
                allocationPercentage: 0.02,
                displayType: .monthly,
                assumptions: [
                    CategoryAssumption(
                        title: "Monthly Cost",
                        value: "80",
                        inputType: .textField,
                        description: "Average monthly cleaning service expense."
                    )
                ],
                type: .other,
                priority: 4
            )
        ]
        
        return list
    }
}
