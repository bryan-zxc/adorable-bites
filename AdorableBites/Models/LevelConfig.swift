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

    // Tutorial shown on first play (nil = no tutorial)
    let tutorialMessage: String?
    let tutorialImages: [String]?  // asset names for step-by-step images
    let tutorialStepLabels: [String]?  // labels below each step image

    static let allLevels: [LevelConfig] = [
        LevelConfig(
            level: 1, name: "", recipeNames: ["Fried Egg"],
            chairCount: 1, customerCount: 2, plateCount: 3, unlockCost: 0,
            autoCollectMoney: true, autoClearTable: true,
            canOvercook: false, hasCustomerTimer: false,
            tutorialMessage: "Welcome to A-Dora-ble Bites!",
            tutorialImages: ["tutorial_ingredient", "tutorial_quiz", "tutorial_cook", "tutorial_serve"],
            tutorialStepLabels: ["Tap ingredient", "Answer quiz", "Cook it", "Serve!"]
        ),
        LevelConfig(
            level: 2, name: "", recipeNames: ["Fried Egg"],
            chairCount: 1, customerCount: 3, plateCount: 3, unlockCost: 1,
            autoCollectMoney: true, autoClearTable: true,
            canOvercook: false, hasCustomerTimer: true,
            tutorialMessage: "Watch out! Customers won't wait forever — keep an eye on the timer above their heads!",
            tutorialImages: nil, tutorialStepLabels: nil
        ),
        LevelConfig(
            level: 3, name: "", recipeNames: ["Fried Egg", "Pan Toast"],
            chairCount: 1, customerCount: 4, plateCount: 3, unlockCost: 1,
            autoCollectMoney: true, autoClearTable: true,
            canOvercook: true, hasCustomerTimer: true,
            tutorialMessage: "Careful — food can burn! Grab it from the pan quickly once it's cooked!",
            tutorialImages: nil, tutorialStepLabels: nil
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
