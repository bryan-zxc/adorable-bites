import Foundation

struct LevelConfig {
    let level: Int
    let name: String
    let recipeNames: [String]  // recipe names to look up at runtime
    let customerCount: Int
    let plateCount: Int
    let unlockCost: Int

    static let allLevels: [LevelConfig] = [
        LevelConfig(level: 1, name: "", recipeNames: ["Fried Egg"], customerCount: 3, plateCount: 3, unlockCost: 0),
        LevelConfig(level: 2, name: "", recipeNames: ["Fried Egg", "Scrambled Egg"], customerCount: 5, plateCount: 5, unlockCost: 1),
        LevelConfig(level: 3, name: "", recipeNames: ["Fried Egg", "Scrambled Egg", "Pancakes"], customerCount: 7, plateCount: 7, unlockCost: 1),
    ]

    @MainActor
    var recipes: [Recipe] {
        let allRecipes = KitchenScene.allRecipes
        return recipeNames.compactMap { name in
            allRecipes.first { $0.name == name }
        }
    }

    static func config(for level: Int) -> LevelConfig? {
        allLevels.first { $0.level == level }
    }

    static func nextLevel(after level: Int) -> LevelConfig? {
        allLevels.first { $0.level == level + 1 }
    }
}
