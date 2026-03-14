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
        requiredIngredients: [flour, egg, milk],
        basePoints: 1
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
    private var mixerBinButton: SKSpriteNode!
    private var panBinButton: SKSpriteNode!

    // Plates
    private var plateSprites: [SKSpriteNode] = []

    // Sink and dirty dishes
    private var dirtyDishSprites: [SKSpriteNode] = []
    private var dirtyDishCount: Int = 0

    // Dish sprites on bench (keyed by customer node)
    private var benchDishSprites: [ObjectIdentifier: SKSpriteNode] = [:]
    private let totalPlates = 3  // TODO: change back to 5 after testing
    private var platesRemaining = 3
    private var customersServed = 0
    private var totalCustomersSpawned = 0

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
    private var plateX: CGFloat { benchRightEdge + (recipePanelLeftEdge - benchRightEdge) * 0.18 }
    private var stoveX: CGFloat { benchRightEdge + (recipePanelLeftEdge - benchRightEdge) * 0.48 }
    private var mixerX: CGFloat { benchRightEdge + (recipePanelLeftEdge - benchRightEdge) * 0.78 }
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
        setupPlateStack()
        setupSink()
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

    private func setupPlateStack() {
        let plateSize: CGFloat = 70
        let stackOffset: CGFloat = 6

        for i in 0..<totalPlates {
            let texture = SKTexture(imageNamed: "plate")
            let plate = SKSpriteNode(texture: texture)
            plate.size = CGSize(width: plateSize, height: plateSize)
            plate.position = CGPoint(x: plateX, y: workstationY - 20 + CGFloat(i) * stackOffset)
            plate.zPosition = CGFloat(i) + 1
            addChild(plate)
            plateSprites.append(plate)
        }
    }

    private func updatePlateStack() {
        for (index, plate) in plateSprites.enumerated() {
            plate.isHidden = index >= platesRemaining
        }
    }

    private func setupStoveTop() {
        stoveTop = StoveTopNode(size: CGSize(width: 170, height: 170))
        stoveTop.position = CGPoint(x: stoveX, y: workstationY + 10)
        stoveTop.zPosition = 1
        addChild(stoveTop)
    }

    private var sinkSize: CGFloat { 130 }
    private var sinkCentreX: CGFloat { benchRightEdge + sinkSize / 2 + 10 }
    private var sinkY: CGFloat { workstationY - 200 }

    private func setupSink() {
        let sinkTexture = SKTexture(imageNamed: "sink")
        let sink = SKSpriteNode(texture: sinkTexture)
        sink.size = CGSize(width: sinkSize, height: sinkSize)
        sink.position = CGPoint(x: sinkCentreX, y: sinkY)
        sink.zPosition = 0
        addChild(sink)
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

    private var canSpawnMore: Bool { totalCustomersSpawned < seatCount }

    private func spawnCustomer() {
        guard canSpawnMore else { return }
        totalCustomersSpawned += 1
        let customer = KitchenScene.customerPool.randomElement()!
        let node = CustomerNode(customer: customer)
        let slotIndex = customerNodes.count
        let seatPos = seatPositionForSlot(slotIndex)
        node.position = seatPos
        node.zPosition = 1
        addChild(node)
        node.animateEntrance()

        // Start customer timer
        node.onTimerExpired = { [weak self, weak node] in
            self?.handleCustomerLeft(node: node)
        }
        node.startTimer(duration: customer.order.waitTime)

        customerNodes.append(node)
        customerData.append(customer)
    }

    private func handleCustomerLeft(node: CustomerNode?) {
        guard let node, let index = customerNodes.firstIndex(where: { $0 === node }) else { return }

        let customer = customerData[index]
        scoreNode.decrement(by: customer.order.basePoints)
        customersServed += 1

        node.showRejected()

        run(SKAction.wait(forDuration: 1.0)) { [weak self] in
            guard let self else { return }
            guard let idx = self.customerNodes.firstIndex(where: { $0 === node }) else { return }

            node.animateExit {
                node.removeFromParent()
            }
            self.customerNodes.remove(at: idx)
            self.customerData.remove(at: idx)
            self.repositionCustomerStrip()

            if self.platesRemaining > 0 && self.canSpawnMore {
                self.spawnCustomer()
            }

            self.checkGameEnd()
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)

        // 0a. Next button (game end screen)
        for node in tappedNodes {
            if node.name == "nextButton" {
                restartGame()
                return
            }
        }

        // 0b. Active quiz takes priority
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

        // 2. Tap stove/pan to serve
        if gamePhase == .readyToServe || gamePhase == .burnt {
            for node in tappedNodes {
                if findStoveNode(in: node) {
                    serveOrder()
                    return
                }
            }
        }

        // 3. Tap mixer to mix (when ingredients added) or pour (when batter ready)
        for node in tappedNodes {
            if findMixerNode(in: node) {
                if gamePhase == .addingIngredients && mixerNode.canMix {
                    startMixing()
                    return
                }
                if gamePhase == .batterReady {
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

    private func findStoveNode(in node: SKNode) -> Bool {
        var current: SKNode? = node
        while let n = current {
            if n === stoveTop { return true }
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
                    self.pulseMixer()
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
        mixerNode.removeAction(forKey: "readyPulse")
        mixerNode.setScale(1.0)

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
        pulseStove()
    }

    private func onBurnt() {
        gamePhase = .burnt
        // Serve button stays visible — serving burnt food penalises
    }

    // MARK: - Serving

    private func serveOrder() {
        guard let result = stoveTop.tapToServe() else { return }

        stoveTop.removeAction(forKey: "readyPulse")
        stoveTop.setScale(1.0)
        hidePanBin()

        guard let activeOrder = customerData.first?.order else { return }
        let requiredSet = Set(activeOrder.requiredIngredients)
        let placedSet = Set(result.ingredients)
        let isCorrectOrder = requiredSet == placedSet

        // Use a plate
        platesRemaining -= 1
        customersServed += 1
        updatePlateStack()

        if isCorrectOrder && !result.isBurnt {
            let bonus = customerNodes.first?.isInBonusWindow == true ? 1 : 0
            customerNodes.first?.showCompleted()
            scoreNode.increment(by: activeOrder.basePoints + bonus)

            // Place dish on bench in front of customer
            if let customerNode = customerNodes.first {
                placeDishOnBench(for: customerNode, imageName: activeOrder.imageName)
            }

            // Customer stays to eat — set up eating callback then start eating
            customerNodes.first?.onFinishedEating = { [weak self] in
                self?.handleCustomerFinishedEating()
            }
            customerNodes.first?.startEating(duration: 5.0)
        } else {
            customerNodes.first?.showRejected()
            scoreNode.decrement(by: activeOrder.basePoints)

            // Wrong/burnt — customer leaves after brief delay
            run(SKAction.wait(forDuration: 1.5)) { [weak self] in
                self?.removeFirstCustomerAndContinue()
            }
        }

        // Reset kitchen immediately so player can start next order while customer eats
        stoveTop.reset()
        mixerNode.reset()
        hideMixerBin()
        hidePanBin()
        resetIngredientShelf()
        gamePhase = .addingIngredients
    }

    private func handleCustomerFinishedEating() {
        // Remove dish from bench and add dirty dish to sink
        if let customerNode = customerNodes.first {
            removeDishFromBench(for: customerNode)
            addDirtyDish()
        }
        removeFirstCustomerAndContinue()
    }

    private func removeFirstCustomerAndContinue() {
        guard let node = customerNodes.first else {
            checkGameEnd()
            return
        }

        node.animateExit {
            node.removeFromParent()
        }
        customerNodes.removeFirst()
        customerData.removeFirst()
        repositionCustomerStrip()

        if platesRemaining > 0 && canSpawnMore {
            spawnCustomer()
        }

        checkGameEnd()
    }

    private func checkGameEnd() {
        // Game ends when bench is empty
        if customerNodes.isEmpty {
            handleGameOver()
        }
    }

    // MARK: - Bin handling

    private func handleMixerBin() {
        guard !mixerNode.isEmpty else { return }
        mixerNode.removeAction(forKey: "readyPulse")
        mixerNode.setScale(1.0)
        mixerNode.reset()
        hideMixerBin()
        resetIngredientShelf()
        gamePhase = .addingIngredients
    }

    private func handlePanBin() {
        guard stoveTop.hasContents else { return }
        stoveTop.removeAction(forKey: "readyPulse")
        stoveTop.setScale(1.0)
        stoveTop.reset()
        mixerNode.reset()
        hidePanBin()
        hideMixerBin()
        resetIngredientShelf()
        gamePhase = .addingIngredients
    }

    // MARK: - Reset

    private func resetForNextOrder() {
        stoveTop.reset()
        mixerNode.reset()
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

    // MARK: - Game end

    private func handleGameOver() {
        // Total customers is seatCount. We served customersServed of them.
        let unservedCount = seatCount - customersServed
        if unservedCount > 0 {
            showUnservedPopup(count: unservedCount) { [weak self] in
                self?.showGameEndScreen()
            }
        } else {
            showGameEndScreen()
        }
    }

    private func showUnservedPopup(count: Int, completion: @escaping () -> Void) {
        // Deduct points for unserved customers
        let penalty = count
        for _ in 0..<penalty {
            scoreNode.decrement()
        }

        // Show all unserved customers with crosses
        for node in customerNodes {
            node.showRejected()
        }

        // Overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = UIColor(white: 0, alpha: 0.5)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 85
        overlay.name = "unservedOverlay"
        addChild(overlay)

        // Card
        let card = SKShapeNode(rectOf: CGSize(width: 400, height: 200), cornerRadius: 20)
        card.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.98)
        card.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        card.lineWidth = 3
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        card.zPosition = 86
        card.name = "unservedCard"
        addChild(card)

        let title = SKLabelNode(text: "No plates left!")
        title.fontSize = 26
        title.fontName = "AvenirNext-Bold"
        title.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
        title.zPosition = 87
        addChild(title)

        let detail = SKLabelNode(text: "\(count) customer\(count == 1 ? "" : "s") left hungry  −\(penalty) points")
        detail.fontSize = 20
        detail.fontName = "AvenirNext-Medium"
        detail.fontColor = UIColor(red: 0.8, green: 0.15, blue: 0.15, alpha: 1.0)
        detail.verticalAlignmentMode = .center
        detail.position = CGPoint(x: size.width / 2, y: size.height / 2 - 10)
        detail.zPosition = 87
        addChild(detail)

        // Auto-dismiss after 2.5s
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run {
                overlay.removeFromParent()
                card.removeFromParent()
                title.removeFromParent()
                detail.removeFromParent()
            },
            SKAction.wait(forDuration: 0.3),
            SKAction.run { completion() }
        ]))
    }

    private func showGameEndScreen() {
        let finalScore = scoreNode.currentScore
        let isPositive = finalScore > 0

        // Dim overlay
        let overlay = SKShapeNode(rectOf: size)
        overlay.fillColor = UIColor(white: 0, alpha: 0.6)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 90
        addChild(overlay)

        // Card
        let card = SKShapeNode(rectOf: CGSize(width: 450, height: 400), cornerRadius: 24)
        card.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 0.98)
        card.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        card.lineWidth = 3
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        card.zPosition = 91
        addChild(card)

        // Dora
        let doraTexture = SKTexture(imageNamed: "dora")
        let dora = SKSpriteNode(texture: doraTexture)
        let doraHeight: CGFloat = 200
        let doraScale = doraHeight / doraTexture.size().height
        dora.size = CGSize(width: doraTexture.size().width * doraScale, height: doraHeight)
        dora.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        dora.zPosition = 92
        addChild(dora)

        // Message depends on score
        let messageText = isPositive ? "Congratulations!" : "Better luck next time!"
        let message = SKLabelNode(text: messageText)
        message.fontSize = 32
        message.fontName = "AvenirNext-Bold"
        message.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        message.verticalAlignmentMode = .center
        message.position = CGPoint(x: size.width / 2, y: size.height / 2 - 60)
        message.zPosition = 92
        addChild(message)

        // Score
        let scoreText = isPositive ? "You scored \(finalScore)!" : "You got \(finalScore) — you can do better!"
        let scoreLabel = SKLabelNode(text: scoreText)
        scoreLabel.fontSize = 22
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.fontColor = UIColor(red: 0.5, green: 0.35, blue: 0.15, alpha: 1.0)
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 100)
        scoreLabel.zPosition = 92
        addChild(scoreLabel)

        // Play Again button
        let nextBtn = SKShapeNode(rectOf: CGSize(width: 160, height: 50), cornerRadius: 14)
        nextBtn.fillColor = UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)
        nextBtn.strokeColor = UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1.0)
        nextBtn.lineWidth = 2.5
        nextBtn.position = CGPoint(x: size.width / 2, y: size.height / 2 - 155)
        nextBtn.name = "nextButton"
        nextBtn.zPosition = 92
        addChild(nextBtn)

        let nextLabel = SKLabelNode(text: "Play Again!")
        nextLabel.fontSize = 20
        nextLabel.fontName = "AvenirNext-Bold"
        nextLabel.fontColor = UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0)
        nextLabel.verticalAlignmentMode = .center
        nextLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 155)
        nextLabel.name = "nextButton"
        nextLabel.zPosition = 93
        addChild(nextLabel)
    }

    private func restartGame() {
        removeAllChildren()
        removeAllActions()

        ingredientShelfNodes.removeAll()
        seatPositions.removeAll()
        customerNodes.removeAll()
        customerData.removeAll()
        plateSprites.removeAll()
        dirtyDishSprites.removeAll()
        dirtyDishCount = 0
        benchDishSprites.removeAll()
        platesRemaining = totalPlates
        customersServed = 0
        totalCustomersSpawned = 0
        gamePhase = .addingIngredients
        activeQuiz = nil
        pendingIngredientNode = nil

        setupScene()
        spawnCustomer()
    }

    // MARK: - Button visibility helpers

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

    // MARK: - Station pulsing

    private func pulseMixer() {
        mixerNode.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])), withKey: "readyPulse")
    }

    private func pulseStove() {
        stoveTop.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])), withKey: "readyPulse")
    }

    // MARK: - Dish on bench

    private func placeDishOnBench(for customerNode: CustomerNode, imageName: String) {
        let texture = SKTexture(imageNamed: imageName)
        let dish = SKSpriteNode(texture: texture)
        dish.size = CGSize(width: 90, height: 90)
        dish.position = CGPoint(x: benchLeftEdge + benchWidth / 2, y: customerNode.position.y)
        dish.zPosition = 2
        addChild(dish)
        benchDishSprites[ObjectIdentifier(customerNode)] = dish
    }

    private func removeDishFromBench(for customerNode: CustomerNode) {
        let key = ObjectIdentifier(customerNode)
        if let dish = benchDishSprites[key] {
            dish.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ]))
            benchDishSprites.removeValue(forKey: key)
        }
    }

    // MARK: - Dirty dish stack

    private func addDirtyDish() {
        dirtyDishCount += 1
        let texture = SKTexture(imageNamed: "dirty_plate")
        let dish = SKSpriteNode(texture: texture)
        dish.size = CGSize(width: 55, height: 55)
        let stackOffset: CGFloat = 6
        dish.position = CGPoint(x: sinkCentreX + 15, y: sinkY + CGFloat(dirtyDishCount - 1) * stackOffset)
        dish.zPosition = CGFloat(dirtyDishCount) + 1
        addChild(dish)
        dirtyDishSprites.append(dish)
    }
}
