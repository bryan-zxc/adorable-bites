import SpriteKit

class QuizNode: SKNode {

    private let background: SKShapeNode
    private let correctAnswer: Int
    private var typedAnswer: String = ""
    private let answerLabel: SKLabelNode
    private let answerBox: SKShapeNode
    private var onCorrect: (() -> Void)?
    private var onWrong: (() -> Void)?

    init(sceneSize: CGSize) {
        // Generate question: randomly either "X + 1" or "1 + X"
        let number = Int.random(in: 0...9)
        correctAnswer = number + 1
        let questionText = Bool.random() ? "What is \(number) + 1?" : "What is 1 + \(number)?"

        // Dimmed overlay
        background = SKShapeNode(rectOf: sceneSize)
        background.fillColor = UIColor(white: 0, alpha: 0.5)
        background.strokeColor = .clear
        background.position = .zero

        // Answer display
        answerBox = SKShapeNode(rectOf: CGSize(width: 120, height: 50), cornerRadius: 12)
        answerBox.fillColor = .white
        answerBox.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        answerBox.lineWidth = 2.5

        answerLabel = SKLabelNode(text: "")
        answerLabel.fontSize = 30
        answerLabel.fontName = "AvenirNext-Bold"
        answerLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        answerLabel.verticalAlignmentMode = .center
        answerLabel.horizontalAlignmentMode = .center

        super.init()

        name = "quizNode"
        zPosition = 100

        addChild(background)

        // Dora on the left — fills the left section
        let doraTexture = SKTexture(imageNamed: "dora")
        let dora = SKSpriteNode(texture: doraTexture)
        let doraHeight = sceneSize.height * 0.7
        let doraScale = doraHeight / doraTexture.size().height
        dora.size = CGSize(width: doraTexture.size().width * doraScale, height: doraHeight)
        dora.position = CGPoint(x: -sceneSize.width / 2 + dora.size.width / 2 + 30, y: -20)
        dora.zPosition = 1
        addChild(dora)

        // Quiz card — centre-right area
        let cardX: CGFloat = 80
        let card = SKShapeNode(rectOf: CGSize(width: 380, height: 460), cornerRadius: 20)
        card.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.98)
        card.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        card.lineWidth = 3
        card.position = CGPoint(x: cardX, y: 0)
        addChild(card)

        // Question
        let questionLabel = SKLabelNode(text: questionText)
        questionLabel.fontSize = 30
        questionLabel.fontName = "AvenirNext-Bold"
        questionLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        questionLabel.verticalAlignmentMode = .center
        questionLabel.position = CGPoint(x: cardX, y: 175)
        addChild(questionLabel)

        // Answer box
        answerBox.position = CGPoint(x: cardX, y: 115)
        addChild(answerBox)
        answerLabel.position = CGPoint(x: cardX, y: 115)
        addChild(answerLabel)

        // Number pad: 1-9 in 3x3 grid, 0 and GO below
        let buttonSize: CGFloat = 60
        let padSpacing: CGFloat = 10
        let padStartX = cardX - (buttonSize + padSpacing)
        let padStartY: CGFloat = 50

        // Row 1: 1 2 3
        // Row 2: 4 5 6
        // Row 3: 7 8 9
        // Row 4: [clear] 0 [GO]
        let digits = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9]
        ]

        for (row, rowDigits) in digits.enumerated() {
            for (col, digit) in rowDigits.enumerated() {
                let x = padStartX + CGFloat(col) * (buttonSize + padSpacing)
                let y = padStartY - CGFloat(row) * (buttonSize + padSpacing)
                addNumberButton(digit: "\(digit)", position: CGPoint(x: x, y: y), size: buttonSize, name: "numpad_\(digit)")
            }
        }

        // Bottom row: clear, 0, GO
        let bottomY = padStartY - 3.0 * (buttonSize + padSpacing)
        addNumberButton(digit: "⌫", position: CGPoint(x: padStartX, y: bottomY), size: buttonSize, name: "numpad_clear")
        addNumberButton(digit: "0", position: CGPoint(x: padStartX + (buttonSize + padSpacing), y: bottomY), size: buttonSize, name: "numpad_0")
        addGoButton(position: CGPoint(x: padStartX + 2.0 * (buttonSize + padSpacing), y: bottomY), size: buttonSize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addNumberButton(digit: String, position: CGPoint, size: CGFloat, name: String) {
        let btn = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 12)
        btn.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)
        btn.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        btn.lineWidth = 2
        btn.position = position
        btn.name = name

        let label = SKLabelNode(text: digit)
        label.fontSize = 26
        label.fontName = "AvenirNext-Bold"
        label.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.name = name
        btn.addChild(label)

        addChild(btn)
    }

    private func addGoButton(position: CGPoint, size: CGFloat) {
        let btn = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 12)
        btn.fillColor = UIColor(red: 0.3, green: 0.75, blue: 0.4, alpha: 1.0)
        btn.strokeColor = UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0)
        btn.lineWidth = 2
        btn.position = position
        btn.name = "numpad_go"

        let label = SKLabelNode(text: "GO")
        label.fontSize = 22
        label.fontName = "AvenirNext-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = "numpad_go"
        btn.addChild(label)

        addChild(btn)
    }

    func configure(onCorrect: @escaping () -> Void, onWrong: @escaping () -> Void) {
        self.onCorrect = onCorrect
        self.onWrong = onWrong
    }

    func handleTap(at point: CGPoint) -> Bool {
        let localPoint = convert(point, from: parent!)
        let tapped = nodes(at: localPoint)

        for node in tapped {
            guard let nodeName = node.name, nodeName.starts(with: "numpad_") else { continue }
            let action = nodeName.replacingOccurrences(of: "numpad_", with: "")

            if action == "clear" {
                if !typedAnswer.isEmpty {
                    typedAnswer.removeLast()
                    answerLabel.text = typedAnswer
                }
                return true
            }

            if action == "go" {
                guard let typed = Int(typedAnswer) else { return true }
                submitAnswer(typed)
                return true
            }

            // Digit pressed — only allow up to 2 digits
            if typedAnswer.count < 2 {
                typedAnswer += action
                answerLabel.text = typedAnswer
            }
            return true
        }

        // Tap on background dismisses nothing — quiz must be answered
        return true
    }

    private func submitAnswer(_ answer: Int) {
        if answer == correctAnswer {
            answerBox.fillColor = UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 0.5)
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.3),
                SKAction.run { [weak self] in self?.onCorrect?() },
                SKAction.removeFromParent()
            ]))
        } else {
            answerBox.fillColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 0.5)
            let shake = SKAction.sequence([
                SKAction.moveBy(x: -8, y: 0, duration: 0.05),
                SKAction.moveBy(x: 16, y: 0, duration: 0.05),
                SKAction.moveBy(x: -16, y: 0, duration: 0.05),
                SKAction.moveBy(x: 8, y: 0, duration: 0.05)
            ])
            run(SKAction.sequence([
                shake,
                SKAction.wait(forDuration: 0.3),
                SKAction.run { [weak self] in
                    self?.typedAnswer = ""
                    self?.answerLabel.text = ""
                    self?.answerBox.fillColor = .white
                },
            ]))
        }
    }
}
