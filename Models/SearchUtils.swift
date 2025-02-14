struct SearchUtils {
    /// Keywords mapping for category matching
    static let categoryKeywords: [String: Set<String>] = [
        // Housing & Property
        "home": ["house", "property", "residence", "apartment", "renovation", "repair", "maintenance", "improvement", "dwelling"],
        "renovation": ["home improvement", "repairs", "remodel", "upgrade", "fix", "maintenance", "construction"],
        "mortgage": ["home loan", "house payment", "property loan", "home debt", "housing loan", "real estate loan"],
        
        // Transportation
        "car": ["auto", "vehicle", "transportation", "automobile", "automotive"],
        "maintenance": ["repair", "upkeep", "service", "fix", "servicing", "care"],
        
        // Utilities & Services
        "utilities": ["bills", "electric", "water", "gas", "power", "energy", "electricity"],
        "internet": ["wifi", "broadband", "cable", "network", "connectivity"],
        
        // Insurance & Protection
        "insurance": ["coverage", "protection", "policy", "premium", "assurance", "security"],
        "health": ["medical", "healthcare", "wellness", "hospital", "doctor", "coverage"],
        
        // Savings & Investments
        "savings": ["emergency fund", "reserve", "nest egg", "saving", "saved", "safety net"],
        "investment": ["stocks", "bonds", "portfolio", "market", "mutual funds", "securities"],
        "retirement": ["401k", "ira", "pension", "retirement savings", "superannuation"],
        "emergency": ["rainy day", "emergency fund", "backup", "safety net", "reserve", "contingency"],
        "college": ["education savings", "university", "school", "tuition", "student savings"],
        "vacation": ["travel savings", "holiday", "trip", "getaway", "leisure"],
        
        // Debt & Loans
        "debt": ["loan", "credit", "payment", "balance", "borrowing", "financing"],
        "credit": ["credit card", "credit cards", "card", "cards", "balance"],
        "student": ["education loan", "college loan", "university", "school loan", "student debt"],
        "personal_loan": ["bank loan", "private loan", "signature loan", "unsecured", "consumer loan"],
        
        // Living Expenses
        "groceries": ["food", "supermarket", "provisions", "grocery", "household items"],
        "dining": ["restaurants", "eating out", "takeout", "food", "cafe", "dining out"],
        
        // Family & Care
        "childcare": ["daycare", "babysitting", "child care", "childminding", "nursery"],
        "pet": ["animal", "veterinary", "vet", "pet care", "pet supplies"],
        
        // Personal Development
        "education": ["school", "college", "university", "tuition", "learning", "courses"],
        "professional": ["career", "work", "job", "professional development", "training"],
        
        // Personal Care
        "personal": ["self care", "grooming", "hygiene", "personal care"],
        "cleaning": ["housekeeping", "maid", "janitorial", "cleaning service"],
        "clothing": ["apparel", "clothes", "fashion", "wardrobe", "attire"],
        
        // Charitable
        "charity": ["donation", "charitable", "giving", "nonprofit", "philanthropy", "contributions"],
        
        // Entertainment
        "entertainment": ["fun", "leisure", "recreation", "hobby", "activities", "entertainment"],
        
        // Healthcare
        "medical": ["health", "healthcare", "doctor", "hospital", "medical care", "treatment"]
    ]
    
    /// Performs fuzzy search on a string using multiple matching techniques
    static func fuzzyMatch(_ source: String, _ target: String) -> Bool {
        let sourceWords = source.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        let targetWords = target.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        
        // Check for exact matches first
        if sourceWords.contains(where: { targetWords.contains($0) }) {
            return true
        }
        
        // Check keyword associations
        for sourceWord in sourceWords {
            let sourceStr = String(sourceWord)
            // Check if we have keywords for this word
            if let keywords = categoryKeywords[sourceStr] {
                // Check if any target word matches one of our keywords
                if targetWords.contains(where: { keywords.contains(String($0)) }) {
                    return true
                }
            }
            
            // Check if any target word is in any keyword set that contains the source word
            for (_, keywords) in categoryKeywords {
                if keywords.contains(sourceStr) {
                    if targetWords.contains(where: { keywords.contains(String($0)) }) {
                        return true
                    }
                }
            }
        }
        
        // Check for partial matches
        for sourceWord in sourceWords {
            if targetWords.contains(where: { $0.hasPrefix(sourceWord) || sourceWord.hasPrefix($0) }) {
                return true
            }
        }
        
        // Calculate similarity for remaining cases
        for sourceWord in sourceWords {
            for targetWord in targetWords {
                if calculateSimilarity(String(sourceWord), String(targetWord)) > 0.7 {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Calculates the similarity between two strings (0-1)
    private static func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        let empty = [Int](repeating: 0, count: s2.count + 1)
        var last = [Int](0...s2.count)
        
        for (i, c1) in s1.enumerated() {
            var current = [i + 1] + empty
            for (j, c2) in s2.enumerated() {
                current[j + 1] = c1 == c2 ? last[j] : min(last[j], min(last[j + 1], current[j])) + 1
            }
            last = current
        }
        
        let maxLength = Double(max(s1.count, s2.count))
        let distance = Double(last[s2.count])
        return 1 - (distance / maxLength)
    }
    
    /// Enhanced search function for BudgetCategory
    static func searchCategories(_ categories: [BudgetCategory], searchText: String) -> [BudgetCategory] {
        guard !searchText.isEmpty else { return categories }
        
        return categories.filter { category in
            fuzzyMatch(searchText, category.name) ||
            fuzzyMatch(searchText, category.description) ||
            searchText.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .contains { word in
                    if let keywords = categoryKeywords[String(word)] {
                        return fuzzyMatch(category.name.lowercased(), Array(keywords).joined(separator: " "))
                    }
                    return false
                }
        }
    }
}
