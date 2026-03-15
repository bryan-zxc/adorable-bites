import Foundation

/// Maps ingredient combinations + mixing state to pan overlay images.
/// This is ingredient-driven, not recipe-driven — the images are determined
/// by what's physically in the pan, regardless of which recipe is being made.
struct PanImageMapping {

    struct Entry {
        let ingredientNames: Set<String>
        let wasMixed: Bool
        let rawImage: String
        let cookedImage: String
    }

    static let mappings: [Entry] = [
        Entry(
            ingredientNames: ["egg"],
            wasMixed: false,
            rawImage: "raw_egg_in_pan",
            cookedImage: "fried_egg_in_pan"
        ),
        Entry(
            ingredientNames: ["egg"],
            wasMixed: true,
            rawImage: "raw_scrambled_in_pan",
            cookedImage: "scrambled_egg_in_pan"
        ),
        Entry(
            ingredientNames: ["flour", "egg", "milk"],
            wasMixed: true,
            rawImage: "raw_batter_in_pan",
            cookedImage: "finished_pancake_in_pan"
        ),
    ]

    static func images(for ingredients: [Ingredient], wasMixed: Bool) -> (raw: String, cooked: String) {
        let nameSet = Set(ingredients.map { $0.name })
        for entry in mappings {
            if entry.ingredientNames == nameSet && entry.wasMixed == wasMixed {
                return (raw: entry.rawImage, cooked: entry.cookedImage)
            }
        }
        return (raw: "mystery_raw_in_pan", cooked: "mystery_cooked_in_pan")
    }

    @MainActor
    static func servedDishImage(for ingredients: [Ingredient], wasMixed: Bool) -> String {
        let ingredientSet = Set(ingredients)
        for recipe in KitchenScene.allRecipes {
            if Set(recipe.requiredIngredients) == ingredientSet && recipe.requiresMixing == wasMixed {
                return recipe.imageName
            }
        }
        return "mystery_dish_plate"
    }
}
