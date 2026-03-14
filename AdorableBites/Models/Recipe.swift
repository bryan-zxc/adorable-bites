import Foundation

struct Recipe {
    let name: String
    let imageName: String
    let requiredIngredients: [Ingredient]
    let basePoints: Int

    // Timer constants
    static let tapTime: Double = 1.0
    static let quizTime: Double = 5.0
    static let mixingDuration: Double = 3.0
    static let cookingDuration: Double = 4.0

    var waitTime: TimeInterval {
        let ingredientCount = Double(requiredIngredients.count)
        // 2 taps per ingredient (tap to pick up + tap to place) + 4 (mix + pour + start cook + serve)
        let taps = (ingredientCount * 2 + 4) * Recipe.tapTime
        let quizzes = ingredientCount * Recipe.quizTime
        let baseTime = taps + quizzes + Recipe.mixingDuration + Recipe.cookingDuration
        return ceil(baseTime * 1.5)
    }
}
