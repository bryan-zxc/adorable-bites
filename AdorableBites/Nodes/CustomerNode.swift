import SpriteKit

class CustomerNode: SKNode {

    private let avatarSprite: SKSpriteNode
    private let speechBubble: SKShapeNode
    private let orderSprite: SKSpriteNode
    private let nameLabel: SKLabelNode

    // Timer
    private let timerBarBackground: SKShapeNode
    private var timerBarFill: SKShapeNode
    private let timerBarWidth: CGFloat = 80
    private let timerBarHeight: CGFloat = 6
    private(set) var isInBonusWindow: Bool = true
    private(set) var isEating: Bool = false
    var onTimerExpired: (() -> Void)?
    var onFinishedEating: (() -> Void)?

    init(customer: Customer) {
        // Customer avatar
        let avatarTexture = SKTexture(imageNamed: customer.imageName)
        avatarSprite = SKSpriteNode(texture: avatarTexture)
        avatarSprite.size = CGSize(width: 80, height: 80)
        avatarSprite.position = .zero

        // Name below avatar
        nameLabel = SKLabelNode(text: customer.name)
        nameLabel.fontSize = 14
        nameLabel.fontName = "AvenirNext-Bold"
        nameLabel.fontColor = UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        nameLabel.verticalAlignmentMode = .top
        nameLabel.position = CGPoint(x: 0, y: -46)

        // Speech bubble to the right of avatar
        let bubbleWidth: CGFloat = 80
        let bubbleHeight: CGFloat = 70
        speechBubble = SKShapeNode(rectOf: CGSize(width: bubbleWidth, height: bubbleHeight), cornerRadius: 14)
        speechBubble.fillColor = .white
        speechBubble.strokeColor = UIColor(red: 0.82, green: 0.76, blue: 0.66, alpha: 1.0)
        speechBubble.lineWidth = 2.5
        speechBubble.position = CGPoint(x: 90, y: 0)

        // Small triangle pointer on the speech bubble
        let pointer = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -bubbleWidth / 2 - 8, y: 5))
        path.addLine(to: CGPoint(x: -bubbleWidth / 2, y: 12))
        path.addLine(to: CGPoint(x: -bubbleWidth / 2, y: -2))
        path.closeSubpath()
        pointer.path = path
        pointer.fillColor = .white
        pointer.strokeColor = UIColor(red: 0.82, green: 0.76, blue: 0.66, alpha: 1.0)
        pointer.lineWidth = 2.5
        speechBubble.addChild(pointer)

        // Order dish image inside the bubble
        let orderTexture = SKTexture(imageNamed: customer.order.imageName)
        orderSprite = SKSpriteNode(texture: orderTexture)
        orderSprite.size = CGSize(width: 50, height: 50)
        orderSprite.position = .zero
        speechBubble.addChild(orderSprite)

        // Timer bar below speech bubble
        timerBarBackground = SKShapeNode(rectOf: CGSize(width: 80, height: 6), cornerRadius: 3)
        timerBarBackground.fillColor = UIColor(red: 0.85, green: 0.82, blue: 0.78, alpha: 1.0)
        timerBarBackground.strokeColor = .clear
        timerBarBackground.position = CGPoint(x: 90, y: -42)

        timerBarFill = SKShapeNode(rectOf: CGSize(width: 80, height: 6), cornerRadius: 3)
        timerBarFill.fillColor = UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)
        timerBarFill.strokeColor = .clear
        timerBarFill.position = CGPoint(x: 90, y: -42)

        super.init()

        name = "customer"
        addChild(avatarSprite)
        addChild(nameLabel)
        addChild(speechBubble)
        addChild(timerBarBackground)
        addChild(timerBarFill)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Timer

    func startTimer(duration: TimeInterval) {
        isInBonusWindow = true

        // Timer 1: bonus window (green bar drains)
        let bonusCountdown = SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self else { return }
            let remaining = 1.0 - elapsed / duration
            self.updateTimerBar(progress: remaining, colour: UIColor(
                red: 0.3 + 0.4 * (1.0 - remaining),
                green: 0.8 * remaining,
                blue: 0.3 * remaining,
                alpha: 1.0
            ))
        }

        let startTimer2 = SKAction.run { [weak self] in
            self?.isInBonusWindow = false
            self?.startImpatientAnimation()
            self?.startSecondTimer(duration: duration)
        }

        run(SKAction.sequence([bonusCountdown, startTimer2]), withKey: "customerTimer")
    }

    private func startSecondTimer(duration: TimeInterval) {
        // Reset bar to full but orange/red
        updateTimerBar(progress: 1.0, colour: UIColor(red: 0.9, green: 0.4, blue: 0.1, alpha: 1.0))

        let normalCountdown = SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self else { return }
            let remaining = 1.0 - elapsed / duration
            self.updateTimerBar(progress: remaining, colour: UIColor(
                red: 0.9,
                green: 0.4 * remaining,
                blue: 0.1 * remaining,
                alpha: 1.0
            ))
        }

        let expire = SKAction.run { [weak self] in
            self?.stopImpatientAnimation()
            self?.onTimerExpired?()
        }

        run(SKAction.sequence([normalCountdown, expire]), withKey: "customerTimer")
    }

    // MARK: - Eating

    func startEating(duration: TimeInterval) {
        isEating = true
        timerBarBackground.isHidden = false
        timerBarFill.isHidden = false

        // Blue countdown bar while eating
        updateTimerBar(progress: 1.0, colour: UIColor(red: 0.4, green: 0.5, blue: 0.85, alpha: 1.0))

        let eatingCountdown = SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self else { return }
            let remaining = 1.0 - elapsed / duration
            self.updateTimerBar(progress: remaining, colour: UIColor(
                red: 0.4,
                green: 0.5 * remaining,
                blue: 0.85 * remaining + 0.15,
                alpha: 1.0
            ))
        }

        let done = SKAction.run { [weak self] in
            self?.isEating = false
            self?.onFinishedEating?()
        }

        run(SKAction.sequence([eatingCountdown, done]), withKey: "customerTimer")
    }

    func cancelTimer() {
        removeAction(forKey: "customerTimer")
        stopImpatientAnimation()
        timerBarFill.isHidden = true
        timerBarBackground.isHidden = true
    }

    private func updateTimerBar(progress: CGFloat, colour: UIColor) {
        timerBarFill.removeFromParent()
        let width = timerBarWidth * max(progress, 0)
        let newFill = SKShapeNode(rectOf: CGSize(width: width, height: timerBarHeight), cornerRadius: 3)
        newFill.fillColor = colour
        newFill.strokeColor = .clear
        // Anchor left: offset so bar drains from right
        let xOffset = -(timerBarWidth - width) / 2
        newFill.position = CGPoint(x: 90 + xOffset, y: -42)
        addChild(newFill)
        timerBarFill = newFill
    }

    // MARK: - Impatient animation

    private func startImpatientAnimation() {
        // Gentle bounce + orange tint on avatar
        avatarSprite.color = UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0)
        avatarSprite.colorBlendFactor = 0.25

        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 4, duration: 0.3),
            SKAction.moveBy(x: 0, y: -4, duration: 0.3)
        ])
        avatarSprite.run(SKAction.repeatForever(bounce), withKey: "impatient")
    }

    private func stopImpatientAnimation() {
        avatarSprite.removeAction(forKey: "impatient")
        avatarSprite.colorBlendFactor = 0
        avatarSprite.position = .zero
    }

    // MARK: - Order feedback

    func animateEntrance() {
        setScale(0)
        run(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }

    func showCompleted() {
        cancelTimer()
        orderSprite.run(SKAction.fadeAlpha(to: 0.2, duration: 0.2))

        let tick = SKLabelNode(text: "✓")
        tick.fontSize = 40
        tick.fontName = "AvenirNext-Bold"
        tick.fontColor = UIColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0)
        tick.verticalAlignmentMode = .center
        tick.horizontalAlignmentMode = .center
        tick.position = .zero
        tick.zPosition = 1
        tick.setScale(0)
        speechBubble.addChild(tick)

        tick.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))

        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 10, duration: 0.12),
            SKAction.moveBy(x: 0, y: -10, duration: 0.12)
        ])
        run(SKAction.repeat(bounce, count: 3))
    }

    func showRejected() {
        cancelTimer()
        orderSprite.run(SKAction.fadeAlpha(to: 0.2, duration: 0.2))

        let cross = SKLabelNode(text: "✗")
        cross.fontSize = 40
        cross.fontName = "AvenirNext-Bold"
        cross.fontColor = UIColor(red: 0.8, green: 0.15, blue: 0.15, alpha: 1.0)
        cross.verticalAlignmentMode = .center
        cross.horizontalAlignmentMode = .center
        cross.position = .zero
        cross.zPosition = 1
        cross.setScale(0)
        speechBubble.addChild(cross)

        cross.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))

        let shake = SKAction.sequence([
            SKAction.moveBy(x: -8, y: 0, duration: 0.08),
            SKAction.moveBy(x: 16, y: 0, duration: 0.08),
            SKAction.moveBy(x: -16, y: 0, duration: 0.08),
            SKAction.moveBy(x: 8, y: 0, duration: 0.08)
        ])
        run(SKAction.repeat(shake, count: 2))
    }

    func animateExit(completion: @escaping () -> Void) {
        cancelTimer()
        run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.run(completion)
        ]))
    }
}
