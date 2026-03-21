import SpriteKit

class IngredientNode: SKNode {

    let ingredient: Ingredient
    private let sprite: SKSpriteNode
    private let nameLabel: SKLabelNode
    private var closeButton: SKLabelNode?
    private(set) var isPickedUp: Bool = false
    private var originalSpritePosition: CGPoint = .zero

    init(ingredient: Ingredient, spriteSize: CGFloat = 54, labelOffsetX: CGFloat = 0, labelOffsetY: CGFloat = -95) {
        self.ingredient = ingredient

        let texture = SKTexture(imageNamed: ingredient.imageName)
        sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: spriteSize, height: spriteSize)
        sprite.position = .zero

        nameLabel = SKLabelNode(text: ingredient.name)
        nameLabel.fontSize = 14
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

    // MARK: - Pickup system

    func animatePickup() {
        isPickedUp = true
        originalSpritePosition = sprite.position

        // Scale up and drop down slightly
        sprite.run(SKAction.group([
            SKAction.scale(to: 1.4, duration: 0.2),
            SKAction.moveBy(x: 0, y: -15, duration: 0.2)
        ]))

        // Gentle bobbing
        let bob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 4, duration: 0.5),
            SKAction.moveBy(x: 0, y: -4, duration: 0.5)
        ])
        sprite.run(SKAction.repeatForever(bob), withKey: "bob")

        // Show X button — red circle with white X, top-right of scaled sprite
        let bg = SKShapeNode(circleOfRadius: 12)
        bg.fillColor = UIColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1.0)
        bg.strokeColor = .white
        bg.lineWidth = 2
        bg.position = CGPoint(x: sprite.size.width * 0.7, y: -15 + sprite.size.height * 0.7)
        bg.zPosition = 5
        bg.name = "ingredientClose"

        let xLabel = SKLabelNode(text: "✕")
        xLabel.fontSize = 14
        xLabel.fontName = "AvenirNext-Bold"
        xLabel.fontColor = .white
        xLabel.verticalAlignmentMode = .center
        xLabel.horizontalAlignmentMode = .center
        xLabel.name = "ingredientClose"
        bg.addChild(xLabel)

        addChild(bg)
        closeButton = xLabel

        // Glow effect on sprite
        sprite.color = UIColor(red: 1.0, green: 0.95, blue: 0.5, alpha: 1.0)
        sprite.colorBlendFactor = 0.2
    }

    func animateReturn() {
        isPickedUp = false

        sprite.removeAction(forKey: "bob")
        sprite.run(SKAction.group([
            SKAction.move(to: originalSpritePosition, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ]))
        sprite.colorBlendFactor = 0

        // Remove the circle background (parent of the label)
        closeButton?.parent?.removeFromParent()
        closeButton = nil
    }

    func animatePop() {
        run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }

    func isCloseButtonTap(at point: CGPoint) -> Bool {
        guard let close = closeButton, let circleBg = close.parent else { return false }
        let localPoint = convert(point, from: parent!)
        // Generous hit area around the circle
        let circlePos = circleBg.position
        let distance = hypot(localPoint.x - circlePos.x, localPoint.y - circlePos.y)
        return distance < 25
    }
}
