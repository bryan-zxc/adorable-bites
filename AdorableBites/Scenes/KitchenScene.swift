import SpriteKit

class KitchenScene: SKScene {

    // MARK: - Game phase

    enum GamePhase {
        case addingIngredients
        case mixing
        case batterReady
        case cooking
        case readyToServe
        case burnt
    }

    private var gamePhase: GamePhase = .addingIngredients

    // MARK: - Ingredients

    static let flour = Ingredient(name: "flour", colour: .systemYellow, imageName: "flour")
    static let egg = Ingredient(name: "egg", colour: .systemOrange, imageName: "egg")
    static let milk = Ingredient(name: "milk", colour: .systemCyan, imageName: "milk")
    static let butter = Ingredient(name: "butter", colour: .systemYellow, imageName: "butter")
    static let chocolate = Ingredient(name: "chocolate", colour: .brown, imageName: "chocolate")

    static let allIngredients = [milk, egg, flour, butter, chocolate]

    // MARK: - Recipes

    static let pancakeRecipe = Recipe(
        name: "Pancakes",
        imageName: "pancakes",
        requiredIngredients: [flour, egg, milk]
    )

    static let allRecipes = [pancakeRecipe]

    // MARK: - Customer pool

    static let customerPool = [
        Customer(name: "Bear", imageName: "customer_bear", order: pancakeRecipe),
        Customer(name: "Cat", imageName: "customer_cat", order: pancakeRecipe),
        Customer(name: "Dog", imageName: "customer_dog", order: pancakeRecipe),
        Customer(name: "Bunny", imageName: "customer_bunny", order: pancakeRecipe),
        Customer(name: "Frog", imageName: "customer_frog", order: pancakeRecipe),
    ]

    // MARK: - Nodes

    private var ingredientShelfNodes: [IngredientNode] = []
    private var mixerNode: MixerNode!
    private var stoveTop: StoveTopNode!
    private var scoreNode: ScoreNode!
    private var recipePanel: RecipePanelNode!

    // Quiz
    private var activeQuiz: QuizNode?
    private var pendingIngredientNode: IngredientNode?

    // Buttons
    private var mixButton: SKShapeNode!
    private var mixLabel: SKLabelNode!
    private var serveButton: SKShapeNode!
    private var serveLabel: SKLabelNode!
    private var mixerBinButton: SKSpriteNode!
    private var panBinButton: SKSpriteNode!

    // MARK: - Bench and seating

    private let seatCount = 5
    private var seatPositions: [CGPoint] = []
    private var customerNodes: [CustomerNode] = []
    private var customerData: [Customer] = []

    // MARK: - Layout zones

    private let seatX: CGFloat = 55
    private let benchWidth: CGFloat = 140
    private var benchLeftEdge: CGFloat { seatX + 38 }
    private var benchRightEdge: CGFloat { benchLeftEdge + benchWidth }
    private var recipePanelCentreX: CGFloat { size.width - 110 }
    private var recipePanelLeftEdge: CGFloat { recipePanelCentreX - 100 }
    private var kitchenCentreX: CGFloat { (benchRightEdge + recipePanelLeftEdge) / 2 }
    private var mixerX: CGFloat { benchRightEdge + (recipePanelLeftEdge - benchRightEdge) * 0.3 }
    private var stoveX: CGFloat { benchRightEdge + (recipePanelLeftEdge - benchRightEdge) * 0.7 }
    private let workstationY: CGFloat = 370

