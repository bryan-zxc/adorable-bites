import SpriteKit

class HudNode: SKNode {

    private let background: SKShapeNode
    private let moneyLabel: SKLabelNode
    private let snowflakeLabel: SKLabelNode
    private(set) var dollars: Int = 0
    var snowflakes: Int = 0 {
        didSet { snowflakeLabel.text = "\(snowflakes)" }
    }

    init(width: CGFloat = 200) {
        let height: CGFloat = 80
        background = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 14)
        background.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.95)
        background.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        background.lineWidth = 2.5

        // Pause icon on the left, spanning full height
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let pauseImage = UIImage(systemName: "pause.fill", withConfiguration: config)!
            .withTintColor(UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0), renderingMode: .alwaysOriginal)
        let pauseIcon = SKSpriteNode(texture: SKTexture(image: pauseImage))
        pauseIcon.size = CGSize(width: 18, height: 18)
        pauseIcon.position = CGPoint(x: -width / 2 + 22, y: 0)
        pauseIcon.name = "pauseButton"

        // Vertical divider
        let vDivider = SKShapeNode(rectOf: CGSize(width: 1.5, height: height - 16))
        vDivider.fillColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        vDivider.strokeColor = .clear
        vDivider.position = CGPoint(x: -width / 2 + 42, y: 0)

        // Horizontal divider (between money and snowflakes)
        let hDivider = SKShapeNode(rectOf: CGSize(width: width - 60, height: 1.5))
        hDivider.fillColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        hDivider.strokeColor = .clear
        hDivider.position = CGPoint(x: 15, y: 0)

        // Money row (top half)
        let contentCentreX: CGFloat = 15
        let rowOffsetY: CGFloat = 18

        let moneyTexture = SKTexture(imageNamed: "money")
        let moneyIcon = SKSpriteNode(texture: moneyTexture)
        moneyIcon.size = CGSize(width: 22, height: 22)
        moneyIcon.position = CGPoint(x: contentCentreX - 35, y: rowOffsetY)

        moneyLabel = SKLabelNode(text: "$0")
        moneyLabel.fontSize = 20
        moneyLabel.fontName = "AvenirNext-Bold"
        moneyLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        moneyLabel.horizontalAlignmentMode = .left
        moneyLabel.verticalAlignmentMode = .center
        moneyLabel.position = CGPoint(x: contentCentreX - 18, y: rowOffsetY)

        // Snowflake row (bottom half)
        let snowflakeTexture = SKTexture(imageNamed: "snowflake")
        let snowflakeIcon = SKSpriteNode(texture: snowflakeTexture)
        snowflakeIcon.size = CGSize(width: 22, height: 22)
        snowflakeIcon.position = CGPoint(x: contentCentreX - 35, y: -rowOffsetY)

        snowflakeLabel = SKLabelNode(text: "0")
        snowflakeLabel.fontSize = 20
        snowflakeLabel.fontName = "AvenirNext-Bold"
        snowflakeLabel.fontColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
        snowflakeLabel.horizontalAlignmentMode = .left
        snowflakeLabel.verticalAlignmentMode = .center
        snowflakeLabel.position = CGPoint(x: contentCentreX - 18, y: -rowOffsetY)

        super.init()

        name = "hud"
        addChild(background)
        background.addChild(pauseIcon)
        background.addChild(vDivider)
        background.addChild(hDivider)
        addChild(moneyIcon)
        addChild(moneyLabel)
        addChild(snowflakeIcon)
        addChild(snowflakeLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Money

    func addDollars(_ amount: Int) {
        dollars += amount
        moneyLabel.text = "$\(dollars)"

        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])
        moneyLabel.run(bounce)
    }

    // MARK: - Snowflakes

    func addSnowflakes(_ amount: Int) {
        snowflakes += amount

        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])
        snowflakeLabel.run(bounce)
    }

    func removeSnowflakes(_ amount: Int) {
        snowflakes -= amount

        let originalColour = snowflakeLabel.fontColor
        let flash = SKAction.sequence([
            SKAction.run { [weak self] in self?.snowflakeLabel.fontColor = .red },
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in self?.snowflakeLabel.fontColor = originalColour }
        ])
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -10, y: 0, duration: 0.05),
            SKAction.moveBy(x: 5, y: 0, duration: 0.05)
        ])
        snowflakeLabel.run(SKAction.group([flash, shake]))
    }

    // MARK: - Floating feedback

    func showSnowflakeChange(_ amount: Int) {
        let text = amount > 0 ? "+\(amount)" : "\(amount)"
        let colour: UIColor = amount > 0
            ? UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
            : UIColor(red: 0.8, green: 0.15, blue: 0.15, alpha: 1.0)

        let label = SKLabelNode(text: text)
        label.fontSize = 18
        label.fontName = "AvenirNext-Bold"
        label.fontColor = colour
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: snowflakeLabel.position.x + 40, y: snowflakeLabel.position.y)
        label.zPosition = 10
        addChild(label)

        let rise = SKAction.moveBy(x: 0, y: 30, duration: 0.8)
        let fade = SKAction.fadeOut(withDuration: 0.8)
        label.run(SKAction.group([rise, fade])) {
            label.removeFromParent()
        }
    }
}
