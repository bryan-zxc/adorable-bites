import SpriteKit

class LandingScene: SKScene {

    var onLevelSelected: ((LevelConfig) -> Void)?
    private var progress: GameProgress

    // Scrollable level strip
    private var levelStrip: SKNode!
    private var stripMinX: CGFloat = 0
    private var stripMaxX: CGFloat = 0
    private var lastTouchX: CGFloat = 0
    private var isDragging = false

    // Card layout
    private let cardSize: CGFloat = 100
    private let cardSpacing: CGFloat = 16

    init(progress: GameProgress) {
        self.progress = progress
        super.init(size: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.95, green: 0.90, blue: 0.80, alpha: 1.0)
        setupScene()
    }

    private func setupScene() {
        // Restaurant exterior as full-bleed background
        let restaurantTexture = SKTexture(imageNamed: "restaurant_exterior")
        let restaurant = SKSpriteNode(texture: restaurantTexture)
        let texSize = restaurantTexture.size()
        let scaleToFill = max(size.width / texSize.width, size.height / texSize.height) * 1.1
        restaurant.size = CGSize(width: texSize.width * scaleToFill, height: texSize.height * scaleToFill)
        restaurant.position = CGPoint(x: size.width / 2, y: size.height / 2)
        restaurant.zPosition = 0
        addChild(restaurant)

        // Dora on the right side
        let doraTexture = SKTexture(imageNamed: "dora")
        let dora = SKSpriteNode(texture: doraTexture)
        let doraHeight = size.height * 0.35
        let doraScale = doraHeight / doraTexture.size().height
        dora.size = CGSize(width: doraTexture.size().width * doraScale, height: doraHeight)
        dora.position = CGPoint(x: size.width * 0.82, y: size.height * 0.20)
        dora.zPosition = 1
        addChild(dora)

        // Currency display — top right
        setupCurrencyDisplay()

        // Scrollable level card strip
        setupLevelStrip()
    }

    // MARK: - Currency display

    private func setupCurrencyDisplay() {
        let currencyBg = SKShapeNode(rectOf: CGSize(width: 180, height: 60), cornerRadius: 14)
        currencyBg.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.95)
        currencyBg.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        currencyBg.lineWidth = 2
        currencyBg.position = CGPoint(x: size.width - 100, y: size.height - 40)
        currencyBg.zPosition = 5
        addChild(currencyBg)

        let moneyIcon = SKSpriteNode(texture: SKTexture(imageNamed: "money"))
        moneyIcon.size = CGSize(width: 20, height: 20)
        moneyIcon.position = CGPoint(x: -50, y: 10)
        currencyBg.addChild(moneyIcon)

        let moneyLabel = SKLabelNode(text: "$\(progress.totalDollars)")
        moneyLabel.fontSize = 16
        moneyLabel.fontName = "AvenirNext-Bold"
        moneyLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        moneyLabel.horizontalAlignmentMode = .left
        moneyLabel.verticalAlignmentMode = .center
        moneyLabel.position = CGPoint(x: -30, y: 10)
        currencyBg.addChild(moneyLabel)

        let snowIcon = SKSpriteNode(texture: SKTexture(imageNamed: "snowflake"))
        snowIcon.size = CGSize(width: 20, height: 20)
        snowIcon.position = CGPoint(x: -50, y: -12)
        currencyBg.addChild(snowIcon)

