import SpriteKit

class ScoreNode: SKNode {

    private let background: SKShapeNode
    private let label: SKLabelNode
    private(set) var score: Int = 0
    var currentScore: Int { score }

    init(width: CGFloat = 200) {
        background = SKShapeNode(rectOf: CGSize(width: width, height: 50), cornerRadius: 14)
        background.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.95)
        background.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        background.lineWidth = 2.5

        // Pause icon on the left
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let pauseImage = UIImage(systemName: "pause.fill", withConfiguration: config)!
            .withTintColor(UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0), renderingMode: .alwaysOriginal)
        let pauseIcon = SKSpriteNode(texture: SKTexture(image: pauseImage))
        pauseIcon.size = CGSize(width: 18, height: 18)
        pauseIcon.position = CGPoint(x: -width / 2 + 22, y: 0)
        pauseIcon.name = "pauseButton"

        // Divider line
        let divider = SKShapeNode(rectOf: CGSize(width: 1.5, height: 30))
        divider.fillColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: -width / 2 + 42, y: 0)

        // Score label shifted right
        label = SKLabelNode(text: "Score: 0")
        label.fontSize = 24
        label.fontName = "AvenirNext-Bold"
        label.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 15, y: 0)

        super.init()

        name = "score"
        addChild(background)
        background.addChild(pauseIcon)
        background.addChild(divider)
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
