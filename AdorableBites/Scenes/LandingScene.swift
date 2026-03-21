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

        // Quiz difficulty selector
        setupDifficultySelector()

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

    // MARK: - Quiz difficulty selector (dropdown)

    private var difficultyLabel: SKLabelNode?
    private var difficultyDropdown: SKNode?

    private func setupDifficultySelector() {
        let brown = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)

        // Main button that opens dropdown
        let bg = SKShapeNode(rectOf: CGSize(width: 180, height: 36), cornerRadius: 10)
        bg.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.95)
        bg.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        bg.lineWidth = 2
        bg.position = CGPoint(x: size.width - 100, y: size.height - 90)
        bg.zPosition = 5
        bg.name = "diffToggle"
        addChild(bg)

        let label = SKLabelNode(text: "Quiz Grade \(progress.quizGrade)  ▼")
        label.fontSize = 14
        label.fontName = "AvenirNext-Bold"
        label.fontColor = brown
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: 0)
        label.name = "diffToggle"
        bg.addChild(label)
        difficultyLabel = label
    }

    private func showDifficultyDropdown() {
        // Remove existing dropdown
        difficultyDropdown?.removeFromParent()

        let brown = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        let container = SKNode()
        container.zPosition = 20
        addChild(container)
        difficultyDropdown = container

        let itemHeight: CGFloat = 32
        let dropdownWidth: CGFloat = 180
        let startY = size.height - 112  // just below the button

        for i in 1...9 {
            let y = startY - CGFloat(i - 1) * itemHeight

            let itemBg = SKShapeNode(rectOf: CGSize(width: dropdownWidth, height: itemHeight - 2), cornerRadius: 6)
            itemBg.fillColor = i == progress.quizGrade
                ? UIColor(red: 0.85, green: 0.80, blue: 0.70, alpha: 0.98)
                : UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.98)
            itemBg.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 0.5)
            itemBg.lineWidth = 1
            itemBg.position = CGPoint(x: size.width - 100, y: y)
            itemBg.name = "diffOption_\(i)"
            container.addChild(itemBg)

            let itemLabel = SKLabelNode(text: "Level \(i)")
            itemLabel.fontSize = 14
            itemLabel.fontName = i == progress.quizGrade ? "AvenirNext-Bold" : "AvenirNext-Medium"
            itemLabel.fontColor = brown
            itemLabel.verticalAlignmentMode = .center
            itemLabel.position = .zero
            itemLabel.name = "diffOption_\(i)"
            itemBg.addChild(itemLabel)
        }
    }

    private func hideDifficultyDropdown() {
        difficultyDropdown?.removeFromParent()
        difficultyDropdown = nil
    }

    // MARK: - Frozen level tap handling

    private var unfreezePopup: UnfreezePopupNode?

    private func handleFrozenLevelTap(_ config: LevelConfig) {
        // Check if previous level is unlocked
        if config.level > 1 && !progress.isLevelUnlocked(config.level - 1) {
            if let card = levelStrip.children.first(where: { $0.name == "level_\(config.level)" }) {
                let shake = SKAction.sequence([
                    SKAction.moveBy(x: -6, y: 0, duration: 0.05),
                    SKAction.moveBy(x: 12, y: 0, duration: 0.05),
                    SKAction.moveBy(x: -12, y: 0, duration: 0.05),
                    SKAction.moveBy(x: 6, y: 0, duration: 0.05)
                ])
                card.run(shake)
            }

            let msg = SKLabelNode(text: "Complete Level \(config.level - 1) first!")
            msg.fontSize = 16
            msg.fontName = "ChalkboardSE-Bold"
            msg.fontColor = UIColor(red: 0.8, green: 0.15, blue: 0.15, alpha: 1.0)
            msg.verticalAlignmentMode = .center
            msg.position = CGPoint(x: size.width / 2, y: size.height * 0.30)
            msg.zPosition = 10
            addChild(msg)
            msg.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.5),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ]))
            return
        }

        // Show unfreeze popup
        let popup = UnfreezePopupNode(config: config, progress: progress, sceneSize: size)
        popup.onUnfreezeComplete = { [weak self] cfg in
            self?.unfreezePopup = nil
            self?.onLevelSelected?(cfg)
        }
        popup.onDismiss = { [weak self] in
            self?.unfreezePopup = nil
        }
        addChild(popup)
        unfreezePopup = popup
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

        // If it was a tap (not a drag), check for interactions
        if !isDragging {
            // Unfreeze popup takes priority
            if let popup = unfreezePopup {
                popup.handleTap()
                return
            }

            let location = touch.location(in: self)
            let tappedNodes = nodes(at: location)

            // Difficulty dropdown
            for node in tappedNodes {
                // Dropdown option selected
                if let name = node.name, name.starts(with: "diffOption_") {
                    let numStr = name.replacingOccurrences(of: "diffOption_", with: "")
                    if let num = Int(numStr) {
                        progress.quizGrade = num
                        progress.save()
                        difficultyLabel?.text = "Quiz Grade \(num)  ▼"
                        hideDifficultyDropdown()
                        return
                    }
                }
                // Toggle dropdown
                if node.name == "diffToggle" {
                    if difficultyDropdown != nil {
                        hideDifficultyDropdown()
                    } else {
                        showDifficultyDropdown()
                    }
                    return
                }
            }

            // Tap elsewhere closes dropdown
            if difficultyDropdown != nil {
                hideDifficultyDropdown()
                return
            }

            // Level selection
            for node in tappedNodes {
                guard let name = node.name, name.starts(with: "level_") else { continue }
                let levelStr = name.replacingOccurrences(of: "level_", with: "")
                guard let levelNum = Int(levelStr) else { continue }
                guard let config = LevelConfig.config(for: levelNum) else { continue }

                if progress.isLevelUnlocked(levelNum) {
                    // Already unlocked — play it
                    onLevelSelected?(config)
                } else {
                    // Frozen — check prerequisites and show unfreeze
                    handleFrozenLevelTap(config)
                }
                return
            }
        }

        isDragging = false
    }
}
