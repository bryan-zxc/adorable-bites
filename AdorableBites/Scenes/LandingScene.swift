import SpriteKit

class LandingScene: SKScene {

    var onLevelSelected: ((LevelConfig) -> Void)?
    private var progress: GameProgress

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
        // Restaurant exterior as full-bleed background — always covers entire screen
        let restaurantTexture = SKTexture(imageNamed: "restaurant_exterior")
        let restaurant = SKSpriteNode(texture: restaurantTexture)
        let texSize = restaurantTexture.size()
        // Scale to cover: fill both dimensions, crop overflow
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

        // Level buttons — centre bottom
        let levels = LevelConfig.allLevels
        let buttonWidth: CGFloat = 140
        let buttonHeight: CGFloat = 80
        let spacing: CGFloat = 20
        let totalWidth = CGFloat(levels.count) * buttonWidth + CGFloat(levels.count - 1) * spacing
        let startX = (size.width - totalWidth) / 2 + buttonWidth / 2

        for (index, level) in levels.enumerated() {
            let x = startX + CGFloat(index) * (buttonWidth + spacing)
            let y = size.height * 0.15

            let isUnlocked = progress.isLevelUnlocked(level.level)

            let btn = SKShapeNode(rectOf: CGSize(width: buttonWidth, height: buttonHeight), cornerRadius: 14)
            btn.fillColor = isUnlocked
                ? UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.95)
                : UIColor(red: 0.75, green: 0.72, blue: 0.68, alpha: 0.8)
            btn.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
            btn.lineWidth = 2.5
            btn.position = CGPoint(x: x, y: y)
            btn.name = "level_\(level.level)"
            btn.zPosition = 3
            addChild(btn)

            let levelLabel = SKLabelNode(text: "Level \(level.level)")
            levelLabel.fontSize = 18
            levelLabel.fontName = "AvenirNext-Bold"
            levelLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
            levelLabel.verticalAlignmentMode = .center
            levelLabel.position = CGPoint(x: 0, y: isUnlocked ? 0 : 10)
            levelLabel.name = "level_\(level.level)"
            btn.addChild(levelLabel)

            if !isUnlocked {
                let lockIcon = SKSpriteNode(texture: SKTexture(imageNamed: "snowflake"))
                lockIcon.size = CGSize(width: 16, height: 16)
                lockIcon.position = CGPoint(x: -15, y: -18)
                lockIcon.name = "level_\(level.level)"
                btn.addChild(lockIcon)

                let costLabel = SKLabelNode(text: "\(level.unlockCost)")
                costLabel.fontSize = 12
                costLabel.fontName = "AvenirNext-Bold"
                costLabel.fontColor = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
                costLabel.verticalAlignmentMode = .center
                costLabel.horizontalAlignmentMode = .left
                costLabel.position = CGPoint(x: 0, y: -18)
                costLabel.name = "level_\(level.level)"
                btn.addChild(costLabel)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
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
}