    // MARK: - Scene lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 1.0, green: 0.97, blue: 0.88, alpha: 1.0)
        setupScene()
        spawnCustomer()
    }

    private func setupScene() {
        setupScoreNode()
        setupBench()
        setupIngredientShelf()
        setupKitchenCounter()
        setupMixer()
        setupStoveTop()
        setupMixButton()
        setupServeButton()
        setupBinButtons()
        setupRecipePanel()
    }

    // MARK: - Layout

    private func setupScoreNode() {
        let seatLeftEdge = seatX - 28
        let scoreWidth = benchRightEdge - seatLeftEdge
        scoreNode = ScoreNode(width: scoreWidth)
        scoreNode.position = CGPoint(x: (seatLeftEdge + benchRightEdge) / 2, y: size.height - 35)
        scoreNode.zPosition = 2
        addChild(scoreNode)
    }

    private func setupBench() {
        let benchTopY = size.height - 70
        let benchBottomY: CGFloat = 30
        let benchHeight = benchTopY - benchBottomY
        let benchCentreY = (benchTopY + benchBottomY) / 2

        let segmentHeight = benchHeight / CGFloat(seatCount)

        for i in 0..<seatCount {
            let seatY = benchTopY - segmentHeight * (CGFloat(i) + 0.5)
            let seatPos = CGPoint(x: seatX, y: seatY)
            seatPositions.append(seatPos)

            let stoolTexture = SKTexture(imageNamed: "bar_stool")
            let stool = SKSpriteNode(texture: stoolTexture)
            stool.size = CGSize(width: 55, height: 55)
            stool.position = seatPos
            stool.zPosition = 0
            addChild(stool)
        }

        let benchTexture = SKTexture(imageNamed: "bench_counter")
        let bench = SKSpriteNode(texture: benchTexture)
        bench.size = CGSize(width: benchHeight, height: self.benchWidth)
        bench.zRotation = .pi / 2
        bench.position = CGPoint(x: benchLeftEdge + self.benchWidth / 2, y: benchCentreY)
        bench.zPosition = -1
        addChild(bench)
    }

    private func setupIngredientShelf() {
        let ingredientCount = CGFloat(KitchenScene.allIngredients.count)

        let pantryPadding: CGFloat = 15
        let pantryWidth = recipePanelLeftEdge - benchRightEdge - pantryPadding * 2
        let pantryHeight: CGFloat = 180
        let pantryCentreX = (benchRightEdge + recipePanelLeftEdge) / 2
        let shelfY = size.height - 100

        let pantryTexture = SKTexture(imageNamed: "pantry_cupboard")
        let pantry = SKSpriteNode(texture: pantryTexture)
        pantry.size = CGSize(width: pantryWidth, height: pantryHeight)
        pantry.position = CGPoint(x: pantryCentreX, y: shelfY)
        pantry.zPosition = -1
        addChild(pantry)

        let compartmentWidth = pantryWidth / ingredientCount
        let pantryLeftEdge = benchRightEdge + pantryPadding
        let pantryInset: CGFloat = 22
        let startX = pantryLeftEdge + pantryInset + (pantryWidth - pantryInset * 2) / ingredientCount / 2

        let ingredientY = shelfY + pantryHeight * 0.125
        let labelOffsetY = -pantryHeight * 0.5
        let spriteSize = min(compartmentWidth, pantryHeight * 0.75) * 0.7
        let insetCompartmentWidth = (pantryWidth - pantryInset * 2) / ingredientCount
        for (index, ingredient) in KitchenScene.allIngredients.enumerated() {
            let ingredientX = startX + CGFloat(index) * insetCompartmentWidth
            let tagInset = pantryInset * 0.5
            let tagCompartmentWidth = (pantryWidth - tagInset * 2) / ingredientCount
            let tagX = pantryLeftEdge + tagInset + tagCompartmentWidth * (CGFloat(index) + 0.5)
            let labelOffsetX = tagX - ingredientX
            let node = IngredientNode(ingredient: ingredient, spriteSize: spriteSize, labelOffsetX: labelOffsetX, labelOffsetY: labelOffsetY)
            node.position = CGPoint(x: ingredientX, y: ingredientY)
            node.zPosition = 1
            addChild(node)
            ingredientShelfNodes.append(node)
        }
    }

    private func setupKitchenCounter() {
        let counterWidth = recipePanelLeftEdge - benchRightEdge - 20
        let counterHeight: CGFloat = 280
        let counterTexture = SKTexture(imageNamed: "kitchen_counter")
        let counter = SKSpriteNode(texture: counterTexture)
        counter.size = CGSize(width: counterWidth, height: counterHeight)
        counter.position = CGPoint(x: kitchenCentreX, y: workstationY)
        counter.zPosition = -1
        addChild(counter)
    }

    private func setupMixer() {
        mixerNode = MixerNode(size: CGSize(width: 150, height: 150))
        mixerNode.position = CGPoint(x: mixerX, y: workstationY + 10)
        mixerNode.zPosition = 1
        addChild(mixerNode)
    }

    private func setupStoveTop() {
        stoveTop = StoveTopNode(size: CGSize(width: 170, height: 170))
        stoveTop.position = CGPoint(x: stoveX, y: workstationY + 10)
        stoveTop.zPosition = 1
        addChild(stoveTop)
    }

    private func setupMixButton() {
        mixButton = SKShapeNode(rectOf: CGSize(width: 150, height: 48), cornerRadius: 14)
        mixButton.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.95)
        mixButton.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        mixButton.lineWidth = 2.5
        mixButton.position = CGPoint(x: mixerX, y: workstationY - 155)
        mixButton.name = "mixButton"
        mixButton.alpha = 0
        mixButton.isHidden = true
        mixButton.zPosition = 2

        let iconTexture = SKTexture(imageNamed: "icon_whisk")
        let icon = SKSpriteNode(texture: iconTexture)
        icon.size = CGSize(width: 24, height: 24)
        icon.position = CGPoint(x: -30, y: 0)
        mixButton.addChild(icon)

        mixLabel = SKLabelNode(text: "MIX!")
        mixLabel.fontSize = 18
        mixLabel.fontName = "AvenirNext-Bold"
        mixLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        mixLabel.verticalAlignmentMode = .center
        mixLabel.position = CGPoint(x: 10, y: 0)
        mixButton.addChild(mixLabel)

        addChild(mixButton)
    }

    private func setupServeButton() {
        serveButton = SKShapeNode(rectOf: CGSize(width: 170, height: 50), cornerRadius: 14)
        serveButton.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.95)
        serveButton.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        serveButton.lineWidth = 2.5
        serveButton.position = CGPoint(x: stoveX, y: workstationY - 155)
        serveButton.name = "serveButton"
        serveButton.alpha = 0
        serveButton.isHidden = true
        serveButton.zPosition = 2

        let iconTexture = SKTexture(imageNamed: "icon_serve")
        let icon = SKSpriteNode(texture: iconTexture)
        icon.size = CGSize(width: 26, height: 26)
        icon.position = CGPoint(x: -38, y: 0)
        serveButton.addChild(icon)

        serveLabel = SKLabelNode(text: "SERVE!")
        serveLabel.fontSize = 20
        serveLabel.fontName = "AvenirNext-Bold"
        serveLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        serveLabel.verticalAlignmentMode = .center
        serveLabel.position = CGPoint(x: 10, y: 0)
        serveButton.addChild(serveLabel)

        addChild(serveButton)
    }

    private func setupBinButtons() {
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let trashImage = UIImage(systemName: "trash.fill", withConfiguration: config)!
            .withTintColor(.systemRed, renderingMode: .alwaysOriginal)
        let trashTexture = SKTexture(image: trashImage)

        mixerBinButton = SKSpriteNode(texture: trashTexture)
        mixerBinButton.size = CGSize(width: 30, height: 30)
        mixerBinButton.position = CGPoint(x: mixerX + 90, y: workstationY + 60)
        mixerBinButton.name = "mixerBin"
        mixerBinButton.alpha = 0
        mixerBinButton.isHidden = true
        mixerBinButton.zPosition = 3
        addChild(mixerBinButton)

        panBinButton = SKSpriteNode(texture: trashTexture)
        panBinButton.size = CGSize(width: 30, height: 30)
        panBinButton.position = CGPoint(x: stoveX + 100, y: workstationY + 60)
        panBinButton.name = "panBin"
        panBinButton.alpha = 0
        panBinButton.isHidden = true
        panBinButton.zPosition = 3
        addChild(panBinButton)
    }

    private func setupRecipePanel() {
        let panelHeight = size.height - 60
        recipePanel = RecipePanelNode(recipes: KitchenScene.allRecipes, width: 200, height: panelHeight)
        recipePanel.position = CGPoint(x: recipePanelCentreX, y: size.height / 2)
        addChild(recipePanel)
    }

    // MARK: - Customer seating

    private func seatPositionForSlot(_ index: Int) -> CGPoint {
        guard index < seatPositions.count else {
            let lastSeat = seatPositions.last ?? CGPoint(x: seatX, y: 100)
            return CGPoint(x: lastSeat.x, y: lastSeat.y - CGFloat(index - seatPositions.count + 1) * 100)
        }
        return seatPositions[index]
    }

    private func spawnCustomer() {
        let customer = KitchenScene.customerPool.randomElement()!
        let node = CustomerNode(customer: customer)
        let slotIndex = customerNodes.count
        let seatPos = seatPositionForSlot(slotIndex)
        node.position = seatPos
        node.zPosition = 1
        addChild(node)
        node.animateEntrance()

        customerNodes.append(node)
        customerData.append(customer)
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // 0. Active quiz takes priority
        if let quiz = activeQuiz {
            if quiz.handleTap(at: location) {
                return
            }
        }

        // 1. Bin buttons (always available when visible)
        for node in tappedNodes {
            if node.name == "mixerBin" {
                handleMixerBin()
                return
            }
            if node.name == "panBin" {
                handlePanBin()
                return
            }
        }

        // 2. Serve button
        if gamePhase == .readyToServe || gamePhase == .burnt {
            for node in tappedNodes {
                if node.name == "serveButton" || node.parent?.name == "serveButton" {
                    serveOrder()
                    return
                }
            }
        }

        // 3. Mix button
        if gamePhase == .addingIngredients && mixerNode.canMix {
            for node in tappedNodes {
                if node.name == "mixButton" || node.parent?.name == "mixButton" {
                    startMixing()
                    return
                }
            }
        }

        // 4. Mixer tap (pour batter to pan)
        if gamePhase == .batterReady {
            for node in tappedNodes {
                if findMixerNode(in: node) {
                    pourBatterToPan()
                    return
                }
            }
        }

        // 5. Recipe panel
        for node in tappedNodes {
            if node.name?.starts(with: "recipeRow") == true || node.parent?.name?.starts(with: "recipeRow") == true || node.parent?.parent?.name?.starts(with: "recipeRow") == true {
                recipePanel.handleTap(at: location)
                return
            }
            if node.name == "recipePanel" {
                recipePanel.handleTap(at: location)
                return
            }
        }

        // 6. Ingredient taps
        if gamePhase == .addingIngredients {
            for node in tappedNodes {
                if let ingredientNode = findIngredientNode(in: node) {
                    handleIngredientTap(ingredientNode)
                    return
                }
            }
        }
    }

    private func findIngredientNode(in node: SKNode) -> IngredientNode? {
        if let ingredientNode = node as? IngredientNode { return ingredientNode }
        if let parent = node.parent as? IngredientNode { return parent }
        return nil
    }

    private func findMixerNode(in node: SKNode) -> Bool {
        var current: SKNode? = node
        while let n = current {
            if n === mixerNode { return true }
            current = n.parent
        }
        return false
    }

    // MARK: - Ingredient handling

    private func handleIngredientTap(_ ingredientNode: IngredientNode) {
        guard gamePhase == .addingIngredients else { return }
        guard activeQuiz == nil else { return }
        guard customerData.first?.order != nil else { return }

        let ingredient = ingredientNode.ingredient
        if mixerNode.currentIngredients.contains(ingredient) { return }

        // Show quiz — ingredient only added on correct answer
        pendingIngredientNode = ingredientNode
        let quiz = QuizNode(sceneSize: size)
        quiz.position = CGPoint(x: size.width / 2, y: size.height / 2)
        quiz.configure(
            onCorrect: { [weak self] in
                guard let self, let node = self.pendingIngredientNode else { return }
                node.animatePop()
                node.animateDimmed()
                self.mixerNode.addIngredient(node.ingredient)
                self.showMixerBin()
                if self.mixerNode.canMix {
                    self.showMixButton()
                }
                self.activeQuiz = nil
                self.pendingIngredientNode = nil
            },
            onWrong: { [weak self] in
                self?.activeQuiz = nil
                self?.pendingIngredientNode = nil
            }
        )
        addChild(quiz)
        activeQuiz = quiz
    }

    // MARK: - Mixing

    private func startMixing() {
        gamePhase = .mixing
        hideMixButton()

        mixerNode.startMixing { [weak self] in
            self?.onMixingComplete()
        }
    }

    private func onMixingComplete() {
        gamePhase = .batterReady

        // Pulse the mixer to indicate "tap me"
        mixerNode.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])), withKey: "readyPulse")
    }

    // MARK: - Pour batter to pan

    private func pourBatterToPan() {
        mixerNode.removeAction(forKey: "readyPulse")
        mixerNode.setScale(1.0)

        let ingredients = mixerNode.pourBatter()
        guard !ingredients.isEmpty else { return }

        gamePhase = .cooking
        hideMixerBin()

        stoveTop.receiveBatter(
            ingredients: ingredients,
            cookingComplete: { [weak self] in
                self?.onCookingComplete()
            },
            burnt: { [weak self] in
                self?.onBurnt()
            }
        )

        showPanBin()
    }

    // MARK: - Cooking

    private func onCookingComplete() {
        gamePhase = .readyToServe
        showServeButton()
    }

    private func onBurnt() {
        gamePhase = .burnt
        // Serve button stays visible — serving burnt food penalises
    }

    // MARK: - Serving

    private func serveOrder() {
        guard let result = stoveTop.tapToServe() else { return }

        hideServeButton()
        hidePanBin()

        guard let activeOrder = customerData.first?.order else { return }
        let requiredSet = Set(activeOrder.requiredIngredients)
        let placedSet = Set(result.ingredients)
        let isCorrectOrder = requiredSet == placedSet

        if isCorrectOrder && !result.isBurnt {
            customerNodes.first?.showCompleted()
            scoreNode.increment()
        } else {
            customerNodes.first?.showRejected()
            scoreNode.decrement()
        }

        run(SKAction.wait(forDuration: 1.5)) { [weak self] in
            self?.resetForNextOrder()
        }
    }

    // MARK: - Bin handling

    private func handleMixerBin() {
        guard !mixerNode.isEmpty else { return }
        mixerNode.removeAction(forKey: "readyPulse")
        mixerNode.setScale(1.0)
        mixerNode.reset()
        hideMixButton()
        hideMixerBin()
        resetIngredientShelf()
        gamePhase = .addingIngredients
    }

    private func handlePanBin() {
        guard stoveTop.hasContents else { return }
        stoveTop.reset()
        mixerNode.reset()
        hideServeButton()
        hidePanBin()
        hideMixerBin()
        resetIngredientShelf()
        gamePhase = .addingIngredients
    }

    // MARK: - Reset

    private func resetForNextOrder() {
        stoveTop.reset()
        mixerNode.reset()
        hideMixButton()
        hideServeButton()
        hideMixerBin()
        hidePanBin()
        resetIngredientShelf()
        gamePhase = .addingIngredients

        guard let servedNode = customerNodes.first else { return }

        servedNode.animateExit { [weak self] in
            guard let self else { return }
            servedNode.removeFromParent()
            self.customerNodes.removeFirst()
            self.customerData.removeFirst()
            self.repositionCustomerStrip()
            self.spawnCustomer()
        }
    }

    private func resetIngredientShelf() {
        for node in ingredientShelfNodes {
            node.animateReset()
        }
    }

    private func repositionCustomerStrip() {
        for (index, node) in customerNodes.enumerated() {
            let target = seatPositionForSlot(index)
            node.run(SKAction.move(to: target, duration: 0.3))
        }
    }

    // MARK: - Button visibility helpers

    private func showMixButton() {
        mixButton.isHidden = false
        mixButton.run(SKAction.fadeIn(withDuration: 0.2))
    }

    private func hideMixButton() {
        mixButton.removeAllActions()
        mixButton.run(SKAction.fadeOut(withDuration: 0.2)) { [weak self] in
            self?.mixButton.isHidden = true
        }
    }

    private func showServeButton() {
        serveButton.isHidden = false
        serveButton.alpha = 0
        serveButton.run(SKAction.fadeIn(withDuration: 0.3))
        serveButton.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])), withKey: "pulse")
    }

    private func hideServeButton() {
        serveButton.removeAction(forKey: "pulse")
        serveButton.setScale(1.0)
        serveButton.run(SKAction.fadeOut(withDuration: 0.2)) { [weak self] in
            self?.serveButton.isHidden = true
        }
    }

    private func showMixerBin() {
        guard mixerBinButton.isHidden else { return }
        mixerBinButton.isHidden = false
        mixerBinButton.run(SKAction.fadeIn(withDuration: 0.2))
    }

    private func hideMixerBin() {
        mixerBinButton.run(SKAction.fadeOut(withDuration: 0.2)) { [weak self] in
            self?.mixerBinButton.isHidden = true
        }
    }

    private func showPanBin() {
        panBinButton.isHidden = false
        panBinButton.run(SKAction.fadeIn(withDuration: 0.2))
    }

    private func hidePanBin() {
        panBinButton.run(SKAction.fadeOut(withDuration: 0.2)) { [weak self] in
            self?.panBinButton.isHidden = true
        }
    }
}
