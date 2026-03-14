import SpriteKit

class StoveTopNode: SKNode {

    enum PanState {
        case empty
        case rawBatter
        case cooking
        case cooked
        case burnt
    }

    private(set) var panState: PanState = .empty
    private var storedIngredients: [Ingredient] = []
    private let cooktopSprite: SKSpriteNode
    private let panSprite: SKSpriteNode
    private var contentsOverlay: SKSpriteNode?
    private let progressBar: SKShapeNode
    private var progressFill: SKShapeNode
    private let stoveSize: CGSize
    private var glowRing: SKShapeNode?

    let cookingDuration: TimeInterval = 4.0
    let burnGracePeriod: TimeInterval = 5.0

    var currentIngredients: [Ingredient] { storedIngredients }
    var hasContents: Bool { panState != .empty }

    init(size: CGSize = CGSize(width: 200, height: 200)) {
        self.stoveSize = size

        let cooktopTexture = SKTexture(imageNamed: "induction_cooktop")
        cooktopSprite = SKSpriteNode(texture: cooktopTexture)
        cooktopSprite.size = size

        let panTexture = SKTexture(imageNamed: "frying_pan")
        panSprite = SKSpriteNode(texture: panTexture)
        let panScale = size.width * 0.55 / panTexture.size().width
        panSprite.size = CGSize(width: panTexture.size().width * panScale, height: panTexture.size().height * panScale)
        panSprite.position = CGPoint(x: 0, y: -8)
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

    // MARK: - Batter flow

    var canReceiveIngredient: Bool { panState == .empty || panState == .rawBatter }
    private var cookingCompleteCallback: (() -> Void)?
    private var burntCallback: (() -> Void)?

    func receiveBatter(ingredients: [Ingredient], cookingComplete: @escaping () -> Void, burnt: @escaping () -> Void) {
        guard panState == .empty else { return }
        storedIngredients = ingredients
        panState = .rawBatter
        cookingCompleteCallback = cookingComplete
        burntCallback = burnt
        showOverlay(imageNamed: "raw_batter_in_pan")
    }

    func startCooking() {
        guard panState == .rawBatter else { return }
        guard let cookingComplete = cookingCompleteCallback, let burnt = burntCallback else { return }
        startCookingInternal(cookingComplete: cookingComplete, burnt: burnt)
    }

    private func startCookingInternal(cookingComplete: @escaping () -> Void, burnt: @escaping () -> Void) {
        guard panState == .rawBatter else { return }
        panState = .cooking

        progressBar.alpha = 1.0

        // Pulsing glow ring
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

        // Progress bar animation
        let barWidth = stoveSize.width * 0.7
        let fillAction = SKAction.customAction(withDuration: cookingDuration) { [weak self] _, elapsed in
            guard let self else { return }
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
            self?.onCookingComplete(burnt: burnt)
            cookingComplete()
        }]))
    }

    private func onCookingComplete(burnt: @escaping () -> Void) {
        panState = .cooked
        glowRing?.removeAllActions()
        glowRing?.removeFromParent()
        glowRing = nil
        removeAction(forKey: "steamAnimation")

        showOverlay(imageNamed: "finished_pancake_in_pan")

        // Burn countdown bar — starts full green, drains to empty red
        let barWidth = stoveSize.width * 0.7
        progressFill.removeFromParent()
        let fullFill = SKShapeNode(rectOf: CGSize(width: barWidth, height: 10), cornerRadius: 5)
        fullFill.fillColor = UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)
        fullFill.strokeColor = .clear
        fullFill.position = CGPoint(x: 0, y: 0)
        progressFill = fullFill
        progressBar.addChild(fullFill)
        progressBar.alpha = 1.0

        let burnCountdown = SKAction.customAction(withDuration: burnGracePeriod) { [weak self] _, elapsed in
            guard let self else { return }
            let remaining = 1.0 - elapsed / self.burnGracePeriod
            let fillWidth = barWidth * remaining
            self.progressFill.removeFromParent()

            let newFill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: 10), cornerRadius: 5)
            // Colour shifts from green to red as time runs out
            let red = min(1.0, 2.0 * (1.0 - remaining))
            let green = min(1.0, 2.0 * remaining)
            newFill.fillColor = UIColor(red: red, green: green, blue: 0.1, alpha: 1.0)
            newFill.strokeColor = .clear
            newFill.position = CGPoint(x: -barWidth / 2 * (1.0 - remaining), y: 0)
            self.progressFill = newFill
            self.progressBar.addChild(newFill)
        }

        run(SKAction.sequence([
            burnCountdown,
            SKAction.run { [weak self] in
                guard self?.panState == .cooked else { return }
                self?.panState = .burnt
                self?.progressBar.run(SKAction.fadeOut(withDuration: 0.2))
                self?.showOverlay(imageNamed: "burnt_food")
                self?.run(SKAction.sequence([
                    SKAction.run { [weak self] in self?.emitSteam() },
                    SKAction.wait(forDuration: 0.3),
                    SKAction.run { [weak self] in self?.emitSteam() },
                    SKAction.wait(forDuration: 0.3),
                    SKAction.run { [weak self] in self?.emitSteam() }
                ]))
                burnt()
            }
        ]), withKey: "burnTimer")
    }

    func tapToServe() -> (ingredients: [Ingredient], isBurnt: Bool)? {
        guard panState == .cooked || panState == .burnt else { return nil }
        let isBurnt = panState == .burnt
        let ingredients = storedIngredients
        removeAction(forKey: "burnTimer")
        reset()
        return (ingredients: ingredients, isBurnt: isBurnt)
    }

    func reset() {
        removeAllActions()
        panState = .empty
        storedIngredients.removeAll()
        cookingCompleteCallback = nil
        burntCallback = nil
        contentsOverlay?.removeFromParent()
        contentsOverlay = nil
        hideDropTarget()
        progressBar.alpha = 0
        glowRing?.removeAllActions()
        glowRing?.removeFromParent()
        glowRing = nil
    }

    // MARK: - Drop target

    private var dropTargetBorder: SKShapeNode?

    func showDropTarget(active: Bool) {
        hideDropTarget()
        let border = SKShapeNode(rectOf: CGSize(width: stoveSize.width + 12, height: stoveSize.height + 12), cornerRadius: 14)
        border.fillColor = .clear
        border.strokeColor = active
            ? UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.9)
            : UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.6)
        border.lineWidth = 3
        border.glowWidth = active ? 4 : 0
        border.zPosition = -0.5
        addChild(border)
        dropTargetBorder = border

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.4),
            SKAction.fadeAlpha(to: 1.0, duration: 0.4)
        ])
        border.run(SKAction.repeatForever(pulse), withKey: "dropPulse")
    }

    func hideDropTarget() {
        dropTargetBorder?.removeAllActions()
        dropTargetBorder?.removeFromParent()
        dropTargetBorder = nil
    }

    // MARK: - Helpers

    private func showOverlay(imageNamed: String) {
        contentsOverlay?.removeFromParent()
        let texture = SKTexture(imageNamed: imageNamed)
        let overlay = SKSpriteNode(texture: texture)
        let panRadius = stoveSize.width * 0.22
        overlay.size = CGSize(width: panRadius * 2, height: panRadius * 2)
        overlay.position = CGPoint(x: 0, y: 15)
        overlay.zPosition = 2
        addChild(overlay)
        contentsOverlay = overlay
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
}
