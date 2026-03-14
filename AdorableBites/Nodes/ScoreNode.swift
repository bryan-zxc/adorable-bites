import SpriteKit

class ScoreNode: SKNode {

    private let background: SKShapeNode
    private let label: SKLabelNode
    private var score: Int = 0

    init(width: CGFloat = 200) {
        background = SKShapeNode(rectOf: CGSize(width: width, height: 50), cornerRadius: 14)
        background.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.95)
        background.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        background.lineWidth = 2.5

        label = SKLabelNode(text: "Score: 0")
        label.fontSize = 24
        label.fontName = "AvenirNext-Bold"
        label.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center

        super.init()

        name = "score"
        addChild(background)
        addChild(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func increment(by amount: Int = 1) {
        score += amount
        label.text = "Score: \(score)"

        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])
        label.run(bounce)
    }

    func decrement(by amount: Int = 1) {
        score -= amount
        label.text = "Score: \(score)"

        let originalColour = label.fontColor
        let flash = SKAction.sequence([
            SKAction.run { [weak self] in self?.label.fontColor = .red },
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in self?.label.fontColor = originalColour }
        ])
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -10, y: 0, duration: 0.05),
            SKAction.moveBy(x: 5, y: 0, duration: 0.05)
        ])
        label.run(SKAction.group([flash, shake]))
    }
}