        let snowLabel = SKLabelNode(text: "\(progress.totalSnowflakes)")
        snowLabel.fontSize = 16
        snowLabel.fontName = "AvenirNext-Bold"
        snowLabel.fontColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
        snowLabel.horizontalAlignmentMode = .left
        snowLabel.verticalAlignmentMode = .center
        snowLabel.position = CGPoint(x: -30, y: -12)
        currencyBg.addChild(snowLabel)
    }

    // MARK: - Level strip

    private func setupLevelStrip() {
        levelStrip = SKNode()
        levelStrip.zPosition = 3
        addChild(levelStrip)

        let levels = LevelConfig.allLevels
        let stripY = size.height * 0.14

        let normalTexture = SKTexture(imageNamed: "level_frame")
        let frozenTexture = SKTexture(imageNamed: "level_frame_frozen")

        for (index, level) in levels.enumerated() {
            let x = CGFloat(index) * (cardSize + cardSpacing) + cardSize / 2 + cardSpacing
            let isUnlocked = progress.isLevelUnlocked(level.level)

            // Frame image
            let texture = isUnlocked ? normalTexture : frozenTexture
            let card = SKSpriteNode(texture: texture)
            card.size = CGSize(width: cardSize, height: cardSize)
            card.position = CGPoint(x: x, y: stripY)
            card.name = "level_\(level.level)"
            levelStrip.addChild(card)

            // Level number — warm colour for normal, icy blue for frozen
            let numberLabel = SKLabelNode(text: "\(level.level)")
            numberLabel.fontSize = 42
            numberLabel.fontName = "ChalkboardSE-Bold"
            numberLabel.fontColor = isUnlocked
                ? UIColor(red: 0.5, green: 0.3, blue: 0.1, alpha: 1.0)
                : UIColor(red: 0.55, green: 0.7, blue: 0.85, alpha: 0.8)
            numberLabel.verticalAlignmentMode = .center
            numberLabel.horizontalAlignmentMode = .center
            numberLabel.position = CGPoint(x: 0, y: 2)
            numberLabel.zPosition = 1
            numberLabel.name = "level_\(level.level)"
            card.addChild(numberLabel)

            // Snowflake cost for frozen levels
            if !isUnlocked {
                let cost = max(1, level.unlockCost)
                let costBg = SKShapeNode(rectOf: CGSize(width: 50, height: 24), cornerRadius: 10)
                costBg.fillColor = UIColor(white: 0, alpha: 0.5)
                costBg.strokeColor = .clear
                costBg.position = CGPoint(x: 0, y: -cardSize / 2 + 18)
                costBg.zPosition = 2
                costBg.name = "level_\(level.level)"
                card.addChild(costBg)

                let snowMini = SKSpriteNode(texture: SKTexture(imageNamed: "snowflake"))
                snowMini.size = CGSize(width: 16, height: 16)
                snowMini.position = CGPoint(x: -12, y: 0)
                costBg.addChild(snowMini)

                let costLabel = SKLabelNode(text: "\(cost)")
                costLabel.fontSize = 14
                costLabel.fontName = "AvenirNext-Bold"
                costLabel.fontColor = .white
                costLabel.verticalAlignmentMode = .center
                costLabel.horizontalAlignmentMode = .left
                costLabel.position = CGPoint(x: 0, y: 0)
                costLabel.name = "level_\(level.level)"
                costBg.addChild(costLabel)
            }
        }

        // Calculate scroll bounds
        let totalStripWidth = CGFloat(levels.count) * (cardSize + cardSpacing) + cardSpacing
        stripMaxX = 0
        stripMinX = -(totalStripWidth - size.width)

        // Centre the strip if it fits on screen (few levels)
        if totalStripWidth <= size.width {
            levelStrip.position.x = (size.width - totalStripWidth) / 2
            stripMinX = levelStrip.position.x
            stripMaxX = levelStrip.position.x
        }
    }

    // MARK: - Touch handling (scroll + tap)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        lastTouchX = touch.location(in: self).x
        isDragging = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentX = touch.location(in: self).x
        let deltaX = currentX - lastTouchX

        if abs(deltaX) > 3 { isDragging = true }

        if isDragging {
            var newX = levelStrip.position.x + deltaX
            newX = max(stripMinX, min(stripMaxX, newX))
            levelStrip.position.x = newX
        }
        lastTouchX = currentX
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        // If it was a tap (not a drag), check for level selection
        if !isDragging {
            let location = touch.location(in: self)
            let tappedNodes = nodes(at: location)

            for node in tappedNodes {
                guard let name = node.name, name.starts(with: "level_") else { continue }
                let levelStr = name.replacingOccurrences(of: "level_", with: "")
                guard let levelNum = Int(levelStr) else { continue }
                guard let config = LevelConfig.config(for: levelNum) else { continue }

                if progress.isLevelUnlocked(levelNum) {
                    onLevelSelected?(config)
                }
                return
            }
        }

        isDragging = false
    }
}
