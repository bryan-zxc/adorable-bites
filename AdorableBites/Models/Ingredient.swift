import UIKit

struct Ingredient: Equatable, Hashable {
    let name: String
    let colour: UIColor
    let imageName: String
    let cookTime: TimeInterval  // seconds this ingredient adds to cooking

    // Hashable/Equatable only on name (cookTime doesn't affect identity)
    static func == (lhs: Ingredient, rhs: Ingredient) -> Bool { lhs.name == rhs.name }
    func hash(into hasher: inout Hasher) { hasher.combine(name) }
}
