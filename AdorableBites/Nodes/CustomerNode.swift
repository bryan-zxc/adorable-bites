import SpriteKit

class CustomerNode: SKNode {

    private let avatarSprite: SKSpriteNode
    private let speechBubble: SKShapeNode
    private let orderSprite: SKSpriteNode
    private let nameLabel: SKLabelNode

    init(customer: Customer) {
        // Customer avatar — big and prominent
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
        orderSprite.position = CGPoint(x: 0, y: 0)
        speechBubble.addChild(orderSprite)

        super.init()

        name = "customer"
        addChild(avatarSprite)
        addChild(nameLabel)
        addChild(speechBubble)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func animateEntrance() {
        setScale(0)
        run(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }

    func showCompleted() {
        // Fade the order image and overlay a green tick on the speech bubble
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

        // Bounce the whole customer
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 10, duration: 0.12),
            SKAction.moveBy(x: 0, y: -10, duration: 0.12)
        ])
        run(SKAction.repeat(bounce, count: 3))
    }

    func showRejected() {
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
        run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.run(completion)
        ]))
    }
}
