import SpriteKit

/// Reusable unfreeze popup shown when tapping a frozen level.
/// Used by both LandingScene and KitchenScene.
class UnfreezePopupNode: SKNode {

    private let config: LevelConfig
    private var progress: GameProgress
    private var phase: Int = 0  // 0 = frozen (tap to unfreeze), 1 = unfrozen (tap to play)
    private let sceneSize: CGSize

    var onUnfreezeComplete: ((LevelConfig) -> Void)?
    var onDismiss: (() -> Void)?

    init(config: LevelConfig, progress: GameProgress, sceneSize: CGSize) {
        self.config = config
        self.progress = progress
        self.sceneSize = sceneSize
        super.init()

        zPosition = 100
        setupPopup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPopup() {
        let brown = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        let blue = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
        let hasNewIngs = !config.newIngredients.isEmpty

        // Dim overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: sceneSize.width * 2, height: sceneSize.height * 2))
        overlay.fillColor = UIColor(white: 0, alpha: 0.75)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        addChild(overlay)

        // Card
        let cardWidth: CGFloat = hasNewIngs ? 450 : 300
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: 380), cornerRadius: 24)
        card.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.98)
        card.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        card.lineWidth = 3
        card.position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        addChild(card)

        // Title
        let title = SKLabelNode(text: "Level \(config.level)")
        title.fontSize = 24
        title.fontName = "ChalkboardSE-Bold"
        title.fontColor = brown
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 0, y: 145)
        card.addChild(title)

        // Frozen frame
        let frameSize: CGFloat = 130
        let contentY: CGFloat = 30
        let frameX: CGFloat = hasNewIngs ? -80 : 0

        let frozenFrame = SKSpriteNode(texture: SKTexture(imageNamed: "level_frame_frozen"))
        frozenFrame.size = CGSize(width: frameSize, height: frameSize)
        frozenFrame.position = CGPoint(x: frameX, y: contentY)
        frozenFrame.name = "unfreezeFrame"
        card.addChild(frozenFrame)

        let numLabel = SKLabelNode(text: "\(config.level)")
        numLabel.fontSize = 48
        numLabel.fontName = "ChalkboardSE-Bold"
        numLabel.fontColor = UIColor(red: 0.55, green: 0.7, blue: 0.85, alpha: 0.8)
        numLabel.verticalAlignmentMode = .center
        numLabel.horizontalAlignmentMode = .center
        numLabel.position = CGPoint(x: 0, y: 2)
        numLabel.zPosition = 1
        numLabel.name = "unfreezeNumber"
        frozenFrame.addChild(numLabel)

        // New ingredients
        if hasNewIngs {
            let frozenOverlayTex = SKTexture(imageNamed: "frozen_overlay")
            let ingStartX: CGFloat = 90

            for (i, ingName) in config.newIngredients.enumerated() {
                let ix = ingStartX + CGFloat(i) * (frameSize + 40)

                let ingSprite = SKSpriteNode(texture: SKTexture(imageNamed: ingName))
                ingSprite.size = CGSize(width: frameSize * 0.7, height: frameSize * 0.7)
                ingSprite.position = CGPoint(x: ix, y: contentY)
                ingSprite.zPosition = 1
                ingSprite.name = "unfreezeIng_\(ingName)"
                card.addChild(ingSprite)

                let iceOverlay = SKSpriteNode(texture: frozenOverlayTex)
                iceOverlay.size = CGSize(width: frameSize, height: frameSize)
                iceOverlay.position = CGPoint(x: ix, y: contentY)
                iceOverlay.zPosition = 2
                iceOverlay.name = "unfreezeIce_\(ingName)"
                card.addChild(iceOverlay)

                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.05, duration: 0.5),
                    SKAction.scale(to: 1.0, duration: 0.5)
                ])
                iceOverlay.run(SKAction.repeatForever(pulse))

                let nameLabel = SKLabelNode(text: ingName)
                nameLabel.fontSize = 14
                nameLabel.fontName = "ChalkboardSE-Bold"
                nameLabel.fontColor = brown
                nameLabel.verticalAlignmentMode = .top
                nameLabel.position = CGPoint(x: ix, y: contentY - frameSize / 2 - 6)
                card.addChild(nameLabel)
            }

            let plusLabel = SKLabelNode(text: "+")
            plusLabel.fontSize = 32
            plusLabel.fontName = "AvenirNext-Bold"
            plusLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 0.5)
            plusLabel.verticalAlignmentMode = .center
            plusLabel.position = CGPoint(x: 0, y: contentY)
            card.addChild(plusLabel)
        }

        // Cost
        let cost = max(1, config.unlockCost)
        let snowIcon = SKSpriteNode(texture: SKTexture(imageNamed: "snowflake"))
        snowIcon.size = CGSize(width: 28, height: 28)
        snowIcon.position = CGPoint(x: -18, y: -80)
        snowIcon.name = "unfreezeCostIcon"
        card.addChild(snowIcon)

        let costLabel = SKLabelNode(text: "-\(cost)")
        costLabel.fontSize = 24
        costLabel.fontName = "AvenirNext-Bold"
        costLabel.fontColor = blue
        costLabel.verticalAlignmentMode = .center
        costLabel.horizontalAlignmentMode = .left
        costLabel.position = CGPoint(x: 4, y: -80)
        costLabel.name = "unfreezeCostLabel"
        card.addChild(costLabel)

        // Hint
        let hint = SKLabelNode(text: "Tap to unfreeze!")
        hint.fontSize = 18
        hint.fontName = "ChalkboardSE-Bold"
        hint.fontColor = brown
        hint.verticalAlignmentMode = .center
        hint.position = CGPoint(x: 0, y: -130)
        hint.name = "unfreezeHint"
        card.addChild(hint)

        // Pulse on frame
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        frozenFrame.run(SKAction.repeatForever(pulse))
    }

    // MARK: - Tap handling

    func handleTap() {
        if phase == 0 {
            // Phase 0: try to unfreeze
            let cost = max(1, config.unlockCost)
            guard progress.unlockLevel(config.level, cost: cost) else {
                // Can't afford
                if let hint = findNode(named: "unfreezeHint") as? SKLabelNode {
                    hint.text = "Not enough! You have \(progress.totalSnowflakes) snowflakes"
                    hint.fontColor = UIColor(red: 0.8, green: 0.15, blue: 0.15, alpha: 1.0)
                }
                if let frame = findNode(named: "unfreezeFrame") {
                    let shake = SKAction.sequence([
                        SKAction.moveBy(x: -8, y: 0, duration: 0.05),
                        SKAction.moveBy(x: 16, y: 0, duration: 0.05),
                        SKAction.moveBy(x: -16, y: 0, duration: 0.05),
                        SKAction.moveBy(x: 8, y: 0, duration: 0.05)
                    ])
                    frame.run(shake)
                }
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 1.5),
                    SKAction.run { [weak self] in
                        self?.removeFromParent()
                        self?.onDismiss?()
                    }
                ]))
                return
            }

            // Unfreeze animation
            if let frame = findNode(named: "unfreezeFrame") as? SKSpriteNode {
                frame.removeAllActions()
                let framePos = frame.parent?.convert(frame.position, to: self) ?? frame.position

                // Flash
                let flash = SKShapeNode(rectOf: CGSize(width: 140, height: 140), cornerRadius: 10)
                flash.fillColor = .white
                flash.strokeColor = .clear
                flash.alpha = 0
                flash.position = framePos
                flash.zPosition = 10
                addChild(flash)

                // Sparkles
                for _ in 0..<12 {
                    let spark = SKSpriteNode(texture: SKTexture(imageNamed: "snowflake"))
                    spark.size = CGSize(width: 14, height: 14)
                    spark.position = framePos
                    spark.zPosition = 11
                    addChild(spark)
                    let angle = CGFloat.random(in: 0...(.pi * 2))
                    let dist = CGFloat.random(in: 50...100)
                    spark.run(SKAction.sequence([
                        SKAction.group([
                            SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.5),
                            SKAction.fadeOut(withDuration: 0.5),
                            SKAction.scale(to: 0.3, duration: 0.5)
                        ]),
                        SKAction.removeFromParent()
                    ]))
                }

                // Swap texture
                flash.run(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.8, duration: 0.1),
                    SKAction.run {
                        frame.texture = SKTexture(imageNamed: "level_frame")
                        if let num = frame.childNode(withName: "unfreezeNumber") as? SKLabelNode {
                            num.fontColor = UIColor(red: 0.5, green: 0.3, blue: 0.1, alpha: 1.0)
                        }
                    },
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent()
                ]))

                frame.run(SKAction.sequence([
                    SKAction.scale(to: 1.2, duration: 0.15),
                    SKAction.scale(to: 1.0, duration: 0.2)
                ]))
            }

            // Remove ice from ingredients
            for ingName in config.newIngredients {
                findNode(named: "unfreezeIce_\(ingName)")?.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent()
                ]))
            }

            // Hide cost, update hint
            findNode(named: "unfreezeCostIcon")?.run(SKAction.fadeOut(withDuration: 0.3))
            findNode(named: "unfreezeCostLabel")?.run(SKAction.fadeOut(withDuration: 0.3))
            if let hint = findNode(named: "unfreezeHint") as? SKLabelNode {
                hint.text = "Tap to play!"
            }

            phase = 1

        } else {
            // Phase 1: proceed to level
            removeFromParent()
            onUnfreezeComplete?(config)
        }
    }

    // MARK: - Helpers

    private func findNode(named name: String) -> SKNode? {
        return findNodeRecursive(named: name, in: self)
    }

    private func findNodeRecursive(named name: String, in node: SKNode) -> SKNode? {
        if node.name == name { return node }
        for child in node.children {
            if let found = findNodeRecursive(named: name, in: child) { return found }
        }
        return nil
    }
}
