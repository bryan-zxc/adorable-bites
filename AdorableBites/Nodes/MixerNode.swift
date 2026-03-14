import SpriteKit

class MixerNode: SKNode {

    enum MixerState {
        case empty
        case unmixed
        case mixing
        case ready
    }

    private(set) var state: MixerState = .empty
    private var placedIngredients: [Ingredient] = []

    var currentIngredients: [Ingredient] { placedIngredients }
    var canMix: Bool { state == .unmixed }
    var canPour: Bool { state == .ready }
    var isEmpty: Bool { state == .empty }

    private let bowlSprite: SKSpriteNode
    private var contentsOverlay: SKSpriteNode?
    private let mixerSize: CGSize

    // Progress bar
    private let progressBar: SKShapeNode
    private let progressFill: SKShapeNode
    private let barWidth: CGFloat
    private let barHeight: CGFloat = 12

    let mixingDuration: TimeInterval = 3.0

    init(size: CGSize = CGSize(width: 150, height: 150)) {
        self.mixerSize = size

        let bowlTexture = SKTexture(imageNamed: "mixing_bowl")
        bowlSprite = SKSpriteNode(texture: bowlTexture)
        bowlSprite.size = size
        bowlSprite.position = .zero

        barWidth = size.width * 0.7
        progressBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 6)
        progressBar.fillColor = UIColor(red: 0.25, green: 0.25, blue: 0.30, alpha: 1.0)
        progressBar.strokeColor = .clear
        progressBar.position = CGPoint(x: 0, y: -size.height / 2 - 16)
        progressBar.alpha = 0

        progressFill = SKShapeNode(rectOf: CGSize(width: 0, height: barHeight - 4), cornerRadius: 4)
        progressFill.fillColor = UIColor(red: 0.3, green: 0.75, blue: 0.4, alpha: 1.0)
        progressFill.strokeColor = .clear
        progressFill.position = CGPoint(x: -barWidth / 2, y: 0)
        progressBar.addChild(progressFill)

        super.init()

        name = "mixerNode"
        addChild(bowlSprite)
        addChild(progressBar)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addIngredient(_ ingredient: Ingredient) {
        guard state == .empty || state == .unmixed else { return }
        guard !placedIngredients.contains(ingredient) else { return }

        placedIngredients.append(ingredient)

        if state == .empty {
            state = .unmixed
            showOverlay(imageNamed: "unmixed_batter")
        }
    }

    func startMixing(completion: @escaping () -> Void) {
        guard state == .unmixed else { return }
        state = .mixing

        // Show progress bar
        progressBar.alpha = 1.0

        // Wobble animation
        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: .pi / 36, duration: 0.1),
            SKAction.rotate(byAngle: -.pi / 18, duration: 0.2),
            SKAction.rotate(byAngle: .pi / 36, duration: 0.1)
        ])
        bowlSprite.run(SKAction.repeat(wobble, count: Int(mixingDuration / 0.4)), withKey: "wobble")

        // Animate progress bar fill
        let fillAction = SKAction.customAction(withDuration: mixingDuration) { [weak self] _, elapsed in
            guard let self else { return }
            let progress = elapsed / CGFloat(self.mixingDuration)
            let width = self.barWidth * progress
            self.progressFill.path = CGPath(
                roundedRect: CGRect(x: 0, y: -self.barHeight / 2 + 2, width: width, height: self.barHeight - 4),
                cornerWidth: 4, cornerHeight: 4, transform: nil
            )
        }

        run(SKAction.sequence([
            fillAction,
            SKAction.run { [weak self] in
                self?.onMixingComplete()
                completion()
            }
        ]))
    }

    private func onMixingComplete() {
        state = .ready
        bowlSprite.removeAction(forKey: "wobble")
        bowlSprite.zRotation = 0

        // Swap to mixed batter overlay
        showOverlay(imageNamed: "mixed_batter")

        // Hide progress bar
        progressBar.run(SKAction.fadeOut(withDuration: 0.2))

        // Bounce to indicate ready
        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.12),
            SKAction.scale(to: 1.0, duration: 0.12)
        ])
        contentsOverlay?.run(bounce)
    }

    func pourBatter() -> [Ingredient] {
        guard state == .ready else { return [] }
        let ingredients = placedIngredients

        // Animate batter fading out
        contentsOverlay?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        contentsOverlay = nil

        placedIngredients = []
        state = .empty
        return ingredients
    }

    func reset() {
        removeAllActions()
        bowlSprite.removeAllActions()
        bowlSprite.zRotation = 0
        contentsOverlay?.removeFromParent()
        contentsOverlay = nil
        progressBar.alpha = 0
        progressFill.path = nil
        placedIngredients = []
        state = .empty
    }

    private func showOverlay(imageNamed: String) {
        contentsOverlay?.removeFromParent()
        let texture = SKTexture(imageNamed: imageNamed)
        let overlay = SKSpriteNode(texture: texture)
        overlay.size = CGSize(width: mixerSize.width * 0.6, height: mixerSize.height * 0.6)
        overlay.position = .zero
        overlay.zPosition = 1
        addChild(overlay)
        contentsOverlay = overlay
    }
}
