import SpriteKit

class IngredientNode: SKNode {

    let ingredient: Ingredient
    private let sprite: SKSpriteNode
    private let nameLabel: SKLabelNode

    init(ingredient: Ingredient, spriteSize: CGFloat = 54, labelOffsetX: CGFloat = 0, labelOffsetY: CGFloat = -95) {
        self.ingredient = ingredient

        let texture = SKTexture(imageNamed: ingredient.imageName)
        sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: spriteSize, height: spriteSize)
        sprite.position = .zero

        nameLabel = SKLabelNode(text: ingredient.name)
        nameLabel.fontSize = 9
        nameLabel.fontName = "AvenirNext-Bold"
        nameLabel.fontColor = UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: labelOffsetX, y: labelOffsetY)

        super.init()

        name = "ingredient_\(ingredient.name)"
        addChild(sprite)
        addChild(nameLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func animatePop() {
        run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }

    func animateDimmed() {
        alpha = 0.4
    }

    func animateReset() {
        alpha = 1.0
    }
}
