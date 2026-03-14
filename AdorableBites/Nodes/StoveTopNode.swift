import SpriteKit

class StoveTopNode: SKNode {

    private let cooktopSprite: SKSpriteNode
    private let panSprite: SKSpriteNode
    private let progressBar: SKShapeNode
    private var progressFill: SKShapeNode
    private var placedIngredients: [Ingredient] = []
    private var ingredientNodes: [SKNode] = []
    private let stoveSize: CGSize
    private let cookingDuration: TimeInterval = 4.0
    private var glowRing: SKShapeNode?

    var isCooking = false
    var isCooked = false

    var currentIngredients: [Ingredient] { placedIngredients }

    init(size: CGSize = CGSize(width: 200, height: 200)) {
        self.stoveSize = size

        let cooktopTexture = SKTexture(imageNamed: "induction_cooktop")
        cooktopSprite = SKSpriteNode(texture: cooktopTexture)
        cooktopSprite.size = size

        let panTexture = SKTexture(imageNamed: "frying_pan")
        panSprite = SKSpriteNode(texture: panTexture)
        let panScale = size.width * 0.55 / panTexture.size().width
        panSprite.size = CGSize(width: panTexture.size().width * panScale, height: panTexture.size().height * panScale)
        panSprite.position = CGPoint(x: 0, y: 5)
        panSprite.zPosition = 1

        let barWidth: CGFloat = size.width * 0.7
        let barHeight: CGFloat = 12
        progressBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 6)
        progressBar.fillColor = UIColor(red: 0.25, green: 0.25, blue: 0.30, alpha: 1.0)
        progressBar.strokeColor = .clear
        progressBar.position = CGPoint(x: 0, y: -size.height / 2 - 16)
        progressBar.alpha = 0
        progressBar.zPosition = 2

        progressFill = SKShapeNode(rectOf: CGSize(width: 0, height: barHeight - 2), cornerRadius: 5)
        progressFill.fillColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
        progressFill.strokeColor = .clear
        progressFill.position = CGPoint(x: -barWidth / 2, y: 0)
        progressBar.addChild(progressFill)

        super.init()

        name = "stoveTop"
        addChild(cooktopSprite)
        addChild(panSprite)
        addChild(progressBar)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addIngredient(_ ingredient: Ingredient) {
        guard !isCooking && !isCooked else { return }

        placedIngredients.append(ingredient)

        let texture = SKTexture(imageNamed: ingredient.imageName)
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: 40, height: 40)
        sprite.zPosition = 2

        sprite.setScale(0)
        sprite.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))

        addChild(sprite)
        ingredientNodes.append(sprite)
        recentreIngredients()
    }

    func removeIngredient(_ ingredient: Ingredient) {
        guard !isCooking && !isCooked else { return }
        guard let index = placedIngredients.firstIndex(of: ingredient) else { return }

        placedIngredients.remove(at: index)
        let node = ingredientNodes.remove(at: index)
        node.removeFromParent()
        recentreIngredients()
    }

    private func recentreIngredients() {
        let spacing: CGFloat = 45
        let totalWidth = spacing * CGFloat(ingredientNodes.count - 1)
        let startX = -totalWidth / 2
        for (i, node) in ingredientNodes.enumerated() {
            node.position = CGPoint(x: startX + spacing * CGFloat(i), y: 5)
        }
    }

    func startCooking(completion: @escaping () -> Void) {
        guard !isCooking else { return }
        isCooking = true

        for node in ingredientNodes {
            node.run(SKAction.fadeOut(withDuration: 0.3))
        }

        progressBar.alpha = 1.0

        // Pulsing glow ring around the cooktop
        let ring = SKShapeNode(circleOfRadius: stoveSize.width * 0.35)
        ring.fillColor = .clear
        ring.strokeColor = UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 0.8)
        ring.lineWidth = 4
        ring.glowWidth = 8
        ring.zPosition = 0.5
        addChild(ring)
        glowRing = ring

        let pulse = SKAction.sequence([
            SKAction.run { ring.strokeColor = UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 0.9) },
            SKAction.wait(forDuration: 0.4),
            SKAction.run { ring.strokeColor = UIColor(red: 1.0, green: 0.2, blue: 0.0, alpha: 0.6) },
            SKAction.wait(forDuration: 0.4)
        ])
        ring.run(SKAction.repeatForever(pulse), withKey: "pulse")

        let steam = SKAction.sequence([
            SKAction.run { [weak self] in self?.emitSteam() },
            SKAction.wait(forDuration: 0.6)
        ])
        run(SKAction.repeatForever(steam), withKey: "steamAnimation")

        let barWidth = stoveSize.width * 0.7
        let fillAction = SKAction.customAction(withDuration: cookingDuration) { [weak self] _, elapsed in
            guard let self = self else { return }
            let progress = elapsed / self.cookingDuration
            let fillWidth = barWidth * progress
            self.progressFill.removeFromParent()

            let newFill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: 10), cornerRadius: 5)
            newFill.fillColor = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
            newFill.strokeColor = .clear
            newFill.position = CGPoint(x: -barWidth / 2 + fillWidth / 2, y: 0)
            self.progressFill = newFill
            self.progressBar.addChild(newFill)
        }

        run(SKAction.sequence([fillAction, SKAction.run { [weak self] in
            self?.isCooking = false
            self?.isCooked = true
            self?.glowRing?.removeAllActions()
            self?.glowRing?.removeFromParent()
            self?.glowRing = nil
            self?.removeAction(forKey: "steamAnimation")
            completion()
        }]))
    }

    private func emitSteam() {
        let steam = SKLabelNode(text: "~")
        steam.fontSize = 20
        steam.fontColor = UIColor(white: 0.9, alpha: 0.7)
        steam.position = CGPoint(x: CGFloat.random(in: -30...30), y: 40)
        steam.zPosition = 3
        addChild(steam)

        let rise = SKAction.moveBy(x: CGFloat.random(in: -15...15), y: 50, duration: 1.0)
        let fade = SKAction.fadeOut(withDuration: 1.0)
        steam.run(SKAction.sequence([SKAction.group([rise, fade]), SKAction.removeFromParent()]))
    }

    func reset() {
        isCooking = false
        isCooked = false
        placedIngredients.removeAll()

        for node in ingredientNodes {
            node.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))
        }
        ingredientNodes.removeAll()

        progressBar.alpha = 0
        glowRing?.removeAllActions()
        glowRing?.removeFromParent()
        glowRing = nil
        removeAction(forKey: "steamAnimation")
    }
}
