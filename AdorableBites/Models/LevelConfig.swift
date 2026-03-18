import Foundation

struct LevelConfig {
    let level: Int
    let name: String
    let recipeNames: [String]
    let chairCount: Int
    let customerCount: Int
    let plateCount: Int
    let unlockCost: Int

    // Feature flags — progressive mechanic introduction
    let autoCollectMoney: Bool
    let autoClearTable: Bool
    let canOvercook: Bool
    let hasCustomerTimer: Bool

    static let allLevels: [LevelConfig] = [
        LevelConfig(
            level: 1, name: "", recipeNames: ["Fried Egg"],
            chairCount: 1, customerCount: 3, plateCount: 3, unlockCost: 0,
            autoCollectMoney: true, autoClearTable: true,
            canOvercook: false, hasCustomerTimer: false
        ),
        LevelConfig(
            level: 2, name: "", recipeNames: ["Fried Egg", "Scrambled Egg"],
            chairCount: 1, customerCount: 5, plateCount: 5, unlockCost: 1,
            autoCollectMoney: false, autoClearTable: false,
            canOvercook: true, hasCustomerTimer: true
        ),
        LevelConfig(
            level: 3, name: "", recipeNames: ["Fried Egg", "Scrambled Egg", "Pancakes"],
            chairCount: 1, customerCount: 7, plateCount: 7, unlockCost: 1,
            autoCollectMoney: false, autoClearTable: false,
            canOvercook: true, hasCustomerTimer: true
        ),
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
